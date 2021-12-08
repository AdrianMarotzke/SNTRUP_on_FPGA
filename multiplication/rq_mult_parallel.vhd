library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;

entity rq_mult_parallel is
	port(
		clock             : in  std_logic;
		reset             : in  std_logic;
		start             : in  std_logic;
		ready             : out std_logic;
		output_valid      : out std_logic;
		output            : out std_logic_vector(q_num_bits - 1 downto 0);
		done              : out std_logic;
		load_small_g      : in  std_logic;
		bram_f_address_a  : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_f_data_out_a : in  std_logic_vector(q_num_bits - 1 downto 0);
		bram_f_address_b  : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_f_data_out_b : in  std_logic_vector(q_num_bits - 1 downto 0);
		bram_g_address_a  : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_g_data_out_a : in  std_logic_vector(2 - 1 downto 0);
		bram_g_address_b  : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_g_data_out_b : in  std_logic_vector(2 - 1 downto 0)
	);
end entity rq_mult_parallel;

architecture RTL of rq_mult_parallel is
	type state_type is (RESET_STATE, IDLE, LOAD_ARRAY_WAIT, LOAD_ARRAY_FINAL, MULT_STATE_START, MULT_STATE, MULT_STATE_FINAL, OUTPUT_STATE, PIPE_FLUSH);
	signal state_rq_mult : state_type;

	type state_type_2 is (IDLE, LOAD_ARRAY, LOAD_ARRAY_DONE, LOAD_ARRAY_FINAL, ARRAY_CYCLE);
	signal state_load_array : state_type_2;

	type small_array_type is array (p - 1 downto 0) of signed(2 downto 0);

	signal small_cyclic_array : small_array_type;

	--type rq_array_type is array (p - 1 downto 0) of signed(q_num_bits - 1 downto 0);
	type rq_array_type is array (p - 1 downto 0) of signed(p_num_bits + q_num_bits - 1 downto 0);
	signal rq_accumulator_array : rq_array_type;

	signal counter : integer range 0 to p;

	signal counter_load_array : integer range 0 to p;

	function r3_fma(a, b, c : signed(2 downto 0))
	return signed is
		variable temp : signed(5 downto 0);

	begin
		temp := a * b + c;
		return temp(2 downto 0);
	end function r3_fma;

	signal output_freeze     : signed(q_num_bits - 1 downto 0);
	signal output_pre_freeze : signed(2 * q_num_bits - 1 downto 0);

	signal output_valid_delay_1 : std_logic;
	signal output_valid_delay_2 : std_logic;
	signal output_valid_delay_3 : std_logic;

	signal bram_f_data_out_a_pipe : std_logic_vector(q_num_bits - 1 downto 0);

	signal fma_output : rq_array_type;

begin

	process(clock, reset) is
	begin
		if reset = '1' then
			state_rq_mult <= RESET_STATE;
		elsif rising_edge(clock) then
			case state_rq_mult is
				when RESET_STATE =>
					counter              <= 0;
					done                 <= '0';
					output_valid_delay_1 <= '0';
					state_rq_mult        <= OUTPUT_STATE;

				when IDLE =>
					counter              <= 0;
					done                 <= '0';
					output_valid_delay_1 <= '0';
					ready                <= '1';

					if start = '1' then
						state_rq_mult <= LOAD_ARRAY_WAIT;
						ready         <= '0';
					end if;

				when LOAD_ARRAY_WAIT =>

					if state_load_array = LOAD_ARRAY_FINAL or state_load_array = LOAD_ARRAY_DONE then
						state_rq_mult <= MULT_STATE_START;
						counter       <= counter + 1;
					end if;

				when LOAD_ARRAY_FINAL =>
					state_rq_mult <= MULT_STATE_START;
				when MULT_STATE_START =>
					state_rq_mult <= MULT_STATE;
					counter       <= counter + 1;
				when MULT_STATE =>
					for i in 0 to p - 1 loop
						rq_accumulator_array(i) <= fma_output(i);
					end loop;

					counter <= counter + 1;

					if counter = p then
						state_rq_mult <= MULT_STATE_FINAL;
						counter       <= 0;
					end if;
				when MULT_STATE_FINAL =>
					for i in 0 to p - 1 loop
						--rq_accumulator_array(i) <= rq_fma(small_cyclic_array(i), signed(bram_f_data_out_a_pipe), rq_accumulator_array(i));
						rq_accumulator_array(i) <= fma_output(i);
					end loop;
					state_rq_mult        <= OUTPUT_STATE;
					output_valid_delay_1 <= '1';
				when OUTPUT_STATE =>
					counter <= counter + 1;

					rq_accumulator_array(0)              <= (others => '0');
					rq_accumulator_array(p - 1 downto 1) <= rq_accumulator_array(p - 2 downto 0);
					if counter = p - 1 then
						state_rq_mult        <= PIPE_FLUSH;
						counter              <= 0;
						output_valid_delay_1 <= '0';
					end if;
				when PIPE_FLUSH =>
					counter                     <= counter + 1;
					rq_accumulator_array(p - 1) <= (others => '0');
					if counter = 1 then
						counter       <= 0;
						done          <= '1';
						state_rq_mult <= IDLE;
					end if;
			end case;
		end if;
	end process;

	fsm_loal_small_cyclic_array : process(clock, reset) is
	begin
		if reset = '1' then
			state_load_array <= IDLE;
		elsif rising_edge(clock) then
			case state_load_array is
				when IDLE =>
					if (start = '1'and state_rq_mult = IDLE) or load_small_g = '1' then
						state_load_array <= LOAD_ARRAY;
					end if;
					counter_load_array <= 0;

				when LOAD_ARRAY =>
					counter_load_array <= counter_load_array + 1;

					if counter_load_array = p - 1 then
						state_load_array <= LOAD_ARRAY_FINAL;
					end if;

					small_cyclic_array(p - 1 downto 0) <= small_cyclic_array(p - 2 downto 0) & resize(signed(bram_g_data_out_a), 3);
				--small_cyclic_array(p - 1 downto 0) <= resize(signed(bram_g_data_out_a), 3) & small_cyclic_array(p - 1 downto 1);
				when LOAD_ARRAY_FINAL =>
					state_load_array                   <= LOAD_ARRAY_DONE;
					small_cyclic_array(p - 1 downto 0) <= small_cyclic_array(p - 2 downto 0) & resize(signed(bram_g_data_out_a), 3);
				--small_cyclic_array(p - 1 downto 0) <= resize(signed(bram_g_data_out_a), 3) & small_cyclic_array(p - 1 downto 1);
				when LOAD_ARRAY_DONE =>
					if state_rq_mult = MULT_STATE_START then
						state_load_array <= ARRAY_CYCLE;
					end if;

				when ARRAY_CYCLE =>
					if state_rq_mult = MULT_STATE_FINAL then
						state_load_array <= IDLE;
					end if;

					small_cyclic_array(p - 1 downto 0) <= small_cyclic_array(0) & small_cyclic_array(p - 1 downto 1);
					small_cyclic_array(p - 2)          <= r3_fma(small_cyclic_array(0), "001", small_cyclic_array(p - 1));

			end case;
		end if;
	end process fsm_loal_small_cyclic_array;

	generate_label : for i in 0 to p - 1 generate
		rq_fma_inst : entity work.rq_fma_v2
			port map(
				a      => small_cyclic_array(i),
				b      => signed(bram_f_data_out_a_pipe),
				c      => rq_accumulator_array(i),
				output => fma_output(i)
			);

	end generate generate_label;

	modq_freeze_inst : entity work.modq_freeze
		port map(
			clock  => clock,
			reset  => reset,
			input  => output_pre_freeze,
			output => output_freeze
		);

	output_valid_delay_2   <= output_valid_delay_1 when rising_edge(clock);
	output_valid_delay_3   <= output_valid_delay_2 when rising_edge(clock);
	output_valid           <= output_valid_delay_3 when rising_edge(clock);
	bram_f_data_out_a_pipe <= bram_f_data_out_a when rising_edge(clock);

	--output <= std_logic_vector(rq_accumulator_array(counter)) when counter /= p else (others => '0');
	--output <= std_logic_vector(rq_accumulator_array(0)(q_num_bits - 1 downto 0));

	output_pre_freeze <= resize(rq_accumulator_array(p - 1), 2 * q_num_bits);
	output            <= std_logic_vector(output_freeze);

	bram_f_address_a <= std_logic_vector(to_unsigned(counter, p_num_bits));
	bram_g_address_a <= std_logic_vector(to_unsigned(counter_load_array, p_num_bits));
end architecture RTL;
