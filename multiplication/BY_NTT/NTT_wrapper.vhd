library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.data_type.all;

entity NTT_wrapper is
	port(
		clock             : in  std_logic;
		reset             : in  std_logic;
		start             : in  std_logic;
		ready             : out std_logic;
		output_valid      : out std_logic;
		output            : out std_logic_vector(q_num_bits - 1 downto 0);
		done              : out std_logic;
		bram_f_address_a  : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_f_data_out_a : in  std_logic_vector(q_num_bits - 1 downto 0);
		bram_f_address_b  : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_f_data_out_b : in  std_logic_vector(q_num_bits - 1 downto 0);
		bram_g_address_a  : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_g_data_out_a : in  std_logic_vector(q_num_bits - 1 downto 0);
		bram_g_address_b  : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_g_data_out_b : in  std_logic_vector(q_num_bits - 1 downto 0)
	);
end entity NTT_wrapper;

architecture RTL of NTT_wrapper is
	type state_type is (IDLE, LOAD_F, LOAD_G, START_NTT_STATE, WAIT_STATE, OUTPUT_STATE, DONE_STATE);
	signal state_NTT_wrapper : state_type;

	signal counter : integer range 0 to 1536;

	signal counter2 : integer range 0 to p;

	signal input_fg  : std_logic;
	signal input_fg2 : std_logic;

	signal start_ntt : std_logic;

	signal ntt_valid : std_logic;

	signal fg_addr  : std_logic_vector(p_num_bits downto 0);
	signal fg_addr2 : std_logic_vector(p_num_bits - 1 downto 0);

	signal din  : std_logic_vector(q_num_bits - 1 downto 0);
	signal dout : std_logic_vector(q_num_bits downto 0);

	signal reset_ntt : std_logic;

begin
	fsm_process : process(clock, reset) is
	begin
		if reset = '1' then
			state_NTT_wrapper <= IDLE;
			start_ntt         <= '0';
			reset_ntt         <= '1';
		elsif rising_edge(clock) then
			case state_NTT_wrapper is
				when IDLE =>
					if start = '1' then
						state_NTT_wrapper <= LOAD_F;
					end if;

					counter      <= 0;
					input_fg     <= '0';
					start_ntt    <= '0';
					done         <= '0';
					output_valid <= '0';
					ready        <= '1';
					counter2     <= 0;
					reset_ntt    <= '0';
				when LOAD_F =>
					counter <= counter + 1;
					ready   <= '0';
					if counter = 1535 then
						counter  <= counter;
						counter2 <= counter2 + 1;

						if counter2 = 10 then
							counter           <= 0;
							state_NTT_wrapper <= LOAD_G;
							input_fg          <= '1';
							counter2          <= 0;
						end if;
					end if;
				when LOAD_G =>
					counter <= counter + 1;
					ready   <= '0';
					if counter = 1535 then
						counter  <= counter;
						counter2 <= counter2 + 1;

						if counter2 = 10 then

							state_NTT_wrapper <= START_NTT_STATE;
							input_fg          <= '1';
							counter2          <= 0;
						end if;
					end if;
				when START_NTT_STATE =>
					start_ntt         <= '1';
					state_NTT_wrapper <= WAIT_STATE;
				when WAIT_STATE =>
					start_ntt <= '0';
					if ntt_valid = '1' then
						state_NTT_wrapper <= OUTPUT_STATE;
						counter           <= 0;
					end if;

				when OUTPUT_STATE =>
					input_fg <= '0';
					counter  <= counter + 1;
					if counter = 2 then
						output_valid <= '1';
					end if;

					if counter = p - 1 + 2 then
						state_NTT_wrapper <= DONE_STATE;
					end if;
				when DONE_STATE =>
					done              <= '1';
					output_valid      <= '0';
					state_NTT_wrapper <= IDLE;
					reset_ntt         <= '1';
			end case;
		end if;
	end process fsm_process;

	input_fg2 <= input_fg when rising_edge(clock);

	bram_f_address_a <= std_logic_vector(to_unsigned(counter, p_num_bits));
	bram_g_address_a <= std_logic_vector(to_unsigned(counter, p_num_bits));
	fg_addr          <= std_logic_vector(to_unsigned(counter, p_num_bits + 1)) when rising_edge(clock);

	output <= dout(q_num_bits - 1 downto 0);
	din    <= (others => '0') when unsigned(fg_addr) >= p
	          else bram_f_data_out_a when input_fg2 = '0'
	          else bram_g_data_out_a;

	ntt_inst : entity work.ntt
		port map(
			clk      => clock,
			rst      => reset_ntt,
			start    => start_ntt,
			input_fg => input_fg2,
			addr     => fg_addr,
			din      => din,
			dout     => dout,
			valid    => ntt_valid
		);

end architecture RTL;
