library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

use work.constants.all;
use work.data_type.all;

-- Calculates the inversion of a short polynomial multiplied by 3 in Rq:
-- out = 1 / (3*f). Output & input is ordered lowest degree first
entity rq_reciprocal_3_vector is
	port(
		clock               : in  std_logic;
		reset               : in  std_logic;
		start               : in  std_logic;
		small_polynomial_in : in  std_logic_vector(q_num_bits - 1 downto 0);
		ready               : out std_logic;
		output_polynomial   : out std_logic_vector(q_num_bits - 1 downto 0);
		output_valid        : out std_logic;
		done                : out std_logic
	);
end entity rq_reciprocal_3_vector;

architecture RTL of rq_reciprocal_3_vector is

	constant loop_limit : integer := 2 * p - 1;

	constant bram_address_width : integer := integer(ceil(log2(real(p + 1))));

	function modq_reciprocal(a : integer)
	return integer is
		variable ai : integer := a;
	begin
		for i in 1 to q - 3 loop
			report "ai= " & integer'image(ai) & " i=" & integer'image(i);
			ai := ai * a;
			while ai >= integer(ceil(real(q) / real(2))) loop
				ai := ai - q;
			end loop;
			while ai <= -integer(ceil(real(q) / real(2))) loop
				ai := ai + q;
			end loop;
		end loop;
		return ai;
	end function modq_reciprocal;

	-- Reciprocal of 3 mod q
	constant reciproc_3 : integer := modq_reciprocal(3);

	signal counter             : integer range 0 to loop_limit + 1 := 0;
	type state_type is (init_state, reset_ram, reset_ram_end, ready_state, running_state, swap_state_1, swap_state_2, swap_state_3, multiply_state_read, multiply_final_state_1, multiply_final_state_2, multiply_final_state_3, calc_reciprocal_init, calc_reciprocal_init_2, calc_reciprocal, output_data, done_state);
	signal state_rq_reciprocal : state_type;

	type vector_data_type is array (keygen_vector_size - 1 downto 0) of std_logic_vector(q_num_bits - 1 downto 0);
	type vector_signed_type is array (keygen_vector_size - 1 downto 0) of signed(q_num_bits - 1 downto 0);

	constant pipeline_length : integer := 7;
	
	signal counter_vr             : integer range 0 to p + 2;
	signal counter_fg             : integer range 0 to p + 2;
	signal counter_vector         : integer range 0 to keygen_vector_size + pipeline_length;
	signal counter_vector_fg      : integer range 0 to keygen_vector_size;
	signal counter_vector_delay_1 : integer range 0 to keygen_vector_size;
	signal counter_vector_delay_2 : integer range 0 to keygen_vector_size;

	signal small_polynomial_in_delay : std_logic_vector(q_num_bits - 1 downto 0);

	signal bram_f_data_in_a : vector_data_type;
	signal bram_g_data_in_a : vector_data_type;
	signal bram_v_data_in_a : vector_data_type;
	signal bram_r_data_in_a : vector_data_type;

	signal bram_f_write_a : std_logic;
	signal bram_g_write_a : std_logic;
	signal bram_v_write_a : std_logic;
	signal bram_r_write_a : std_logic;

	signal bram_f_address_a : std_logic_vector(bram_address_width - keygen_vector_width - 1 downto 0);
	signal bram_g_address_a : std_logic_vector(bram_address_width - keygen_vector_width - 1 downto 0);
	signal bram_v_address_a : std_logic_vector(bram_address_width - keygen_vector_width - 1 downto 0);
	signal bram_r_address_a : std_logic_vector(bram_address_width - keygen_vector_width - 1 downto 0);

	signal bram_f_data_out_a : vector_data_type;
	signal bram_g_data_out_a : vector_data_type;
	signal bram_v_data_out_a : vector_data_type;
	signal bram_r_data_out_a : vector_data_type;

	signal swap_mask_s : std_logic;

	signal f_zero : std_logic_vector(q_num_bits - 1 downto 0);
	signal g_zero : std_logic_vector(q_num_bits - 1 downto 0);

	signal fg_freeze : vector_signed_type;

	signal bram_f_data_in_b : vector_data_type;
	signal bram_g_data_in_b : vector_data_type;
	signal bram_v_data_in_b : vector_data_type;
	signal bram_r_data_in_b : vector_data_type;

	signal bram_f_write_b : std_logic;
	signal bram_g_write_b : std_logic;
	signal bram_v_write_b : std_logic;
	signal bram_r_write_b : std_logic;

	signal bram_f_address_b : std_logic_vector(bram_address_width - keygen_vector_width - 1 downto 0);
	signal bram_g_address_b : std_logic_vector(bram_address_width - keygen_vector_width - 1 downto 0);
	signal bram_v_address_b : std_logic_vector(bram_address_width - keygen_vector_width - 1 downto 0);
	signal bram_r_address_b : std_logic_vector(bram_address_width - keygen_vector_width - 1 downto 0);

	type address_delay is array (pipeline_length downto 0) of std_logic_vector(bram_address_width - keygen_vector_width - 1 downto 0);

	signal bram_g_address_b_delay : address_delay;
	signal bram_g_write_b_delay   : std_logic_vector(pipeline_length downto 0);

	signal vr_freeze : vector_signed_type;

	signal bram_r_address_b_delay : address_delay;
	signal bram_r_write_b_delay   : std_logic_vector(pipeline_length downto 0);

	signal bram_shift_g_data_in_carry : std_logic_vector(q_num_bits - 1 downto 0);

	-- Shift data in v RAM
	signal bram_shift_v_address_b : std_logic_vector(bram_address_width - keygen_vector_width - 1 downto 0);
	signal bram_shift_v_data_in_b : vector_data_type;
	signal bram_shift_v_write_b   : std_logic;

	signal bram_shift_v_data_in_carry : std_logic_vector(q_num_bits - 1 downto 0);

	signal reciprocal_start  : std_logic;
	signal reciprocal_input  : std_logic_vector(q_num_bits - 1 downto 0);
	signal reciprocal_ready  : std_logic;
	signal reciprocal_done   : std_logic;
	signal reciprocal_output : std_logic_vector(q_num_bits - 1 downto 0);

	signal output_pre_freeze : signed(q_num_bits * 2 - 1 downto 0);
	signal output_freeze     : signed(q_num_bits - 1 downto 0);

	signal output_valid_pipe : std_logic_vector(pipeline_length downto 0);

	signal bram_f_data_in_a_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);
	signal bram_g_data_in_a_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);
	signal bram_v_data_in_a_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);
	signal bram_r_data_in_a_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);

	signal bram_f_data_out_a_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);
	signal bram_g_data_out_a_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);
	signal bram_v_data_out_a_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);
	signal bram_r_data_out_a_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);

	signal bram_f_data_in_b_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);
	signal bram_g_data_in_b_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);
	signal bram_v_data_in_b_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);
	signal bram_r_data_in_b_vector : std_logic_vector(q_num_bits * keygen_vector_size - 1 downto 0);

	constant zero_vector : vector_data_type := (others => (others => '0'));

begin

	main : process(clock, reset) is
		variable delta : signed(15 downto 0);

		variable swap_mask : signed(15 downto 0);

	begin
		if reset = '1' then
			state_rq_reciprocal <= init_state;

			reciprocal_start <= '0';
			reciprocal_input <= (others => '0');

			bram_g_address_b_delay(0) <= (others => '0');
			bram_g_write_b_delay(0)   <= '0';

			bram_r_address_b_delay(0) <= (others => '0');
			bram_r_write_b_delay(0)   <= '0';

			bram_f_write_a <= '0';
			bram_g_write_a <= '0';
			bram_v_write_a <= '0';
			bram_r_write_a <= '0';

			bram_f_data_in_a <= (others => (others => '0'));
			bram_g_data_in_a <= (others => (others => '0'));
			bram_v_data_in_a <= (others => (others => '0'));
			bram_r_data_in_a <= (others => (others => '0'));

			f_zero <= (others => '0');
			g_zero <= (others => '0');

			bram_shift_v_write_b    <= '0';
			bram_r_write_b_delay(0) <= '0';

			done  <= '0';
			ready <= '0';

			output_valid_pipe(0) <= '0';
		elsif rising_edge(clock) then
			case state_rq_reciprocal is
				when init_state =>
					state_rq_reciprocal  <= ready_state;
					delta                := to_signed(1, 16);
					swap_mask            := (others => '0');
					counter              <= 0;
					--counter_vr           <= 0;
					--counter_fg           <= 0;
					output_valid_pipe(0) <= '0';
					ready                <= '0';
					swap_mask_s          <= '0';
					done                 <= '0';
				when ready_state =>
					if start = '1' then
						state_rq_reciprocal <= reset_ram;
						ready               <= '0';
					else
						state_rq_reciprocal <= ready_state;
						ready               <= '1';
					end if;
					bram_f_write_a    <= '0';
					bram_g_write_a    <= '0';
					bram_v_write_a    <= '0';
					bram_r_write_a    <= '0';
					counter_vector    <= 0;
					counter_vector_fg <= p mod keygen_vector_size - 1;
					counter_fg        <= p / keygen_vector_size;
					counter_vr        <= 0;
				when reset_ram =>

					bram_f_address_a <= std_logic_vector(to_unsigned(counter_fg, bram_address_width - keygen_vector_width));
					bram_g_address_a <= std_logic_vector(to_unsigned(counter_fg, bram_address_width - keygen_vector_width));

					bram_v_address_a <= std_logic_vector(to_unsigned(counter_vr, bram_address_width - keygen_vector_width));
					bram_r_address_a <= std_logic_vector(to_unsigned(counter_vr, bram_address_width - keygen_vector_width));

					if counter_fg = 0 then
						bram_f_data_in_a(0)                               <= std_logic_vector(to_signed(1, q_num_bits));
						bram_f_data_in_a(keygen_vector_size - 1 downto 1) <= (others => (others => '0'));
					elsif counter_fg = p / keygen_vector_size then
						bram_f_data_in_a                                 <= (others => (others => '0'));
						bram_f_data_in_a(p mod keygen_vector_size)       <= std_logic_vector(to_signed(-1, q_num_bits));
						bram_f_data_in_a((p - 1) mod keygen_vector_size) <= std_logic_vector(to_signed(-1, q_num_bits));
					else
						bram_f_data_in_a <= (others => (others => '0'));
					end if;

					if counter_fg < p / keygen_vector_size then
						bram_g_data_in_a(counter_vector_fg) <= std_logic_vector(resize(signed(small_polynomial_in_delay), q_num_bits));
					else
						bram_g_data_in_a(counter_vector_fg)                                      <= std_logic_vector(resize(signed(small_polynomial_in_delay), q_num_bits));
						bram_g_data_in_a(keygen_vector_size - 1 downto p mod keygen_vector_size) <= (others => (others => '0'));
					end if;

					bram_v_data_in_a <= (others => (others => '0'));

					if counter_vr = 0 then
						bram_r_data_in_a    <= (others => (others => '0'));
						bram_r_data_in_a(0) <= std_logic_vector(to_signed(reciproc_3, q_num_bits));
					else
						bram_r_data_in_a <= (others => (others => '0'));
					end if;

					if counter_vector = keygen_vector_size - 1 then
						counter_vr     <= counter_vr + 1;
						counter_vector <= 0;

						bram_v_write_a <= '1';
						bram_r_write_a <= '1';
					else
						bram_v_write_a <= '0';
						bram_r_write_a <= '0';
						counter_vector <= counter_vector + 1;
					end if;

					if counter_vector_fg = 0 then
						counter_fg        <= counter_fg - 1;
						counter_vector_fg <= keygen_vector_size - 1;
						bram_f_write_a    <= '1';
						bram_g_write_a    <= '1';
					else
						bram_f_write_a    <= '0';
						bram_g_write_a    <= '0';
						counter_vector_fg <= counter_vector_fg - 1;
					end if;

					if counter_vr = (p / keygen_vector_size) + 1 then
						state_rq_reciprocal <= running_state;
					else
						state_rq_reciprocal <= reset_ram;
					end if;
				when reset_ram_end =>
					state_rq_reciprocal <= running_state;
					bram_f_write_a      <= '0';
					bram_g_write_a      <= '0';
					bram_v_write_a      <= '0';
					bram_r_write_a      <= '0';
					bram_g_address_a    <= (others => '0');
					bram_f_address_a    <= (others => '0');
				when running_state =>
					if counter >= loop_limit then
						state_rq_reciprocal <= calc_reciprocal_init;
					else
						state_rq_reciprocal <= swap_state_1;
					end if;
					bram_g_address_a <= (others => '0');
					bram_f_address_a <= (others => '0');

					counter                 <= counter + 1;
					counter_fg              <= 0;
					counter_vr              <= 0;
					bram_g_write_b_delay(0) <= '0';
					bram_r_write_b_delay(0) <= '0';
					bram_shift_v_write_b    <= '0';
					bram_f_write_a          <= '0';
					bram_g_write_a          <= '0';
					bram_v_write_a          <= '0';
					bram_r_write_a          <= '0';
				when swap_state_1 =>
					state_rq_reciprocal <= swap_state_2;
				when swap_state_2 =>
					state_rq_reciprocal <= swap_state_3;
					swap_mask           := negative_mask(-delta) AND non_zero_mask(signed(bram_g_data_out_a(0)));
					delta               := (delta XOR (swap_mask AND (delta XOR -delta))) + to_signed(1, 16);

					if swap_mask(0) = '1' then
						swap_mask_s <= not swap_mask_s;
					else
						swap_mask_s <= swap_mask_s;
					end if;
				when swap_state_3 =>
					state_rq_reciprocal <= multiply_state_read;
					f_zero              <= bram_f_data_out_a(0);
					g_zero              <= bram_g_data_out_a(0);
				when multiply_state_read =>

					bram_f_address_a <= std_logic_vector(to_unsigned(p / keygen_vector_size - counter_fg, bram_address_width - keygen_vector_width));
					bram_g_address_a <= std_logic_vector(to_unsigned(p / keygen_vector_size - counter_fg, bram_address_width - keygen_vector_width));
					bram_v_address_a <= std_logic_vector(to_unsigned(counter_vr, bram_address_width - keygen_vector_width));
					bram_r_address_a <= std_logic_vector(to_unsigned(counter_vr, bram_address_width - keygen_vector_width));

					bram_g_address_b_delay(0) <= std_logic_vector(to_unsigned(p / keygen_vector_size - counter_fg, bram_address_width - keygen_vector_width));
					bram_g_write_b_delay(0)   <= '1';

					bram_r_address_b_delay(0) <= std_logic_vector(to_unsigned(counter_vr, bram_address_width - keygen_vector_width));
					bram_r_write_b_delay(0)   <= '1';

					counter_fg <= counter_fg + 1;
					counter_vr <= counter_vr + 1;

					if counter_fg = p / keygen_vector_size and counter_vr = p / keygen_vector_size then
						state_rq_reciprocal <= multiply_final_state_1;
					else
						state_rq_reciprocal <= multiply_state_read;
					end if;

					if counter = loop_limit then
						bram_shift_v_write_b <= '0';
					else
						bram_shift_v_write_b <= '0';
						if counter_vr = 1 then
							bram_shift_v_address_b <= (others => '0');
							bram_shift_v_write_b   <= '1';

						else
							if counter_vr > 1 then
								bram_shift_v_address_b <= std_logic_vector(to_unsigned(counter_vr - 1, bram_address_width - keygen_vector_width));
								bram_shift_v_write_b   <= '1';
							end if;
						end if;
					end if;

				when multiply_final_state_1 =>
					bram_g_write_b_delay(0) <= '0';

					bram_r_write_b_delay(0) <= '0';
					state_rq_reciprocal     <= multiply_final_state_2;

					bram_shift_v_address_b <= std_logic_vector(to_unsigned(counter_vr - 1, bram_address_width - keygen_vector_width));
					if counter = loop_limit then
						bram_shift_v_write_b <= '0';
					else
						bram_shift_v_write_b <= '1';
					end if;

					bram_f_address_a <= (others => '0');
					bram_g_address_a <= (others => '0');
					counter_vector   <= 0;
				when multiply_final_state_2 =>
					counter_vector <= counter_vector + 1;

					if counter_vector = pipeline_length then
						state_rq_reciprocal <= running_state;
						counter_vector      <= 0;
					end if;

					bram_shift_v_write_b    <= '0';
					bram_g_write_b_delay(0) <= '0';

					bram_v_address_a <= (others => '0');
					bram_r_address_a <= (others => '0');
				when multiply_final_state_3 => -- unused state
					state_rq_reciprocal     <= running_state;
					bram_shift_v_write_b    <= '0';
					bram_g_write_b_delay(0) <= '0';

					bram_v_address_a <= (others => '0');
					bram_r_address_a <= (others => '0');
				when calc_reciprocal_init =>
					state_rq_reciprocal <= calc_reciprocal_init_2;
					bram_f_address_a    <= (others => '0');
				when calc_reciprocal_init_2 =>
					state_rq_reciprocal <= calc_reciprocal;
				when calc_reciprocal =>
					reciprocal_start <= '1';
					reciprocal_input <= bram_f_data_out_a(0);
					counter_vr       <= 0;
					counter_vector   <= p mod keygen_vector_size - 1;
					if reciprocal_done = '1' then
						state_rq_reciprocal <= output_data;
						reciprocal_start    <= '0';
					else
						state_rq_reciprocal <= calc_reciprocal;
					end if;
				when output_data =>
					bram_v_address_a <= std_logic_vector(to_unsigned(p / keygen_vector_size - counter_vr, bram_address_width - keygen_vector_width));

					if counter_vector = 0 then
						counter_vr     <= counter_vr + 1;
						counter_vector <= keygen_vector_size - 1;
					else
						counter_vector <= counter_vector - 1;
					end if;

					output_valid_pipe(0) <= '1';

					if counter_vr = (p / keygen_vector_size) and counter_vector = 0 then
						state_rq_reciprocal <= done_state;
					else
						state_rq_reciprocal <= output_data;
					end if;

				when done_state =>
					state_rq_reciprocal  <= init_state;
					output_valid_pipe(0) <= '0';
					done                 <= '1';
			end case;
		end if;
	end process main;

	bram_shift_v_data_in_b(0)                               <= (others => '0') when counter_vr = 2 else bram_shift_v_data_in_carry;
	bram_shift_v_data_in_b(keygen_vector_size - 1 downto 1) <= bram_v_data_out_a(keygen_vector_size - 2 downto 0);
	bram_shift_v_data_in_carry                              <= bram_v_data_out_a(keygen_vector_size - 1) when rising_edge(clock);

	modq_reciprocal_inst : entity work.modq_reciprocal
		port map(
			clock  => clock,
			reset  => reset,
			start  => reciprocal_start,
			input  => reciprocal_input,
			ready  => reciprocal_ready,
			done   => reciprocal_done,
			output => reciprocal_output
		);

	output_pre_freeze <= signed(reciprocal_output) * signed(bram_v_data_out_a(counter_vector_delay_2)) when rising_edge(clock);

	modq_freeze_inst_scale : entity work.modq_freeze(RTL)
		port map(
			clock  => clock,
			reset  => reset,
			input  => output_pre_freeze,
			output => output_freeze
		);

	output_polynomial <= std_logic_vector(output_freeze);

	delay_output_valid : process(clock, reset) is
	begin
		if reset = '1' then
		--output_valid_pipe(pipeline_length downto 1) <= (others => '0');
		elsif rising_edge(clock) then
			output_valid_pipe(pipeline_length downto 1) <= output_valid_pipe(pipeline_length - 1 downto 0);
			counter_vector_delay_1                      <= counter_vector mod keygen_vector_size;
			counter_vector_delay_2                      <= counter_vector_delay_1;
		end if;
	end process delay_output_valid;

	output_valid <= output_valid_pipe(pipeline_length - 2);

	-- Delay the write to g bram to wait for freeze pipeline to complete.
	-- Also shifts the address by one to implement the shift of g
	delay_bram_g_port_b : process(clock, reset) is
	begin
		if reset = '1' then
			--bram_g_address_b_delay(pipeline_length downto 1) <= (others => (others => '0'));
			--bram_g_write_b_delay(pipeline_length downto 1)   <= (others => '0');

			bram_shift_g_data_in_carry <= (others => '0');
		else

			if rising_edge(clock) then
				bram_g_address_b_delay(pipeline_length downto 1) <= bram_g_address_b_delay(pipeline_length - 1 downto 0);

				bram_g_write_b_delay(pipeline_length downto 1) <= bram_g_write_b_delay(pipeline_length - 1 downto 0);

				bram_shift_g_data_in_carry <= std_logic_vector(fg_freeze(0));
			end if;
		end if;
	end process delay_bram_g_port_b;

	small_polynomial_in_delay <= small_polynomial_in when rising_edge(clock);

	vector_fma_generate : for i in 0 to keygen_vector_size - 1 generate
		-- Multiplication of f0*g[i]-g0*f[i]
		modq_minus_product_inst_fg : entity work.modq_minus_product
			port map(
				clock         => clock,
				reset         => reset,
				data_in_a     => bram_g_data_out_a(i),
				data_in_b     => bram_f_data_out_a(i),
				f_zero        => f_zero,
				g_zero        => g_zero,
				output_freeze => fg_freeze(i)
			);

		-- Multiplication of f0*r[i]-g0*v[i]
		modq_minus_product_inst_vr : entity work.modq_minus_product
			port map(
				clock         => clock,
				reset         => reset,
				data_in_a     => bram_r_data_out_a(i),
				data_in_b     => bram_v_data_out_a(i),
				f_zero        => f_zero,
				g_zero        => g_zero,
				output_freeze => vr_freeze(i)
			);

	end generate vector_fma_generate;

	fg_freeze_to_g_data : for i in 0 to keygen_vector_size - 2 generate

		bram_g_data_in_b(i) <= std_logic_vector(fg_freeze(i + 1)) when unsigned(bram_g_address_b_delay(pipeline_length)) /= (p / keygen_vector_size) --
		                       else zero_vector(i) when i >= p mod keygen_vector_size + 1
		                       else std_logic_vector(fg_freeze(i + 1));
	end generate fg_freeze_to_g_data;

	bram_g_data_in_b(keygen_vector_size - 1) <= bram_shift_g_data_in_carry when unsigned(bram_g_address_b_delay(pipeline_length)) /= (p / keygen_vector_size) else (others => '0');

	delay_bram_r_port_b : process(clock, reset) is
	begin
		if reset = '1' then
		--bram_r_address_b_delay(pipeline_length downto 1) <= (others => (others => '0'));
		--bram_r_write_b_delay(pipeline_length downto 1)   <= (others => '0');
		else
			if rising_edge(clock) then
				bram_r_address_b_delay(pipeline_length downto 1) <= bram_r_address_b_delay(pipeline_length - 1 downto 0);
				bram_r_write_b_delay(pipeline_length downto 1)   <= bram_r_write_b_delay(pipeline_length - 1 downto 0);
			end if;
		end if;
	end process delay_bram_r_port_b;

	type_to_vector_generate : for i in 0 to keygen_vector_size - 1 generate
		bram_f_data_in_b_vector((i + 1) * q_num_bits - 1 downto i * q_num_bits) <= (others => '0') when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_f_data_in_a(i);
		bram_g_data_in_b_vector((i + 1) * q_num_bits - 1 downto i * q_num_bits) <= bram_g_data_in_b(i) when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_g_data_in_a(i);
		bram_v_data_in_b_vector((i + 1) * q_num_bits - 1 downto i * q_num_bits) <= bram_v_data_in_b(i) when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_v_data_in_a(i);
		bram_r_data_in_b_vector((i + 1) * q_num_bits - 1 downto i * q_num_bits) <= bram_r_data_in_b(i) when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_r_data_in_a(i);

		bram_f_data_out_a(i) <= bram_f_data_out_a_vector((i + 1) * q_num_bits - 1 downto i * q_num_bits);
		bram_g_data_out_a(i) <= bram_g_data_out_a_vector((i + 1) * q_num_bits - 1 downto i * q_num_bits);
		bram_v_data_out_a(i) <= bram_v_data_out_a_vector((i + 1) * q_num_bits - 1 downto i * q_num_bits);
		bram_r_data_out_a(i) <= bram_r_data_out_a_vector((i + 1) * q_num_bits - 1 downto i * q_num_bits);

		bram_v_data_in_b(i) <= bram_shift_v_data_in_b(i);
		bram_r_data_in_b(i) <= std_logic_vector(vr_freeze(i));
	end generate type_to_vector_generate;

	bram_f_write_b <= '0' when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_f_write_a;
	bram_g_write_b <= bram_g_write_b_delay(pipeline_length) when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_g_write_a;
	bram_v_write_b <= bram_shift_v_write_b when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_v_write_a;
	bram_r_write_b <= bram_r_write_b_delay(pipeline_length) when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_r_write_a;

	bram_f_address_b <= (others => '0') when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_f_address_a;
	bram_g_address_b <= bram_g_address_b_delay(pipeline_length) when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_g_address_a;
	bram_v_address_b <= bram_shift_v_address_b when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_v_address_a;
	bram_r_address_b <= bram_r_address_b_delay(pipeline_length) when state_rq_reciprocal /= reset_ram and state_rq_reciprocal /= reset_ram_end else bram_r_address_a;

	bram_rq_reciprocal_3_inst : entity work.bram_rq_reciprocal_3_vector
		generic map(
			bram_address_width => bram_address_width,
			bram_data_width    => q_num_bits,
			vector_size        => keygen_vector_size,
			vector_width       => keygen_vector_width
		)
		port map(
			clock             => clock,
			swap_mask_s       => swap_mask_s,
			bram_f_address_a  => bram_f_address_a,
			bram_g_address_a  => bram_g_address_a,
			bram_v_address_a  => bram_v_address_a,
			bram_r_address_a  => bram_r_address_a,
			bram_f_data_out_a => bram_f_data_out_a_vector,
			bram_g_data_out_a => bram_g_data_out_a_vector,
			bram_v_data_out_a => bram_v_data_out_a_vector,
			bram_r_data_out_a => bram_r_data_out_a_vector,
			bram_f_data_in_b  => bram_f_data_in_b_vector,
			bram_g_data_in_b  => bram_g_data_in_b_vector,
			bram_v_data_in_b  => bram_v_data_in_b_vector,
			bram_r_data_in_b  => bram_r_data_in_b_vector,
			bram_f_write_b    => bram_f_write_b,
			bram_g_write_b    => bram_g_write_b,
			bram_v_write_b    => bram_v_write_b,
			bram_r_write_b    => bram_r_write_b,
			bram_f_address_b  => bram_f_address_b,
			bram_g_address_b  => bram_g_address_b,
			bram_v_address_b  => bram_v_address_b,
			bram_r_address_b  => bram_r_address_b
		);

end architecture RTL;
