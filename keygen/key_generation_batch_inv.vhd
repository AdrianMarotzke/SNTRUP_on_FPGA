library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.constants.all;
use work.data_type.all;

-- Core key generation. Generates keys in batches. Batch size set in constants.pkg.vhdl
entity key_generation_batch_inv is
	port(
		clock                       : in  std_logic;
		reset                       : in  std_logic;
		start                       : in  std_logic;
		ready                       : out std_logic;
		done                        : out std_logic;
		output_h                    : out std_logic_vector(q_num_bits - 1 downto 0);
		output_h_valid              : out std_logic;
		output_h_ack                : in  std_logic;
		output_f                    : out std_logic_vector(1 downto 0);
		output_f_valid              : out std_logic;
		output_g_recip              : out std_logic_vector(1 downto 0);
		output_g_valid              : out std_logic;
		random_small_enable         : out std_logic;
		random_small_poly           : in  std_logic_vector(1 downto 0);
		small_weights_random_enable : out std_logic;
		small_weights_random_output : in  std_logic_vector(31 downto 0);
		to_rq_mult                  : out rq_multiplication_in_type;
		from_rq_mult                : in  rq_multiplication_out_type;
		to_small_weights            : out small_random_weights_in_type;
		from_small_weights          : in  small_random_weights_out_type
	);
end entity key_generation_batch_inv;

architecture RTL of key_generation_batch_inv is

	type state_type is (init_state, state_inv_wait, output_f_state, output_ginv, mult_g_finv, mult_g_finv_done, done_state);
	signal state_key_gen : state_type;

	type state_type_f is (init_state, gen_f, wait_gen_f, gen_f_done, wait_ainv_done, output_f_start, output_f_state, output_f_done, done_state);

	signal state_key_gen_f : state_type_f;

	type state_type_a is (init_state, gen_a, wait_gen_a, gen_a_done, inv_a_start, inv_a_done, mult_ainv_f, increment_f_read, done_state);
	signal state_key_gen_a : state_type_a;

	type state_type_a_inv is (init_state, gen_ainv, wait_gen_ainv, gen_ainv_done, mult_ainv_a, mult_ainv_a_wait, mult_ainv_a_done, mult_ainv_f, mult_ainv_f_wait, mult_ainv_f_done, gen_final_f, gen_final_f_wait, gen_final_f_done, done_state);
	signal state_key_gen_ainv : state_type_a_inv;

	type state_type_g_inv is (init_state, gen_g, wait_gen_g, wait_g_inv, g_inv_done, output_ginv_start, output_ginv_state, output_ginv_done, done_state);
	signal state_key_g_inv : state_type_g_inv;

	constant RAM_SIZE      : integer := BATCH_SIZE * p;
	constant RAM_SIZE_BITS : integer := integer(ceil(log2(real(RAM_SIZE))));

	function set_rounded_p
	return integer is
		variable temp : integer := 0;
	begin
		while temp < p loop
			temp := temp + 128;
		end loop;

		return temp;
	end function set_rounded_p;

	-- This rounding up of p to the nearest multiple of 128 makes the address calculation much simpler
	-- and means that no DSP are needed. for p = 761, it is rounded up to 768, so the loss of memory
	-- is neglibile. For batch sizes of 21 and 42, no extra BRAM is needed.
	constant rounded_p : integer := set_rounded_p;

	signal random_small_enable_out : std_logic;
	signal random_small_counter    : integer range 0 to p;

	signal random_small_counter_delay : std_logic_vector(p_num_bits - 1 downto 0);

	signal r3_recip_start         : std_logic;
	signal r3_recip_poly_in       : std_logic_vector(1 downto 0);
	signal r3_recip_poly_out      : std_logic_vector(1 downto 0);
	signal r3_recip_done          : std_logic;
	signal r3_recip_is_invertable : std_logic;
	signal r3_recip_ready         : std_logic;
	signal r3_recip_output_valid  : std_logic;

	signal small_weigh_start        : std_logic;
	signal small_weights_out_enable : std_logic;
	signal small_weights_valid      : std_logic;
	signal small_weights_out        : signed(1 downto 0);
	signal small_weights_done       : std_logic;

	signal rq_recip3_start        : std_logic;
	signal rq_recip3_poly_in      : std_logic_vector(q_num_bits - 1 downto 0);
	signal rq_recip3_ready        : std_logic;
	signal rq_recip3_output_poly  : std_logic_vector(q_num_bits - 1 downto 0);
	signal rq_recip3_output_valid : std_logic;
	signal rq_recip3_done         : std_logic;
	signal rq_recip3_f_address    : std_logic_vector(p_num_bits - 1 downto 0);

	signal rq_mult_rq_start        : std_logic;
	signal rq_mult_rq_ready        : std_logic;
	signal rq_mult_rq_output_valid : std_logic;
	signal rq_mult_rq_output       : std_logic_vector(q_num_bits - 1 downto 0);
	signal rq_mult_rq_done         : std_logic;

	signal rq_mult_start        : std_logic;
	signal rq_mult_ready        : std_logic;
	signal rq_mult_output_valid : std_logic;
	signal rq_mult_output       : std_logic_vector(q_num_bits - 1 downto 0);
	signal rq_mult_output_ack   : std_logic;
	signal rq_mult_done         : std_logic;

	signal rq_mult_bram_f_address_a  : std_logic_vector(p_num_bits - 1 downto 0);
	signal rq_mult_bram_f_data_out_a : std_logic_vector(q_num_bits - 1 downto 0);
	signal rq_mult_bram_f_address_b  : std_logic_vector(p_num_bits - 1 downto 0);
	signal rq_mult_bram_f_data_out_b : std_logic_vector(q_num_bits - 1 downto 0);
	signal rq_mult_bram_g_address_a  : std_logic_vector(p_num_bits - 1 downto 0);
	signal rq_mult_bram_g_data_out_a : std_logic_vector(2 - 1 downto 0);
	signal rq_mult_bram_g_address_b  : std_logic_vector(p_num_bits - 1 downto 0);
	signal rq_mult_bram_g_data_out_b : std_logic_vector(2 - 1 downto 0);

	signal bram_f_address_a  : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_f_write_a    : std_logic;
	signal bram_f_data_in_a  : std_logic_vector(2 - 1 downto 0);
	signal bram_f_data_out_a : std_logic_vector(2 - 1 downto 0);
	signal bram_f_address_b  : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_f_write_b    : std_logic;
	signal bram_f_data_in_b  : std_logic_vector(2 - 1 downto 0);
	signal bram_f_data_out_b : std_logic_vector(2 - 1 downto 0);

	signal bram_g_address_a      : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_g_write_a        : std_logic;
	signal bram_g_data_in_a      : std_logic_vector(2 - 1 downto 0);
	signal bram_g_data_out_a     : std_logic_vector(2 - 1 downto 0);
	signal bram_g_address_b      : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_g_address_b_pipe : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_g_write_b        : std_logic;
	signal bram_g_write_b_pipe   : std_logic;
	signal bram_g_data_in_b      : std_logic_vector(2 - 1 downto 0);
	signal bram_g_data_out_b     : std_logic_vector(2 - 1 downto 0);

	signal bram_ginv_address_a  : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_ginv_write_a    : std_logic;
	signal bram_ginv_data_in_a  : std_logic_vector(2 - 1 downto 0);
	signal bram_ginv_data_out_a : std_logic_vector(2 - 1 downto 0);
	signal bram_ginv_address_b  : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_ginv_write_b    : std_logic;
	signal bram_ginv_data_in_b  : std_logic_vector(2 - 1 downto 0);
	signal bram_ginv_data_out_b : std_logic_vector(2 - 1 downto 0);

	signal bram_a_address_a  : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_a_write_a    : std_logic;
	signal bram_a_data_in_a  : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_a_data_out_a : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_a_address_b  : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_a_write_b    : std_logic;
	signal bram_a_data_in_b  : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_a_data_out_b : std_logic_vector(q_num_bits - 1 downto 0);

	signal bram_ainv_address_a  : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_ainv_write_a    : std_logic;
	signal bram_ainv_data_in_a  : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_ainv_data_out_a : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_ainv_address_b  : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_ainv_write_b    : std_logic;
	signal bram_ainv_data_in_b  : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_ainv_data_out_b : std_logic_vector(q_num_bits - 1 downto 0);

	signal bram_finv_address_a  : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_finv_write_a    : std_logic;
	signal bram_finv_data_in_a  : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_finv_data_out_a : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_finv_address_b  : std_logic_vector(RAM_SIZE_BITS - 1 downto 0);
	signal bram_finv_write_b    : std_logic;
	signal bram_finv_data_in_b  : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_finv_data_out_b : std_logic_vector(q_num_bits - 1 downto 0);

	attribute use_dsp : string;

	signal bram_f_read_position  : integer range 0 to BATCH_SIZE;
	signal bram_f_write_position : integer range 0 to BATCH_SIZE;
	signal f_counter             : integer range 0 to p;

	signal bram_f_read_position_offset  : integer range 0 to BATCH_SIZE * rounded_p;
	signal bram_f_write_position_offset : integer range 0 to BATCH_SIZE * rounded_p;
	attribute use_dsp of bram_f_read_position_offset : signal is "no";
	attribute use_dsp of bram_f_write_position_offset : signal is "no";

	signal bram_a_read_position  : integer range 0 to BATCH_SIZE;
	signal bram_a_write_position : integer range 0 to BATCH_SIZE;
	signal a_counter             : integer range 0 to p;

	signal bram_a_read_position_offset  : integer range 0 to BATCH_SIZE * rounded_p;
	signal bram_a_write_position_offset : integer range 0 to BATCH_SIZE * rounded_p;
	attribute use_dsp of bram_a_read_position_offset : signal is "no";
	attribute use_dsp of bram_a_write_position_offset : signal is "no";

	signal bram_ainv_read_position  : integer range 0 to BATCH_SIZE;
	signal bram_ainv_write_position : integer range 0 to BATCH_SIZE;
	signal ainv_counter             : integer range 0 to p;

	signal bram_ainv_read_position_offset  : integer range 0 to BATCH_SIZE * rounded_p;
	signal bram_ainv_write_position_offset : integer range 0 to BATCH_SIZE * rounded_p;
	attribute use_dsp of bram_ainv_read_position_offset : signal is "no";
	attribute use_dsp of bram_ainv_write_position_offset : signal is "no";

	signal bram_finv_read_position  : integer range 0 to BATCH_SIZE;
	signal bram_finv_write_position : integer range 0 to BATCH_SIZE;
	signal finv_counter             : integer range 0 to p;

	signal bram_finv_read_position_offset  : integer range 0 to BATCH_SIZE * rounded_p;
	signal bram_finv_write_position_offset : integer range 0 to BATCH_SIZE * rounded_p;
	attribute use_dsp of bram_finv_read_position_offset : signal is "no";
	attribute use_dsp of bram_finv_write_position_offset : signal is "no";

	signal bram_g_read_position  : integer range 0 to BATCH_SIZE;
	signal bram_g_write_position : integer range 0 to BATCH_SIZE;
	signal g_counter             : integer range 0 to p;

	signal bram_g_read_position_offset : integer range 0 to BATCH_SIZE * rounded_p;
	attribute use_dsp of bram_g_read_position_offset : signal is "no";

	signal bram_ginv_read_position  : integer range 0 to BATCH_SIZE;
	signal bram_ginv_write_position : integer range 0 to BATCH_SIZE;
	signal ginv_counter             : integer range 0 to p;

	signal bram_ginv_read_position_offset  : integer range 0 to BATCH_SIZE * rounded_p;
	signal bram_ginv_write_position_offset : integer range 0 to BATCH_SIZE * rounded_p;
	attribute use_dsp of bram_ginv_read_position_offset : signal is "no";
	attribute use_dsp of bram_ginv_write_position_offset : signal is "no";

	signal gen_a_mult_start        : std_logic;
	signal gen_a_mult_ready        : std_logic;
	signal gen_a_mult_done         : std_logic;
	signal gen_a_mult_output       : std_logic_vector(q_num_bits - 1 downto 0);
	signal gen_a_mult_output_valid : std_logic;

	signal gen_ainv_mult_start : std_logic;

	signal gen_finv_mult_start : std_logic;

	signal x_address_a  : std_logic_vector(p_num_bits - 1 downto 0);
	signal x_data_out_a : std_logic_vector(q_num_bits - 1 downto 0);
	signal x_address_b  : std_logic_vector(p_num_bits - 1 downto 0);
	signal x_data_out_b : std_logic_vector(q_num_bits - 1 downto 0);
	signal y_address_a  : std_logic_vector(p_num_bits - 1 downto 0);
	signal y_data_out_a : std_logic_vector(q_num_bits - 1 downto 0);
	signal y_address_b  : std_logic_vector(p_num_bits - 1 downto 0);
	signal y_data_out_b : std_logic_vector(q_num_bits - 1 downto 0);

	attribute use_dsp of bram_f_address_a : signal is "no";
	attribute use_dsp of bram_f_address_b : signal is "no";
	attribute use_dsp of bram_a_address_a : signal is "no";
	attribute use_dsp of bram_a_address_b : signal is "no";
	attribute use_dsp of bram_g_address_a : signal is "no";
	attribute use_dsp of bram_g_address_b : signal is "no";
	attribute use_dsp of bram_ainv_address_a : signal is "no";
	attribute use_dsp of bram_ainv_address_b : signal is "no";
	attribute use_dsp of bram_finv_address_a : signal is "no";
	attribute use_dsp of bram_finv_address_b : signal is "no";
	attribute use_dsp of bram_ginv_address_a : signal is "no";
	attribute use_dsp of bram_ginv_address_b : signal is "no";
begin
	main_fsm : process(clock, reset) is
	begin
		if reset = '1' then
			state_key_gen <= init_state;
		elsif rising_edge(clock) then
			case state_key_gen is
				when init_state =>
					ready                   <= '1';
					if start = '1' then
						state_key_gen <= state_inv_wait;
					end if;
					rq_mult_start           <= '0';
					bram_finv_read_position <= 0;
					bram_g_read_position    <= 0;
					done                    <= '0';
				when state_inv_wait =>
					ready <= '0';
					if state_key_gen_ainv = done_state then
						state_key_gen <= output_f_state;
					end if;
				when output_f_state =>
					if state_key_gen_f = output_f_done then
						state_key_gen <= output_ginv;
					end if;
				when output_ginv =>
					if state_key_g_inv = output_ginv_done then
						state_key_gen <= mult_g_finv;
						rq_mult_start <= '1';
					end if;
				when mult_g_finv =>
					if rq_mult_done = '1' then
						state_key_gen           <= mult_g_finv_done;
						bram_g_read_position    <= bram_g_read_position + 1;
						bram_finv_read_position <= bram_finv_read_position + 1;
					end if;
					rq_mult_start <= '0';
				when mult_g_finv_done =>
					ready <= '1';
					if start = '1' then
						state_key_gen <= output_f_state;
						ready         <= '0';
					end if;
					if bram_g_read_position = BATCH_SIZE then
						state_key_gen <= done_state;
					end if;
				when done_state =>
					done          <= '1';
					state_key_gen <= init_state;
			end case;
		end if;
	end process main_fsm;

	fsm_generate_f : process(clock, reset) is
	begin
		if reset = '1' then
			state_key_gen_f          <= init_state;
			small_weigh_start        <= '0';
			small_weights_out_enable <= '0';
		elsif rising_edge(clock) then
			case state_key_gen_f is
				when init_state =>
					if start = '1' and state_key_gen = init_state then
						state_key_gen_f <= gen_f;
					else
						state_key_gen_f <= init_state;
					end if;
					bram_f_write_position <= 0;
					output_f_valid        <= '0';
				when gen_f =>
					state_key_gen_f   <= wait_gen_f;
					small_weigh_start <= '1';
					f_counter         <= 0;
				when wait_gen_f =>
					if small_weights_done = '1' then
						state_key_gen_f <= gen_f_done;
					end if;

					if small_weights_valid = '1' then
						f_counter <= f_counter + 1;
					end if;

					small_weigh_start        <= '0';
					small_weights_out_enable <= '1';
				when gen_f_done =>
					if bram_f_write_position = BATCH_SIZE - 1 then
						state_key_gen_f <= wait_ainv_done;
					else
						state_key_gen_f <= gen_f;
					end if;
					bram_f_write_position    <= bram_f_write_position + 1;
					small_weights_out_enable <= '0';
				when wait_ainv_done =>
					if rq_recip3_done = '1' then
						state_key_gen_f <= output_f_start;
					end if;
				when output_f_start =>
					f_counter <= 0;
					if state_key_gen = output_f_state then
						state_key_gen_f <= output_f_state;
					end if;

				when output_f_state =>
					f_counter      <= f_counter + 1;
					if f_counter = p - 1 then
						state_key_gen_f <= output_f_done;

					end if;
					output_f_valid <= '1';
				when output_f_done =>
					output_f_valid <= '0';
					if bram_f_read_position = BATCH_SIZE - 1 then
						state_key_gen_f <= done_state;
					else
						state_key_gen_f <= output_f_start;
					end if;
				when done_state =>
					if state_key_gen = done_state then
						state_key_gen_f <= init_state;
					end if;
			end case;
		end if;
	end process fsm_generate_f;

	bram_f_address_a <= std_logic_vector(to_unsigned(f_counter + bram_f_write_position_offset, RAM_SIZE_BITS)) when small_weights_valid = '1'
	                    else std_logic_vector(resize(unsigned(rq_mult_bram_g_address_a), RAM_SIZE_BITS) + bram_f_read_position_offset) when state_key_gen_a = gen_a or state_key_gen_a = wait_gen_a
	                    else std_logic_vector(resize(unsigned(rq_mult_bram_g_address_a), RAM_SIZE_BITS) + bram_f_read_position_offset) when state_key_gen_ainv = mult_ainv_f_wait or state_key_gen_ainv = gen_final_f_wait
	                    else std_logic_vector(resize(unsigned(x_address_a), RAM_SIZE_BITS) + bram_f_read_position_offset);

	bram_f_data_in_a <= std_logic_vector(small_weights_out);
	bram_f_write_a   <= small_weights_valid when state_key_gen_f = wait_gen_f else '0';

	bram_f_address_b <= std_logic_vector(to_unsigned(f_counter + bram_f_read_position_offset, RAM_SIZE_BITS)) when state_key_gen_f = output_f_state
	                    else std_logic_vector(resize(unsigned(rq_mult_bram_g_address_b), RAM_SIZE_BITS) + bram_f_read_position_offset) when state_key_gen_a = gen_a or state_key_gen_a = wait_gen_a
	                    else std_logic_vector(resize(unsigned(x_address_b), RAM_SIZE_BITS) + bram_f_read_position_offset);

	output_f <= bram_f_data_out_b(1 downto 0);

	fsm_generate_a : process(clock, reset) is
	begin
		if reset = '1' then
			state_key_gen_a <= init_state;
		elsif rising_edge(clock) then
			case state_key_gen_a is
				when init_state =>
					if bram_f_write_position = BATCH_SIZE and state_key_gen /= init_state then
						state_key_gen_a <= gen_a;
					end if;

					bram_f_read_position  <= 1;
					bram_a_read_position  <= 0;
					bram_a_write_position <= 1;

					gen_a_mult_start <= '0';
					rq_recip3_start  <= '0';
				when gen_a =>
					if small_weights_valid /= '1' then
						state_key_gen_a  <= wait_gen_a;
						gen_a_mult_start <= '1';
						a_counter        <= 0;
					end if;
				when wait_gen_a =>
					if gen_a_mult_done = '1' then
						state_key_gen_a <= gen_a_done;
					end if;

					if gen_a_mult_output_valid = '1' then
						a_counter <= a_counter + 1;
					end if;

					gen_a_mult_start <= '0';
				when gen_a_done =>
					if bram_a_write_position = BATCH_SIZE - 1 then
						state_key_gen_a <= inv_a_start;
						a_counter       <= 0;
					else
						state_key_gen_a <= gen_a;
					end if;
					bram_f_read_position  <= bram_f_read_position + 1;
					bram_a_read_position  <= bram_a_read_position + 1;
					bram_a_write_position <= bram_a_write_position + 1;
				when inv_a_start =>
					rq_recip3_start <= '1';
					a_counter       <= a_counter + 1;

					if a_counter = p - 1 then
						state_key_gen_a <= inv_a_done;
					end if;
				when inv_a_done =>
					rq_recip3_start      <= '0';
					bram_a_read_position <= bram_a_read_position - 1;
					state_key_gen_a      <= mult_ainv_f;
				when mult_ainv_f =>
					if state_key_gen_ainv = mult_ainv_a_done or state_key_gen_ainv = gen_final_f_done then
						bram_f_read_position <= bram_f_read_position - 1;
						bram_a_read_position <= bram_a_read_position - 1;
					end if;

					if bram_f_read_position = 0 then
						state_key_gen_a <= increment_f_read;
					end if;
				when increment_f_read =>
					if state_key_gen_f = output_f_done then
						bram_f_read_position <= bram_f_read_position + 1;
					end if;
					if bram_f_read_position = BATCH_SIZE - 1 then
						state_key_gen_a <= done_state;
					end if;
				when done_state =>
					if state_key_gen = done_state then
						state_key_gen_a <= init_state;
					end if;
			end case;
		end if;
	end process fsm_generate_a;

	bram_a_address_a <= std_logic_vector(to_unsigned(f_counter + bram_f_write_position_offset, RAM_SIZE_BITS)) when bram_f_write_position = 0 and state_key_gen_a = init_state
	                    else std_logic_vector(to_unsigned(a_counter + bram_a_write_position_offset, RAM_SIZE_BITS)) when gen_a_mult_output_valid = '1'
	                    else std_logic_vector(resize(unsigned(rq_mult_bram_f_address_a), RAM_SIZE_BITS) + bram_a_read_position_offset) when state_key_gen_a = gen_a or state_key_gen_a = wait_gen_a
	                    else std_logic_vector(resize(unsigned(y_address_a), RAM_SIZE_BITS) + bram_a_read_position_offset);

	bram_a_data_in_a <= std_logic_vector(resize(signed(small_weights_out), q_num_bits)) when bram_f_write_position = 0 and state_key_gen_a = init_state else gen_a_mult_output;
	bram_a_write_a   <= small_weights_valid when state_key_gen_f = wait_gen_f and state_key_gen_a = init_state and bram_f_write_position = 0
	                    else gen_a_mult_output_valid when state_key_gen_a = wait_gen_a
	                    else '0';

	bram_a_address_b <= std_logic_vector(resize(unsigned(rq_mult_bram_f_address_a), RAM_SIZE_BITS) + bram_a_read_position_offset) when state_key_gen_a = gen_a or state_key_gen_a = wait_gen_a
	                    else std_logic_vector(resize(unsigned(y_address_b), RAM_SIZE_BITS) + bram_a_read_position_offset) when state_key_gen_a /= inv_a_start
	                    else std_logic_vector(to_unsigned(a_counter + bram_a_read_position_offset, RAM_SIZE_BITS));

	--
	--
	--

	x_data_out_b <= std_logic_vector(resize(signed(bram_f_data_out_b), q_num_bits)) when state_key_gen_ainv = gen_ainv or state_key_gen_ainv = wait_gen_ainv else bram_ainv_data_out_b;

	x_data_out_a <= std_logic_vector(resize(signed(bram_f_data_out_a), q_num_bits)) when state_key_gen_ainv = gen_ainv or state_key_gen_ainv = wait_gen_ainv else bram_ainv_data_out_a;

	y_data_out_b <= bram_a_data_out_b when state_key_gen_ainv /= mult_ainv_f and state_key_gen_ainv /= mult_ainv_f_wait and state_key_gen_ainv /= gen_final_f_wait else std_logic_vector(resize(signed(bram_f_data_out_b), q_num_bits));

	y_data_out_a <= bram_a_data_out_a when state_key_gen_ainv /= mult_ainv_f and state_key_gen_ainv /= mult_ainv_f_wait and state_key_gen_ainv /= gen_final_f_wait else std_logic_vector(resize(signed(bram_f_data_out_a), q_num_bits));

	rq_mult_rq_start <= gen_finv_mult_start;

	gen_a_mult_ready        <= rq_mult_ready;
	gen_a_mult_output_valid <= rq_mult_output_valid;
	gen_a_mult_output       <= rq_mult_output;
	gen_a_mult_done         <= rq_mult_done;

	NTT_wrapper_inst : entity work.NTT_wrapper
		port map(
			clock             => clock,
			reset             => reset,
			start             => rq_mult_rq_start,
			ready             => rq_mult_rq_ready,
			output_valid      => rq_mult_rq_output_valid,
			output            => rq_mult_rq_output,
			done              => rq_mult_rq_done,
			bram_f_address_a  => x_address_a,
			bram_f_data_out_a => x_data_out_a,
			bram_f_address_b  => x_address_b,
			bram_f_data_out_b => x_data_out_b,
			bram_g_address_a  => y_address_a,
			bram_g_data_out_a => y_data_out_a,
			bram_g_address_b  => y_address_b,
			bram_g_data_out_b => y_data_out_b
		);
	
--	rq_mult_rq_NTT_inst : entity work.rq_mult_rq_NTT
--		port map(
--			clock             => clock,
--			reset             => reset,
--			start             => rq_mult_rq_start,
--			ready             => rq_mult_rq_ready,
--			output_valid      => rq_mult_rq_output_valid,
--			output            => rq_mult_rq_output,
--			done              => rq_mult_rq_done,
--			bram_f_address_a  => x_address_a,
--			bram_f_data_out_a => x_data_out_a,
--			bram_f_address_b  => x_address_b,
--			bram_f_data_out_b => x_data_out_b,
--			bram_g_address_a  => y_address_a,
--			bram_g_data_out_a => y_data_out_a,
--			bram_g_address_b  => y_address_b,
--			bram_g_data_out_b => y_data_out_b
--		);

	gen_rq_reciprocal_vector : if keygen_vector_width >= 1 generate
		rq_reciprocal_3_inst : entity work.rq_reciprocal_3_vector
			port map(
				clock               => clock,
				reset               => reset,
				start               => rq_recip3_start,
				small_polynomial_in => rq_recip3_poly_in,
				ready               => rq_recip3_ready,
				output_polynomial   => rq_recip3_output_poly,
				output_valid        => rq_recip3_output_valid,
				done                => rq_recip3_done
			);
	end generate gen_rq_reciprocal_vector;

	gen_rq_reciprocal : if keygen_vector_width = 0 generate
		rq_reciprocal_3_inst : entity work.rq_reciprocal_3
			port map(
				clock               => clock,
				reset               => reset,
				start               => rq_recip3_start,
				small_polynomial_in => rq_recip3_poly_in,
				ready               => rq_recip3_ready,
				output_polynomial   => rq_recip3_output_poly,
				output_valid        => rq_recip3_output_valid,
				done                => rq_recip3_done
			);
	end generate gen_rq_reciprocal;

	rq_recip3_poly_in <= bram_a_data_out_b;

	fsm_gen_a_inv : process(clock, reset) is
	begin
		if reset = '1' then
			state_key_gen_ainv <= init_state;
		elsif rising_edge(clock) then
			case state_key_gen_ainv is
				when init_state =>
					if state_key_gen /= init_state then
						state_key_gen_ainv <= gen_ainv;
					end if;
					bram_ainv_write_position <= BATCH_SIZE - 1;
					bram_ainv_read_position  <= BATCH_SIZE - 1;

					bram_finv_write_position <= BATCH_SIZE - 1;
					gen_ainv_mult_start      <= '0';
					gen_finv_mult_start      <= '0';
				when gen_ainv =>
					if rq_recip3_start = '1' then
						state_key_gen_ainv <= wait_gen_ainv;
					end if;
					ainv_counter <= 0;
				when wait_gen_ainv =>
					if rq_recip3_output_valid = '1' then
						ainv_counter <= ainv_counter + 1;
					end if;

					if rq_recip3_done = '1' then
						state_key_gen_ainv <= gen_ainv_done;
					end if;
				when gen_ainv_done =>
					if rq_recip3_output_valid = '1' then
						ainv_counter <= ainv_counter + 1;
					else
						state_key_gen_ainv <= mult_ainv_a;

					end if;

				when mult_ainv_a =>
					gen_finv_mult_start      <= '1';
					state_key_gen_ainv       <= mult_ainv_a_wait;
					finv_counter             <= 0;
					bram_ainv_write_position <= bram_ainv_write_position - 1;
				when mult_ainv_a_wait =>
					gen_finv_mult_start <= '0';
					if rq_mult_rq_output_valid = '1' then
						finv_counter <= finv_counter + 1;
					end if;
					if rq_mult_rq_done = '1' then
						state_key_gen_ainv <= mult_ainv_a_done;
					end if;
				when mult_ainv_a_done =>
					state_key_gen_ainv       <= mult_ainv_f;
					bram_finv_write_position <= bram_finv_write_position - 1;

					if bram_finv_write_position = 1 then
						state_key_gen_ainv <= gen_final_f;
					end if;

				when mult_ainv_f =>
					gen_ainv_mult_start <= '1';
					state_key_gen_ainv  <= mult_ainv_f_wait;
					ainv_counter        <= 0;
				when mult_ainv_f_wait =>
					gen_ainv_mult_start <= '0';
					if rq_mult_output_valid = '1' then
						ainv_counter <= ainv_counter + 1;
					end if;
					if rq_mult_done = '1' then
						state_key_gen_ainv <= mult_ainv_f_done;
					end if;
				when mult_ainv_f_done =>
					state_key_gen_ainv      <= mult_ainv_a;
					bram_ainv_read_position <= bram_ainv_read_position - 1;
				when gen_final_f =>
					gen_ainv_mult_start <= '1';
					finv_counter        <= 0;
					state_key_gen_ainv  <= gen_final_f_wait;
				when gen_final_f_wait =>
					gen_ainv_mult_start <= '0';
					if rq_mult_output_valid = '1' then
						finv_counter <= finv_counter + 1;
					end if;
					if rq_mult_done = '1' then
						state_key_gen_ainv <= gen_final_f_done;
					end if;
				when gen_final_f_done =>
					state_key_gen_ainv <= done_state;
				when done_state =>
					if state_key_gen = done_state then
						state_key_gen_ainv <= init_state;
					end if;
			end case;
		end if;
	end process fsm_gen_a_inv;

	bram_ainv_address_a <= std_logic_vector(to_unsigned(ainv_counter + bram_ainv_write_position_offset, RAM_SIZE_BITS)) when state_key_gen_ainv = gen_ainv or --
	                       state_key_gen_ainv = wait_gen_ainv or state_key_gen_ainv = gen_ainv_done or (state_key_gen_ainv = mult_ainv_f_wait and rq_mult_output_valid = '1') --
	                       else std_logic_vector(resize(unsigned(rq_mult_bram_f_address_a), RAM_SIZE_BITS) + bram_ainv_read_position_offset) when state_key_gen_ainv = mult_ainv_f_wait or state_key_gen_ainv = gen_final_f_wait
	                       else std_logic_vector(resize(unsigned(x_address_a), RAM_SIZE_BITS) + bram_ainv_read_position_offset);

	bram_ainv_data_in_a <= rq_recip3_output_poly when state_key_gen_ainv /= mult_ainv_f_wait else rq_mult_output;
	bram_ainv_write_a   <= rq_recip3_output_valid when state_key_gen_ainv /= mult_ainv_f_wait
	                       else rq_mult_output_valid when state_key_gen_ainv = mult_ainv_f_wait
	                       else '0';

	bram_ainv_address_b <= std_logic_vector(resize(unsigned(x_address_b), RAM_SIZE_BITS) + bram_ainv_read_position_offset);

	bram_finv_address_a <= std_logic_vector(to_unsigned(finv_counter + bram_finv_write_position_offset, RAM_SIZE_BITS));
	bram_finv_data_in_a <= rq_mult_rq_output when state_key_gen_ainv = mult_ainv_a_wait else rq_mult_output;
	bram_finv_write_a   <= rq_mult_rq_output_valid when state_key_gen_ainv = mult_ainv_a_wait
	                       else rq_mult_output_valid when state_key_gen_ainv = gen_final_f_wait
	                       else '0';

	generate_g_inv : process(clock, reset) is
	begin
		if reset = '1' then
			state_key_g_inv <= init_state;
		elsif rising_edge(clock) then
			case state_key_g_inv is
				when init_state =>
					if state_key_gen_f = wait_ainv_done then
						state_key_g_inv <= gen_g;
					end if;

					r3_recip_start           <= '0';
					ginv_counter             <= 0;
					g_counter                <= p - 1;
					random_small_enable      <= '0';
					bram_ginv_write_position <= 0;
					bram_ginv_read_position  <= 0;
					output_g_valid           <= '0';
				when gen_g =>
					if from_small_weights.random_enable = '0' then
						r3_recip_start  <= '1';
						state_key_g_inv <= wait_gen_g;
					end if;
				when wait_gen_g =>
					r3_recip_start <= '0';
					if ginv_counter <= p - 1 then
						random_small_enable <= '1';
						ginv_counter        <= ginv_counter + 1;
						g_counter           <= g_counter - 1;
					else
						random_small_enable <= '0';
						state_key_g_inv     <= wait_g_inv;
						ginv_counter        <= 0;
					end if;
				when wait_g_inv =>
					if r3_recip_output_valid = '1' then
						ginv_counter <= ginv_counter + 1;
					end if;

					if r3_recip_done = '1' then
						if r3_recip_is_invertable = '1' then
							state_key_g_inv <= g_inv_done;
						else
							state_key_g_inv <= gen_g;
							ginv_counter    <= 0;
							g_counter       <= p - 1;
						end if;
					end if;
				when g_inv_done =>
					if bram_ginv_write_position = BATCH_SIZE - 1 then
						state_key_g_inv <= output_ginv_start;
					else
						state_key_g_inv          <= gen_g;
						bram_ginv_write_position <= bram_ginv_write_position + 1;
					end if;
					ginv_counter <= 0;
					g_counter    <= p - 1;
				when output_ginv_start =>
					ginv_counter <= 0;
					if state_key_gen = output_ginv then
						state_key_g_inv <= output_ginv_state;
					end if;
				when output_ginv_state =>
					ginv_counter <= ginv_counter + 1;
					if ginv_counter = p - 1 then
						state_key_g_inv <= output_ginv_done;
					end if;

					output_g_valid <= '1';
				when output_ginv_done =>
					output_g_valid <= '0';
					if bram_ginv_read_position = BATCH_SIZE - 1 then
						state_key_g_inv <= done_state;
					else
						state_key_g_inv         <= output_ginv_start;
						bram_ginv_read_position <= bram_ginv_read_position + 1;
					end if;

				when done_state =>
					if state_key_gen = done_state then
						state_key_g_inv <= init_state;
					end if;
			end case;
		end if;
	end process generate_g_inv;

	r3_recip_poly_in <= random_small_poly;

	bram_g_address_b_pipe <= std_logic_vector(to_unsigned(g_counter + bram_ginv_write_position_offset, RAM_SIZE_BITS));
	bram_g_address_b      <= bram_g_address_b_pipe when rising_edge(clock);

	bram_g_data_in_b <= random_small_poly;

	bram_g_write_b_pipe <= '1' when state_key_g_inv = wait_gen_g and ginv_counter <= p - 1 else '0';
	bram_g_write_b      <= bram_g_write_b_pipe when rising_edge(clock);

	bram_ginv_address_b <= std_logic_vector(to_unsigned(ginv_counter + bram_ginv_read_position_offset, RAM_SIZE_BITS)) when state_key_g_inv = output_ginv_state else -- 
	                       std_logic_vector(to_unsigned(ginv_counter + bram_ginv_write_position_offset, RAM_SIZE_BITS));
	bram_ginv_data_in_b <= r3_recip_poly_out;
	bram_ginv_write_b   <= r3_recip_output_valid when state_key_g_inv = wait_g_inv else '0';

	output_g_recip <= bram_ginv_data_out_b;

	r3_reciprocal_inst : entity work.r3_reciprocal_vector
		port map(
			clock               => clock,
			reset               => reset,
			start               => r3_recip_start,
			small_polynomial_in => r3_recip_poly_in,
			ready               => r3_recip_ready,
			output_polynomial   => r3_recip_poly_out,
			output_valid        => r3_recip_output_valid,
			is_invertable       => r3_recip_is_invertable,
			done                => r3_recip_done
		);

	bram_g_address_a          <= std_logic_vector(resize(unsigned(rq_mult_bram_g_address_a), RAM_SIZE_BITS) + bram_g_read_position_offset);
	rq_mult_bram_g_data_out_a <= bram_f_data_out_a when state_key_gen_ainv = gen_ainv or state_key_gen_ainv = wait_gen_ainv
	                             else bram_f_data_out_a when state_key_gen_ainv = mult_ainv_f or state_key_gen_ainv = mult_ainv_f_wait or state_key_gen_ainv = gen_final_f_wait
	                             else bram_g_data_out_a;

	rq_mult_bram_f_data_out_a <= bram_a_data_out_a when state_key_gen_ainv = gen_ainv or state_key_gen_ainv = wait_gen_ainv
	                             else bram_ainv_data_out_a when state_key_gen_ainv = mult_ainv_f or state_key_gen_ainv = mult_ainv_f_wait or state_key_gen_ainv = gen_final_f_wait
	                             else bram_finv_data_out_b;

	bram_finv_address_b <= std_logic_vector(resize(unsigned(rq_mult_bram_f_address_a), RAM_SIZE_BITS) + bram_finv_read_position_offset); -- This is deliberate, we use port b of finv, but the multiplier only uses port a

	to_rq_mult.start             <= rq_mult_start or gen_a_mult_start or gen_ainv_mult_start;
	to_rq_mult.output_ack        <= rq_mult_output_ack;
	to_rq_mult.bram_f_data_out_a <= rq_mult_bram_f_data_out_a;
	to_rq_mult.bram_g_data_out_a <= rq_mult_bram_g_data_out_a;
	rq_mult_ready                <= from_rq_mult.ready;
	rq_mult_output_valid         <= from_rq_mult.output_valid;
	rq_mult_output               <= from_rq_mult.output;
	rq_mult_done                 <= from_rq_mult.done;

	rq_mult_output_ack <= '1';

	rq_mult_bram_f_address_a <= from_rq_mult.bram_f_address_a;
	rq_mult_bram_g_address_a <= from_rq_mult.bram_g_address_a;

	output_h       <= rq_mult_output;
	output_h_valid <= rq_mult_output_valid when state_key_gen = mult_g_finv else '0';

	bram_f_read_position_offset  <= bram_f_read_position * rounded_p;
	bram_f_write_position_offset <= bram_f_write_position * rounded_p;
	bram_g_read_position_offset  <= bram_g_read_position * rounded_p;
	bram_a_read_position_offset  <= bram_a_read_position * rounded_p;
	bram_a_write_position_offset <= bram_a_write_position * rounded_p;

	bram_finv_read_position_offset  <= bram_finv_read_position * rounded_p;
	bram_finv_write_position_offset <= bram_finv_write_position * rounded_p;
	bram_ginv_read_position_offset  <= bram_ginv_read_position * rounded_p;
	bram_ginv_write_position_offset <= bram_ginv_write_position * rounded_p;
	bram_ainv_read_position_offset  <= bram_ainv_read_position * rounded_p;
	bram_ainv_write_position_offset <= bram_ainv_write_position * rounded_p;
	--
	--
	--
	--
	--

	to_small_weights.random_output <= small_weights_random_output;
	to_small_weights.start         <= small_weigh_start;
	to_small_weights.output_enable <= small_weights_out_enable;

	small_weights_done          <= from_small_weights.done;
	small_weights_random_enable <= from_small_weights.random_enable;
	small_weights_out           <= from_small_weights.small_weights_out;
	small_weights_valid         <= from_small_weights.small_weights_valid;

	block_ram_f : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => RAM_SIZE_BITS,
			DATA_WIDTH    => 2,
			DUAL_PORT     => true
		)
		port map(
			clock      => clock,
			address_a  => bram_f_address_a,
			write_a    => bram_f_write_a,
			data_in_a  => bram_f_data_in_a,
			data_out_a => bram_f_data_out_a,
			address_b  => bram_f_address_b,
			write_b    => bram_f_write_b,
			data_in_b  => bram_f_data_in_b,
			data_out_b => bram_f_data_out_b
		);

	block_ram_g : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => RAM_SIZE_BITS,
			DATA_WIDTH    => 2
		)
		port map(
			clock      => clock,
			address_a  => bram_g_address_a,
			write_a    => bram_g_write_a,
			data_in_a  => bram_g_data_in_a,
			data_out_a => bram_g_data_out_a,
			address_b  => bram_g_address_b,
			write_b    => bram_g_write_b,
			data_in_b  => bram_g_data_in_b,
			data_out_b => bram_g_data_out_b
		);

	block_ram_ginv : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => RAM_SIZE_BITS,
			DATA_WIDTH    => 2
		)
		port map(
			clock      => clock,
			address_a  => bram_ginv_address_a,
			write_a    => bram_ginv_write_a,
			data_in_a  => bram_ginv_data_in_a,
			data_out_a => bram_ginv_data_out_a,
			address_b  => bram_ginv_address_b,
			write_b    => bram_ginv_write_b,
			data_in_b  => bram_ginv_data_in_b,
			data_out_b => bram_ginv_data_out_b
		);

	block_ram_f_inv : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => RAM_SIZE_BITS,
			DATA_WIDTH    => q_num_bits,
			DUAL_PORT     => true
		)
		port map(
			clock      => clock,
			address_a  => bram_finv_address_a,
			write_a    => bram_finv_write_a,
			data_in_a  => bram_finv_data_in_a,
			data_out_a => bram_finv_data_out_a,
			address_b  => bram_finv_address_b,
			write_b    => bram_finv_write_b,
			data_in_b  => bram_finv_data_in_b,
			data_out_b => bram_finv_data_out_b
		);

	block_ram_a : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => RAM_SIZE_BITS,
			DATA_WIDTH    => q_num_bits,
			DUAL_PORT     => true
		)
		port map(
			clock      => clock,
			address_a  => bram_a_address_a,
			write_a    => bram_a_write_a,
			data_in_a  => bram_a_data_in_a,
			data_out_a => bram_a_data_out_a,
			address_b  => bram_a_address_b,
			write_b    => bram_a_write_b,
			data_in_b  => bram_a_data_in_b,
			data_out_b => bram_a_data_out_b
		);

	block_ram_a_inv : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => RAM_SIZE_BITS,
			DATA_WIDTH    => q_num_bits,
			DUAL_PORT     => true
		)
		port map(
			clock      => clock,
			address_a  => bram_ainv_address_a,
			write_a    => bram_ainv_write_a,
			data_in_a  => bram_ainv_data_in_a,
			data_out_a => bram_ainv_data_out_a,
			address_b  => bram_ainv_address_b,
			write_b    => bram_ainv_write_b,
			data_in_b  => bram_ainv_data_in_b,
			data_out_b => bram_ainv_data_out_b
		);

end architecture RTL;
