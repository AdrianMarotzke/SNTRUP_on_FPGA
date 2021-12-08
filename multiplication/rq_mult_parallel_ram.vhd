library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;

entity rq_mult_parallel_ram is
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
		bram_g_data_out_a : in  std_logic_vector(2 - 1 downto 0);
		bram_g_address_b  : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_g_data_out_b : in  std_logic_vector(2 - 1 downto 0)
	);
end entity rq_mult_parallel_ram;

architecture RTL of rq_mult_parallel_ram is
	type state_type is (RESET_STATE, IDLE, LOAD_ARRAY, LOAD_ARRAY_FINAL, MULT_STATE_START, MULT_STATE, MULT_STATE_FINAL, OUTPUT_STATE, PIPE_FLUSH);
	signal state_rq_mult : state_type;

	type small_array_type is array (p - 1 downto 0) of signed(2 downto 0);

	--signal small_cyclic_array : small_array_type;

	--type rq_array_type is array (p - 1 downto 0) of signed(q_num_bits - 1 downto 0);
	type rq_array_type is array (p - 1 downto 0) of signed(p_num_bits + q_num_bits downto 0);
	--signal rq_accumulator_array : rq_array_type;

	signal counter       : integer range 0 to p;
	signal counter_delay : integer range 0 to p;

	signal cyclic_counter : integer range 0 to 31;

	signal cyclic_counter_delay : integer range 0 to 31;

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
	signal output_valid_delay_4 : std_logic;

	signal bram_f_data_out_a_pipe : std_logic_vector(q_num_bits - 1 downto 0);

	type accumulator_signed_type is array (23 downto 0) of signed(p_num_bits + q_num_bits - 1 downto 0);
	signal fma_output : accumulator_signed_type;

	type address_array_type is array (23 downto 0) of std_logic_vector(5 - 1 downto 0);
	type accumulator_array_type is array (23 downto 0) of std_logic_vector(p_num_bits + q_num_bits - 1 downto 0);
	type cyclic_array_type is array (23 downto 0) of std_logic_vector(2 downto 0);

	signal accumulator_address_a         : address_array_type;
	signal accumulator_data_out_a        : accumulator_array_type;
	signal accumulator_data_out_vector_a : std_logic_vector((p_num_bits + q_num_bits) * 24 - 1 downto 0);
	signal accumulator_address_b         : address_array_type;
	signal accumulator_write_b           : std_logic_vector(23 downto 0);
	signal accumulator_data_in_b         : accumulator_array_type;
	signal accumulator_data_in_vector_b  : std_logic_vector((p_num_bits + q_num_bits) * 24 - 1 downto 0);

	signal fma_data_in : accumulator_array_type;

	signal cyclic_array_address_a           : address_array_type;
	signal cyclic_array_data_out_a          : cyclic_array_type;
	signal cyclic_array_data_out_vector_a   : std_logic_vector(3 * 24 - 1 downto 0);
	signal cyclic_array_address_b           : address_array_type;
	signal cyclic_array_write_b             : std_logic_vector(23 downto 0);
	signal cyclic_array_data_in_b           : cyclic_array_type;
	signal cyclic_array_data_in_b_shift_reg : cyclic_array_type;
	signal cyclic_array_data_in_vector_b    : std_logic_vector(3 * 24 - 1 downto 0);

	--signal cyclic_array_carry_15   : std_logic_vector(2 downto 0);
	signal cyclic_array_carry_16   : std_logic_vector(2 downto 0);
	--signal cyclic_array_carry_16_b : std_logic_vector(2 downto 0);
	signal cyclic_array_carry_16_a : std_logic_vector(2 downto 0);
	--signal cyclic_array_carry_22   : std_logic_vector(2 downto 0);
	signal cyclic_array_carry_23   : std_logic_vector(2 downto 0);

	signal last_output_round : std_logic;

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
					state_rq_mult        <= IDLE;

				when IDLE =>
					counter              <= 0;
					cyclic_counter       <= 0;
					done                 <= '0';
					output_valid_delay_1 <= '0';
					ready                <= '1';

					if start = '1' then
						state_rq_mult <= LOAD_ARRAY;
						ready         <= '0';
						counter       <= counter + 1;
					end if;

				--rq_accumulator_array <= (others => (others => '0'));
				when LOAD_ARRAY =>
					counter <= counter + 1;

					cyclic_array_write_b <= (others => '0');

					if counter_delay mod 24 = 0 and counter_delay /= 0 then
						cyclic_counter <= cyclic_counter + 1;
					end if;

					if counter mod 24 = 0 and counter /= 0 then
						cyclic_array_write_b(0) <= '1';
					end if;

					if counter = p then
						state_rq_mult           <= LOAD_ARRAY_FINAL;
						cyclic_array_write_b(0) <= '1';
						counter                 <= 0;
					end if;

					--cyclic_array_write_b(counter mod 24) <= '1';

					cyclic_array_data_in_b_shift_reg(counter_delay mod 24) <= std_logic_vector(resize(signed(bram_g_data_out_a), 3));

				--small_cyclic_array(p - 1 downto 0) <= resize(signed(bram_g_data_out_a), 3) & small_cyclic_array(p - 1 downto 1);
				when LOAD_ARRAY_FINAL =>
					cyclic_array_write_b <= (others => '0');
					--small_cyclic_array(p - 1 downto 0) <= resize(signed(bram_g_data_out_a), 3) & small_cyclic_array(p - 1 downto 1);
					state_rq_mult        <= MULT_STATE_START;
				--counter                            <= counter + 1;
				when MULT_STATE_START =>
					cyclic_counter <= 0;
					state_rq_mult  <= MULT_STATE;
				--counter       <= counter + 1;
				when MULT_STATE =>

					--small_cyclic_array(p - 1 downto 0) <= small_cyclic_array(0) & small_cyclic_array(p - 1 downto 1);
					--small_cyclic_array(p - 2)          <= r3_fma(small_cyclic_array(0), "001", small_cyclic_array(p - 1));

					--for i in 0 to p - 1 loop
					--	rq_accumulator_array(i) <= fma_output(i);
					--rq_accumulator_array(i) <= rq_fma(small_cyclic_array(i), signed(bram_f_data_out_a_pipe), rq_accumulator_array(i));
					--end loop;
					cyclic_counter <= cyclic_counter + 1;

					if cyclic_counter = 31 then
						cyclic_counter <= 0;
					end if;

					if cyclic_counter = 30 then
						counter <= counter + 1;
					end if;

					cyclic_array_write_b <= (others => '1');
					accumulator_write_b  <= (others => '1');

					if counter = p and cyclic_counter_delay = 31 then
						state_rq_mult        <= MULT_STATE_FINAL;
						cyclic_counter       <= 0;
						counter              <= 0;
						cyclic_array_write_b <= (others => '0');
						accumulator_write_b  <= (others => '0');
					end if;

				when MULT_STATE_FINAL =>
					state_rq_mult        <= OUTPUT_STATE;
					output_valid_delay_1 <= '1';
					last_output_round    <= '0';
				when OUTPUT_STATE =>
					counter <= counter + 1;

					if counter = 23 then
						counter <= 0;
					end if;
					if counter = 22 then
						cyclic_counter <= cyclic_counter + 1;
					end if;

					if counter = 23 and cyclic_counter = 31 then
						last_output_round <= '1';
					end if;
					if counter = 16 and last_output_round = '1' then
						state_rq_mult        <= PIPE_FLUSH;
						counter              <= 0;
						output_valid_delay_1 <= '0';
					end if;
				when PIPE_FLUSH =>
					counter <= counter + 1;
					if counter = 2 then
						counter       <= 0;
						done          <= '1';
						state_rq_mult <= IDLE;
					end if;
			end case;
		end if;
	end process;

	modq_freeze_inst : entity work.modq_freeze
		port map(
			clock  => clock,
			reset  => reset,
			input  => output_pre_freeze,
			output => output_freeze
		);

	output_valid_delay_2   <= output_valid_delay_1 when rising_edge(clock);
	output_valid_delay_3   <= output_valid_delay_2 when rising_edge(clock);
	output_valid_delay_4   <= output_valid_delay_3 when rising_edge(clock);
	output_valid           <= output_valid_delay_4 when rising_edge(clock);
	bram_f_data_out_a_pipe <= bram_f_data_out_a when rising_edge(clock);

	--output <= std_logic_vector(rq_accumulator_array(counter)) when counter /= p else (others => '0');
	--output <= std_logic_vector(rq_accumulator_array(0)(q_num_bits - 1 downto 0));

	--	output_pre_freeze <= resize(rq_accumulator_array(0), 2 * q_num_bits);
	output_pre_freeze <= resize(signed(accumulator_data_out_a(counter)), 2 * q_num_bits) when state_rq_mult = OUTPUT_STATE and rising_edge(clock);
	output            <= std_logic_vector(output_freeze);

	bram_f_address_a <= std_logic_vector(to_unsigned(counter, p_num_bits));
	bram_g_address_a <= std_logic_vector(to_unsigned(counter, p_num_bits));

	generate_label_ram : for i in 0 to 23 generate
		rq_fma_inst : entity work.rq_fma_v2
			port map(
				a      => signed(cyclic_array_data_out_a(i)),
				b      => signed(bram_f_data_out_a_pipe),
				c      => signed(fma_data_in(i)),
				output => fma_output(i)
			);

		fma_data_in(i)           <= (others => '0') when counter = 0 or (counter = 1 and (cyclic_counter = 0 or cyclic_counter = 31)) else accumulator_data_out_a(i);
		accumulator_data_in_b(i) <= std_logic_vector(fma_output(i));

		accumulator_data_out_a(i) <= accumulator_data_out_vector_a((p_num_bits + q_num_bits) * (i + 1) - 1 downto (p_num_bits + q_num_bits) * i);

		accumulator_data_in_vector_b((p_num_bits + q_num_bits) * (i + 1) - 1 downto (p_num_bits + q_num_bits) * i) <= accumulator_data_in_b(i);

		cyclic_array_data_out_a(i) <= cyclic_array_data_out_vector_a(3 * (i + 1) - 1 downto 3 * i);

		cyclic_array_data_in_vector_b(3 * (i + 1) - 1 downto 3 * i) <= cyclic_array_data_in_b(i);

		accumulator_address_a(i) <= std_logic_vector(to_unsigned(cyclic_counter, 5));
		accumulator_address_b(i) <= std_logic_vector(to_unsigned(cyclic_counter_delay, 5));

		cyclic_array_address_a(i) <= std_logic_vector(to_unsigned(cyclic_counter, 5));

		cyclic_array_address_b(i) <= std_logic_vector(to_unsigned(cyclic_counter, 5)) when state_rq_mult = LOAD_ARRAY or state_rq_mult = LOAD_ARRAY_FINAL --
		                             else std_logic_vector(to_unsigned(cyclic_counter_delay, 5));
	end generate generate_label_ram;

	-- TODO merge to one single memory

	SDP_dist_RAM_cyclic : entity work.SDP_dist_RAM
		generic map(
			ADDRESS_WIDTH => 5,
			DATA_WIDTH    => 3 * 24
		)
		port map(
			clock      => clock,
			address_a  => cyclic_array_address_a(0),
			data_out_a => cyclic_array_data_out_vector_a,
			address_b  => cyclic_array_address_b(0),
			write_b    => cyclic_array_write_b(0),
			data_in_b  => cyclic_array_data_in_vector_b
		);

	SDP_dist_RAM_acc : entity work.SDP_dist_RAM
		generic map(
			ADDRESS_WIDTH => 5,
			DATA_WIDTH    => (p_num_bits + q_num_bits) * 24
		)
		port map(
			clock      => clock,
			address_a  => accumulator_address_a(0),
			data_out_a => accumulator_data_out_vector_a,
			address_b  => accumulator_address_b(0),
			write_b    => accumulator_write_b(0),
			data_in_b  => accumulator_data_in_vector_b
		);

	cyclic_array_data_in_b(0) <= cyclic_array_data_in_b_shift_reg(0) when state_rq_mult = LOAD_ARRAY or state_rq_mult = LOAD_ARRAY_FINAL --
	                             else cyclic_array_carry_23 when cyclic_counter_delay /= 0
	                             else cyclic_array_carry_16;

	cyclic_array_data_in_b(1) <= cyclic_array_data_in_b_shift_reg(1) when state_rq_mult = LOAD_ARRAY or state_rq_mult = LOAD_ARRAY_FINAL --
	                             else cyclic_array_data_out_a(0) when cyclic_counter_delay /= 0
	                             else std_logic_vector(r3_fma(signed(cyclic_array_carry_16), "001", signed(cyclic_array_data_out_a(0))));

	gen_cyclic_data_in : for i in 2 to 23 generate
		cyclic_array_data_in_b(i) <= cyclic_array_data_in_b_shift_reg(i) when state_rq_mult = LOAD_ARRAY or state_rq_mult = LOAD_ARRAY_FINAL --
		                             else cyclic_array_data_out_a(i - 1);
	end generate gen_cyclic_data_in;

	cyclic_array_carry_23 <= cyclic_array_data_out_a(23) when rising_edge(clock);
	--cyclic_array_carry_22 <= cyclic_array_data_out_a(22) when rising_edge(clock);

	cyclic_array_carry_16   <= cyclic_array_carry_16_a when rising_edge(clock);
	cyclic_array_carry_16_a <= cyclic_array_data_out_a(16) when (cyclic_counter = 1 or cyclic_counter = 0) and counter = 0 else cyclic_array_data_in_b(16);

	--cyclic_array_carry_15 <= cyclic_array_data_out_a(15) when rising_edge(clock);

	cyclic_counter_delay <= cyclic_counter when rising_edge(clock);
	counter_delay        <= counter when rising_edge(clock);
end architecture RTL;
