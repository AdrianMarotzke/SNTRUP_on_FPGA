library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.data_type.all;

-- The wrapper for the core decapuslation. Constains en and decoding, and hashing and rencapsulation
entity key_decap_wrapper is
	port(
		clock                : in  std_logic;
		reset                : in  std_logic;
		secret_key_in        : in  std_logic_vector(7 downto 0);
		secret_input_address : out std_logic_vector(SecretKey_length_bits - 1 downto 0);
		key_new              : in  std_logic;
		key_is_set           : out std_logic;
		ready                : out std_logic;
		start_decap          : in  std_logic;
		cipher_input         : in  std_logic_vector(7 downto 0);
		cipher_input_address : out std_logic_vector(Cipher_bytes_bits - 1 downto 0);
		k_hash_out           : out std_logic_vector(63 downto 0);
		k_out_valid          : out std_logic;
		done                 : out std_logic;
		to_sha               : out sha_record_in_type;
		from_sha             : in  sha_record_out_type;
		to_decode_Rq         : out decode_Rq_in_type;
		from_decode_Rq       : in  decode_Rq_out_type;
		to_encode_Rq         : out encode_Rq_in_type;
		from_encode_Rq       : in  encode_Rq_out_type;
		to_encap_core        : out encap_core_in_type;
		from_encap_core      : in  encap_core_out_type;
		reencap_true         : out std_logic;
		to_rq_mult           : out rq_multiplication_in_type;
		from_rq_mult         : in  rq_multiplication_out_type;
		to_freeze_round      : out mod3_freeze_round_in_type;
		from_freeze_round    : in  mod3_freeze_round_out_type
	);
end entity key_decap_wrapper;

architecture RTL of key_decap_wrapper is

	type state_type is (IDLE, LOAD_NEW_SECRET_KEY, LOAD_NEW_SECRET_KEY_DECODE_START, LOAD_NEW_KEY_PK, LOAD_NEW_KEY_PK_2, LOAD_RHO, LOAD_PK_CACHE, KEY_READY,
	                    LOAD_CIPHER_WAIT,
	                    DECAP_CORE_START, DECAP_CORE_RQ, DECAP_CORE_R3, DECAP_CORE_WAIT, REENCAP, REENCAP_END, REENCAP_ENCODE, REENCAP_DIF_HASH, REENCAP_ENCODE_DONE,
	                    MASK_R_ENC, MASK_R_ENC_DONE, HASH_SESSION_START, HASH_SESSION, HASH_SESSION_END, DONE_STATE
	                   );
	signal state_dec_wrap : state_type;

	type state_type2 is (IDLE_ZX, DECODE_F, DECODE_GINV);
	signal state_Zx : state_type2;

	type state_type3 is (IDLE, LOAD_CIPHER, LOAD_CIPHER_HASH, LOAD_CIPHER_DONE);
	signal state_Rq_cipher : state_type3;

	signal key_decap_start           : std_logic;
	signal key_decap_done            : std_logic;
	signal key_decap_r_output        : std_logic_vector(1 downto 0);
	signal key_decap_r_output_valid  : std_logic;
	signal key_decap_key_ready       : std_logic;
	signal key_decap_ginv_address_a  : std_logic_vector(p_num_bits - 1 downto 0);
	signal key_decap_ginv_data_out_a : std_logic_vector(1 downto 0);
	signal key_decap_ginv_address_b  : std_logic_vector(p_num_bits - 1 downto 0);
	signal key_decap_ginv_data_out_b : std_logic_vector(1 downto 0);

	signal key_encap_ready               : std_logic;
	signal key_encap_done                : std_logic;
	signal key_encap_start_encap         : std_logic;
	signal key_encap_new_public_key      : std_logic;
	signal key_encap_public_key_in       : std_logic_vector(q_num_bits - 1 downto 0);
	signal key_encap_public_key_valid    : std_logic;
	signal key_encap_public_key_ready    : std_logic;
	signal key_encap_c_encrypt           : std_logic_vector(q_num_bits - 1 downto 0);
	signal key_encap_c_encrypt_valid     : std_logic;
	signal key_encap_r_secret            : std_logic_vector(1 downto 0);
	signal key_encap_r_secret_valid      : std_logic;
	signal key_encap_small_weights_start : std_logic;
	signal key_encap_small_weights_out   : std_logic_vector(1 downto 0);
	signal key_encap_small_weights_valid : std_logic;
	signal key_encap_small_weights_done  : std_logic;

	signal key_encap_c_encrypt_valid_pipe : std_logic;

	signal bram_ginv_address_a  : std_logic_vector(p_num_bits - 1 downto 0);
	signal bram_ginv_write_a    : std_logic;
	signal bram_ginv_data_in_a  : std_logic_vector(1 downto 0);
	signal bram_ginv_data_out_a : std_logic_vector(1 downto 0);
	signal bram_ginv_address_b  : std_logic_vector(p_num_bits - 1 downto 0);
	signal bram_ginv_write_b    : std_logic;
	signal bram_ginv_data_in_b  : std_logic_vector(1 downto 0);
	signal bram_ginv_data_out_b : std_logic_vector(1 downto 0);

	signal bram_f_address_a  : std_logic_vector(p_num_bits - 1 downto 0);
	signal bram_f_write_a    : std_logic;
	signal bram_f_data_in_a  : std_logic_vector(1 downto 0);
	signal bram_f_data_out_a : std_logic_vector(1 downto 0);
	signal bram_f_address_b  : std_logic_vector(p_num_bits - 1 downto 0);
	signal bram_f_write_b    : std_logic;
	signal bram_f_data_in_b  : std_logic_vector(1 downto 0);
	signal bram_f_data_out_b : std_logic_vector(1 downto 0);

	signal bram_c_address_a  : std_logic_vector(p_num_bits - 1 downto 0);
	signal bram_c_write_a    : std_logic;
	signal bram_c_data_in_a  : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_c_data_out_a : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_c_address_b  : std_logic_vector(p_num_bits - 1 downto 0);
	signal bram_c_write_b    : std_logic;
	signal bram_c_data_in_b  : std_logic_vector(q_num_bits - 1 downto 0);
	signal bram_c_data_out_b : std_logic_vector(q_num_bits - 1 downto 0);

	signal rq_mult_done : std_logic;

	signal decode_Rq_start        : std_logic;
	signal decode_Rq_input        : std_logic_vector(7 downto 0);
	signal decode_Rq_input_valid  : std_logic;
	signal decode_Rq_input_ack    : std_logic;
	signal decode_rounded_true    : std_logic;
	signal decode_Rq_output       : std_logic_vector(q_num_bits - 1 downto 0);
	signal decode_Rq_output_valid : std_logic;
	signal decode_Rq_done         : std_logic;
	signal decode_Rq_read_address : std_logic_vector(Cipher_bytes_bits - 1 downto 0);

	signal decode_Zx_input        : std_logic_vector(7 downto 0);
	signal decode_Zx_input_valid  : std_logic;
	signal decode_Zx_input_ack    : std_logic;
	signal decode_Zx_output       : std_logic_vector(1 downto 0);
	signal decode_Zx_output_valid : std_logic;
	signal decode_Zx_done         : std_logic;
	signal decode_Zx_start        : std_logic;

	signal counter        : integer range 0 to 2047;
	signal counter_c_diff : integer range 0 to 2047;
	signal counter_c_hash : integer range Ciphertexts_bytes to Ciphertexts_bytes + 32;
	signal counter_decode : integer range 0 to 2047;

	signal counter_pipe : integer range 0 to 2047;

	signal bram_pk_data_in_a : std_logic_vector(q_num_bits - 1 downto 0);

	signal bram_rho_address_a  : std_logic_vector(Small_bytes_bits - 1 downto 0);
	signal bram_rho_write_a    : std_logic;
	signal bram_rho_data_in_a  : std_logic_vector(7 downto 0);
	signal bram_rho_data_out_a : std_logic_vector(7 downto 0);

	signal sha_start_confirm         : std_logic;
	signal sha_r_encoded_in          : std_logic_vector(7 downto 0);
	signal sha_r_encoded_in_valid    : std_logic;
	signal sha_start_session         : std_logic;
	signal sha_c_encoded_in          : std_logic_vector(7 downto 0);
	signal sha_c_encoded_in_valid    : std_logic;
	signal sha_decode_Rq_input_ack   : std_logic;
	signal sha_decode_Rq_input_valid : std_logic;
	signal sha_finished              : std_logic;
	signal sha_ack_new_input         : std_logic;
	signal sha_out                   : std_logic_vector(63 downto 0);
	signal sha_out_address           : integer range 0 to 3;
	signal sha_out_read_en           : std_logic;
	signal sha_new_pk_cache          : std_logic;
	signal sha_pk_cache_in           : std_logic_vector(7 downto 0);
	signal sha_pk_cache_in_valid     : std_logic;
	signal sha_re_encap_session      : std_logic;
	signal sha_diff_mask             : std_logic_vector(7 downto 0);

	signal encode_Zx_input        : std_logic_vector(1 downto 0);
	signal encode_Zx_input_valid  : std_logic;
	signal encode_Zx_output       : std_logic_vector(7 downto 0);
	signal encode_Zx_output_valid : std_logic;
	signal encode_Zx_done         : std_logic;

	signal encode_Rq_start        : std_logic;
	signal encode_Rq_input        : std_logic_vector(q_num_bits - 1 downto 0);
	signal encode_Rq_input_valid  : std_logic;
	signal encode_Rq_m_input      : std_logic_vector(15 downto 0);
	signal encode_Rq_input_ack    : std_logic;
	signal encode_Rq_output       : std_logic_vector(7 downto 0);
	signal encode_Rq_output_valid : std_logic;
	signal encode_Rq_done         : std_logic;

	signal bram_c_diff_address_a  : std_logic_vector(Cipher_bytes_bits - 1 downto 0);
	signal bram_c_diff_write_a    : std_logic;
	signal bram_c_diff_data_in_a  : std_logic_vector(7 downto 0);
	signal bram_c_diff_data_out_a : std_logic_vector(7 downto 0);

	signal differentbits : std_logic_vector(15 downto 0);

	signal bram_r_enc_address_a  : std_logic_vector(Small_bytes_bits - 1 downto 0);
	signal bram_r_enc_write_a    : std_logic;
	signal bram_r_enc_data_in_a  : std_logic_vector(7 downto 0);
	signal bram_r_enc_data_out_a : std_logic_vector(7 downto 0);

	signal masked_r_enc       : std_logic_vector(7 downto 0);
	signal masked_r_enc_valid : std_logic;

	signal c_diff_bram_valid : std_logic;

	signal temp_s : std_logic_vector(7 downto 0);

	signal sha_record_in  : sha_record_in_type;
	signal sha_record_out : sha_record_out_type;

	signal key_decap_to_rq_mult   : rq_multiplication_in_type;
	signal key_decap_from_rq_mult : rq_multiplication_out_type;

	signal sha_out_counter : integer range 0 to 8;

	signal key_decap_f_address_a  : std_logic_vector(p_num_bits - 1 downto 0);
	signal key_decap_f_data_out_a : std_logic_vector(1 downto 0);
	signal key_decap_f_address_b  : std_logic_vector(p_num_bits - 1 downto 0);
	signal key_decap_f_data_out_b : std_logic_vector(1 downto 0);
	signal key_decap_c_address_a  : std_logic_vector(p_num_bits - 1 downto 0);
	signal key_decap_c_data_out_a : std_logic_vector(q_num_bits - 1 downto 0);
	signal key_decap_c_address_b  : std_logic_vector(p_num_bits - 1 downto 0);
	signal key_decap_c_data_out_b : std_logic_vector(q_num_bits - 1 downto 0);

	signal secret_key_fifo_write_enable : std_logic;
	signal secret_key_fifo_input        : std_logic_vector(8 - 1 downto 0);
	signal secret_key_fifo_read_enable  : std_logic;
	signal secret_key_fifo_output_valid : std_logic;
	signal secret_key_fifo_output       : std_logic_vector(8 - 1 downto 0);
	signal secret_key_fifo_empty        : std_logic;
	signal secret_key_fifo_empty_next   : std_logic;
	signal secret_key_fifo_full         : std_logic;
	signal secret_key_fifo_full_next    : std_logic;

	signal small_bytes_counter : integer range 0 to p;

	signal cipher_input_address_pipe : std_logic_vector(Cipher_bytes_bits - 1 downto 0);

	signal secret_key_valid      : std_logic;
	signal bram_rho_write_a_pipe : std_logic;

	signal decode_cipher_start              : std_logic;
	signal decode_cipher_input              : std_logic_vector(7 downto 0);
	signal decode_cipher_input_read_address : std_logic_vector(Cipher_bytes_bits - 1 downto 0);
	signal decode_cipher_input_valid        : std_logic;
	signal decode_cipher_input_ack          : std_logic;
	signal decode_cipher_output             : std_logic_vector(q_num_bits - 1 downto 0);
	signal decode_cipher_output_valid       : std_logic;
	signal decode_cipher_done               : std_logic;

begin

	decap_wrapper_process : process(clock, reset) is
	begin
		if reset = '1' then
			state_dec_wrap        <= IDLE;
			ready                 <= '0';
			key_is_set            <= '0';
			decode_Rq_start       <= '0';
			key_decap_start       <= '0';
			key_encap_start_encap <= '0';
			sha_new_pk_cache      <= '0';
			sha_start_confirm     <= '0';
			sha_start_session     <= '0';
			sha_re_encap_session  <= '0';
			encode_Rq_input_valid <= '0';
			masked_r_enc_valid    <= '0';
			c_diff_bram_valid     <= '0';
			done                  <= '0';
			k_out_valid           <= '0';
			sha_out_read_en       <= '0';
			encode_Rq_start       <= '0';
			key_decap_key_ready   <= '0';
			decode_Zx_start       <= '0';
			--bram_c_diff_write_a   <= '0';
			secret_key_valid      <= '0';
		elsif rising_edge(clock) then
			case state_dec_wrap is
				when IDLE =>
					if key_new = '1' then
						state_dec_wrap <= LOAD_NEW_SECRET_KEY;

						--decode_rounded_true <= '0';
						counter <= 0;
					end if;

					ready               <= '1';
					done                <= '0';
					k_out_valid         <= '0';
					sha_out_read_en     <= '0';
					sha_out_counter     <= 0;
					key_decap_key_ready <= '0';
					secret_key_valid    <= '0';
				when LOAD_NEW_SECRET_KEY =>
					decode_Zx_start <= '0';
					if secret_key_fifo_empty = '0' then
						state_dec_wrap  <= LOAD_NEW_SECRET_KEY_DECODE_START;
						decode_Zx_start <= '1';
					end if;

					ready <= '0';

					counter          <= counter + 1;
					secret_key_valid <= '1';
				when LOAD_NEW_SECRET_KEY_DECODE_START =>
					decode_Zx_start <= '0';
					counter         <= counter + 1;

					if counter = Small_bytes * 2 - 1 then
						state_dec_wrap  <= LOAD_NEW_KEY_PK;
						decode_Rq_start <= '1';
						counter         <= Small_bytes * 2 + PublicKeys_bytes - 1;

					end if;
				when LOAD_NEW_KEY_PK =>
					counter <= counter - 1;

					if counter = Small_bytes * 2 + p - 1 then
						counter             <= Small_bytes * 2;
						state_dec_wrap      <= LOAD_NEW_KEY_PK_2;
						key_decap_key_ready <= '1';
					end if;

					decode_Rq_start <= '0';
				when LOAD_NEW_KEY_PK_2 =>
					if counter /= Small_bytes * 2 + p then
						counter <= counter + 1;
					end if;

					if decode_Rq_done = '1' then
						state_dec_wrap   <= LOAD_RHO;
						counter          <= Small_bytes * 2 + PublicKeys_bytes;
						sha_new_pk_cache <= '1';
					end if;

					key_decap_key_ready <= '0';
				when LOAD_RHO =>
					counter <= counter + 1;

					if counter = Small_bytes * 2 + PublicKeys_bytes + Small_bytes - 1 then
						state_dec_wrap <= LOAD_PK_CACHE;
					end if;
					sha_new_pk_cache <= '0';
				when LOAD_PK_CACHE =>
					counter <= counter + 1;

					if counter = SecretKey_bytes then
						if state_Rq_cipher = IDLE then
							state_dec_wrap <= KEY_READY;
						else
							state_dec_wrap  <= LOAD_CIPHER_WAIT;
							key_is_set      <= '0';
							sha_out_read_en <= '0';
							sha_out_counter <= 0;
							counter_c_diff  <= 0;
						end if;

						counter          <= 0;
						secret_key_valid <= '0';
					end if;

				when KEY_READY =>
					ready               <= '1';
					key_is_set          <= '1';
					key_decap_key_ready <= '0';

					if start_decap = '1' then
						state_dec_wrap      <= LOAD_CIPHER_WAIT;
						counter_c_diff      <= 0;
						ready               <= '0';
						key_decap_key_ready <= '1';
					end if;

					if key_new = '1' then
						ready               <= '0';
						key_is_set          <= '0';
						state_dec_wrap      <= LOAD_NEW_SECRET_KEY;
						key_decap_key_ready <= '0';
					end if;

					counter         <= 0;
					done            <= '0';
					k_out_valid     <= '0';
					sha_out_read_en <= '0';
					sha_out_counter <= 0;
				when LOAD_CIPHER_WAIT =>
					key_decap_key_ready <= '0';
					if state_Rq_cipher = LOAD_CIPHER_DONE then
						state_dec_wrap <= DECAP_CORE_START;
						counter_c_diff <= 0;
					end if;
				when DECAP_CORE_START =>
					state_dec_wrap        <= DECAP_CORE_RQ;
					key_decap_start       <= '1';
					key_encap_start_encap <= '1';
					sha_start_confirm     <= '1';
					counter               <= 0;
				when DECAP_CORE_RQ =>
					if rq_mult_done = '1' then
						state_dec_wrap <= DECAP_CORE_R3;
					end if;

					key_decap_start       <= '0';
					key_encap_start_encap <= '0';
					sha_start_confirm     <= '0';
				when DECAP_CORE_R3 =>
					if key_decap_from_rq_mult.done = '1' then
						state_dec_wrap <= DECAP_CORE_WAIT;
					end if;
					if encode_Zx_output_valid = '1' then
						counter <= counter + 1;
					end if;
				when DECAP_CORE_WAIT =>
					if key_decap_done = '1' then
						state_dec_wrap  <= REENCAP;
						counter         <= 0;
						encode_Rq_start <= '1';
					end if;

					key_decap_start       <= '0';
					key_encap_start_encap <= '0';
					sha_start_confirm     <= '0';

					if encode_Zx_output_valid = '1' then
						counter <= counter + 1;
					end if;

					counter_c_diff <= 0;
					differentbits  <= (others => '0');
				when REENCAP =>
					if key_encap_c_encrypt_valid = '1' then
						counter <= counter + 1;
					end if;

					if bram_c_write_b = '1' and counter = 3 then
						encode_Rq_start       <= '0';
						encode_Rq_input_valid <= '1';
					end if;

					if key_encap_done = '1' then
						state_dec_wrap <= REENCAP_END;
						counter        <= 0;
					end if;

					if encode_Rq_output_valid = '1' then
						counter_c_diff            <= counter_c_diff + 1;
						differentbits(7 downto 0) <= differentbits(7 downto 0) OR (encode_Rq_output XOR bram_c_diff_data_out_a);
					end if;
				when REENCAP_END =>
					state_dec_wrap        <= REENCAP_ENCODE;
					encode_Rq_input_valid <= '1';

					if encode_Rq_output_valid = '1' then
						counter_c_diff            <= counter_c_diff + 1;
						differentbits(7 downto 0) <= differentbits(7 downto 0) OR (encode_Rq_output XOR bram_c_diff_data_out_a);
					end if;
				when REENCAP_ENCODE =>
					encode_Rq_start <= '0';

					if encode_Rq_input_ack = '1' and counter /= p - 1 then
						counter <= counter + 1;
					end if;

					if counter = p - 1 then
						encode_Rq_input_valid <= '0';
					end if;

					if encode_Rq_done = '1' and encode_Rq_output_valid = '0' and counter_c_diff = Ciphertexts_bytes then
						state_dec_wrap <= REENCAP_DIF_HASH;
						temp_s         <= sha_out(63 - sha_out_counter * 8 downto 64 - (sha_out_counter + 1) * 8);
					end if;

					sha_start_session <= '0';
					sha_out_address   <= 0;
					sha_out_read_en   <= '1';

					if encode_Rq_output_valid = '1' then
						counter_c_diff            <= counter_c_diff + 1;
						differentbits(7 downto 0) <= differentbits(7 downto 0) OR (encode_Rq_output XOR bram_c_diff_data_out_a);
					end if;
				when REENCAP_DIF_HASH =>
					if counter_c_diff = Ciphertexts_bytes + 32 - 1 then
						state_dec_wrap  <= REENCAP_ENCODE_DONE;
						sha_out_read_en <= '0';
					end if;
					counter_c_diff            <= counter_c_diff + 1;
					temp_s                    <= sha_out(63 - sha_out_counter * 8 downto 64 - (sha_out_counter + 1) * 8);
					differentbits(7 downto 0) <= differentbits(7 downto 0) OR (temp_s XOR bram_c_diff_data_out_a);

					if sha_out_counter = 7 then
						sha_out_counter <= 0;
					else
						sha_out_counter <= sha_out_counter + 1;
					end if;

					if sha_out_counter = 6 then
						sha_out_address <= sha_out_address + 1;
					end if;
				when REENCAP_ENCODE_DONE =>
					differentbits     <= std_logic_vector(("0000000000000001" AND shift_right(signed(differentbits(15 downto 8) & (differentbits(7 downto 0) OR (temp_s XOR bram_c_diff_data_out_a))) - 1, 8)) - 1);
					state_dec_wrap    <= MASK_R_ENC;
					counter           <= 0;
					sha_start_confirm <= '1';
				when MASK_R_ENC =>
					if counter = Small_bytes then
						state_dec_wrap <= MASK_R_ENC_DONE;
					end if;
					sha_start_confirm <= '0';

					if sha_ack_new_input = '1' then
						counter <= counter + 1;

					end if;
					masked_r_enc_valid <= '1';
				when MASK_R_ENC_DONE =>
					masked_r_enc_valid <= '0';
					if sha_finished = '1' then
						state_dec_wrap       <= HASH_SESSION_START;
						sha_start_session    <= '1';
						sha_re_encap_session <= '1';
						counter_c_diff       <= 0;
					end if;
				when HASH_SESSION_START =>
					state_dec_wrap    <= HASH_SESSION;
					sha_start_session <= '0';
				when HASH_SESSION =>

					if counter_c_diff = Ciphertexts_bytes + 32 - 1 then
						state_dec_wrap <= HASH_SESSION_END;
					end if;

					if sha_ack_new_input = '1' then
						counter_c_diff    <= counter_c_diff + 1;
						c_diff_bram_valid <= '1';
					else
						c_diff_bram_valid <= '0';
						if c_diff_bram_valid = '1' and sha_ack_new_input = '0' then
							counter_c_diff <= counter_c_diff - 1;
						end if;

					end if;

				when HASH_SESSION_END =>
					c_diff_bram_valid <= '0';
					if sha_finished = '1' then
						state_dec_wrap       <= DONE_STATE;
						sha_re_encap_session <= '0';
						sha_out_read_en      <= '1';
						sha_out_address      <= 0;
					end if;
				when DONE_STATE =>
					if sha_out_address = 3 then
						done           <= '1';
						state_dec_wrap <= KEY_READY;
					end if;
					sha_out_address <= sha_out_address + 1;
					k_out_valid     <= '1';
			end case;
		end if;
	end process decap_wrapper_process;

	secret_input_address <= std_logic_vector(to_unsigned(counter, SecretKey_length_bits)) when state_dec_wrap = LOAD_NEW_SECRET_KEY_DECODE_START --
	                        or state_dec_wrap = LOAD_NEW_SECRET_KEY --
	                        or state_dec_wrap = LOAD_RHO --
	                        or state_dec_wrap = LOAD_PK_CACHE --
	                        or state_dec_wrap = LOAD_NEW_KEY_PK --
	                        or state_dec_wrap = LOAD_NEW_KEY_PK_2 --
	                        else (others => '0');

	secret_key_fifo_input        <= secret_key_in;
	secret_key_fifo_write_enable <= secret_key_valid when (state_dec_wrap = LOAD_NEW_SECRET_KEY or state_dec_wrap = LOAD_NEW_SECRET_KEY_DECODE_START or (decode_Rq_start = '1' and state_dec_wrap = LOAD_NEW_KEY_PK)) and secret_key_fifo_full_next = '0' else '0';

	decode_Zx_input <= secret_key_fifo_output;

	FSM_decode_Zx : process(clock, reset) is
	begin
		if reset = '1' then
			state_Zx              <= IDLE_ZX;
			decode_Zx_input_valid <= '0';
		elsif rising_edge(clock) then
			case state_Zx is
				when IDLE_ZX =>
					if state_dec_wrap = LOAD_NEW_SECRET_KEY then
						state_Zx <= DECODE_F;
					end if;
					small_bytes_counter   <= 0;
					decode_Zx_input_valid <= '0';
				when DECODE_F =>
					if decode_Zx_output_valid = '1' then
						small_bytes_counter <= small_bytes_counter + 1;
					end if;
					decode_Zx_input_valid <= '1';

					if decode_Zx_done = '1' then
						state_Zx              <= DECODE_GINV;
						decode_Zx_input_valid <= '0';
						small_bytes_counter   <= 0;
					end if;
				when DECODE_GINV =>
					if decode_Zx_output_valid = '1' then
						small_bytes_counter <= small_bytes_counter + 1;
					end if;
					decode_Zx_input_valid <= '1';
					if decode_Zx_done = '1' then
						decode_Zx_input_valid <= '0';
						state_Zx              <= IDLE_ZX;
					end if;
			end case;
		end if;
	end process FSM_decode_Zx;

	FSM_process_decode_cipher : process(clock, reset) is
	begin
		if reset = '1' then
			state_Rq_cipher     <= IDLE;
			bram_c_diff_write_a <= '0';
			decode_cipher_start <= '0';
		--key_decap_start     <= '0';
		elsif rising_edge(clock) then
			case state_Rq_cipher is
				when IDLE =>
					decode_rounded_true <= '0';

					if (state_dec_wrap = KEY_READY and start_decap = '1' and (key_new = '0' or seperate_cipher_decode)) or (state_dec_wrap = IDLE and start_decap = '1' and key_new = '1' and seperate_cipher_decode) then
						decode_cipher_start <= '1';
						decode_rounded_true <= '1';

						state_Rq_cipher <= LOAD_CIPHER;
					end if;

					counter_decode <= 0;
				--key_decap_start <= '0';
				when LOAD_CIPHER =>
					bram_c_diff_write_a <= '1';
					decode_cipher_start <= '0';

					if decode_cipher_done = '1' then
						bram_c_diff_write_a <= '0';
						state_Rq_cipher     <= LOAD_CIPHER_HASH;
					end if;

					counter_c_hash <= Ciphertexts_bytes;

					if decode_cipher_output_valid = '1' then
						counter_decode <= counter_decode + 1;
					end if;
				when LOAD_CIPHER_HASH =>
					bram_c_diff_write_a <= '1';

					counter_c_hash <= counter_c_hash + 1;

					if counter_c_hash = Ciphertexts_bytes + 32 - 1 then
						state_Rq_cipher <= LOAD_CIPHER_DONE;
						--key_decap_start <= '1';
					end if;
				when LOAD_CIPHER_DONE =>
					if state_dec_wrap = LOAD_CIPHER_WAIT then
						state_Rq_cipher <= IDLE;
					end if;
					bram_c_diff_write_a <= '0';
					--key_decap_start     <= '0';
			end case;
		end if;
	end process FSM_process_decode_cipher;

	secret_key_fifo_read_enable <= decode_Zx_input_ack;

	decode_Rq_input       <= secret_key_in when state_dec_wrap = LOAD_NEW_KEY_PK or state_dec_wrap = LOAD_NEW_KEY_PK_2 else cipher_input;
	decode_Rq_input_valid <= secret_key_valid when state_dec_wrap = LOAD_NEW_KEY_PK or state_dec_wrap = LOAD_NEW_KEY_PK_2 else '0';

	cipher_input_address <= decode_cipher_input_read_address when state_Rq_cipher = LOAD_CIPHER else std_logic_vector(to_unsigned(counter_c_hash, Cipher_bytes_bits));

	cipher_input_address_pipe <= decode_cipher_input_read_address when rising_edge(clock);

	--bram_pk_address_a <= std_logic_vector(to_unsigned(counter, p_num_bits));
	bram_pk_data_in_a <= std_logic_vector(signed(decode_Rq_output) - q12);
	--bram_pk_write_a   <= decode_Rq_output_valid when state_dec_wrap = LOAD_NEW_KEY_PK else '0';

	bram_f_address_a       <= std_logic_vector(to_unsigned(small_bytes_counter, p_num_bits)) when state_Zx = DECODE_F else key_decap_f_address_a;
	bram_f_data_in_a       <= decode_Zx_output;
	bram_f_write_a         <= decode_Zx_output_valid when state_Zx = DECODE_F else '0';
	key_decap_f_data_out_a <= bram_f_data_out_a;

	bram_f_address_b       <= key_decap_f_address_b;
	key_decap_f_data_out_b <= bram_f_data_out_b;

	bram_ginv_address_a       <= std_logic_vector(to_unsigned(small_bytes_counter, p_num_bits)) when state_Zx = DECODE_GINV else key_decap_ginv_address_a;
	bram_ginv_data_in_a       <= decode_Zx_output;
	bram_ginv_write_a         <= decode_Zx_output_valid when state_Zx = DECODE_GINV else '0';
	key_decap_ginv_data_out_a <= bram_ginv_data_out_a;

	bram_ginv_address_b       <= key_decap_ginv_address_b;
	key_decap_ginv_data_out_b <= bram_ginv_data_out_b;

	bram_c_address_a       <= std_logic_vector(to_unsigned(counter_decode, p_num_bits)) when state_Rq_cipher = LOAD_CIPHER
	                          else key_decap_c_address_a when state_dec_wrap = DECAP_CORE_WAIT or state_dec_wrap = DECAP_CORE_RQ or state_dec_wrap = DECAP_CORE_RQ
	                          else from_encode_Rq.read_address;
	bram_c_data_in_a       <= std_logic_vector(resize(signed(decode_cipher_output) * 3 - q12, q_num_bits));
	bram_c_write_a         <= decode_cipher_output_valid when state_Rq_cipher = LOAD_CIPHER_DONE or state_Rq_cipher = LOAD_CIPHER else '0';
	key_decap_c_data_out_a <= bram_c_data_out_a;

	counter_pipe <= counter when rising_edge(clock);

	bram_c_address_b <= key_decap_c_address_b when state_dec_wrap = DECAP_CORE_WAIT or state_dec_wrap = DECAP_CORE_RQ or state_dec_wrap = DECAP_CORE_RQ
	                    else std_logic_vector(to_unsigned(counter_pipe, p_num_bits)) when state_dec_wrap = REENCAP
	                    else from_encode_Rq.read_address;

	key_encap_c_encrypt_valid_pipe <= key_encap_c_encrypt_valid when rising_edge(clock);
	bram_c_write_b                 <= key_encap_c_encrypt_valid_pipe when state_dec_wrap = REENCAP else '0';
	bram_c_data_in_b               <= key_encap_c_encrypt when rising_edge(clock);

	key_decap_c_data_out_b <= bram_c_data_out_b;

	key_encap_new_public_key   <= key_new;
	key_encap_public_key_in    <= bram_pk_data_in_a;
	key_encap_public_key_valid <= decode_Rq_output_valid when state_dec_wrap = LOAD_NEW_KEY_PK or state_dec_wrap = LOAD_NEW_KEY_PK_2 else '0';

	key_encap_small_weights_out   <= key_decap_r_output;
	key_encap_small_weights_valid <= key_decap_r_output_valid;
	key_encap_small_weights_done  <= key_decap_done;

	bram_rho_address_a    <= std_logic_vector(to_unsigned(counter - Small_bytes * 2 - PublicKeys_bytes - 1, Small_bytes_bits)) when state_dec_wrap /= MASK_R_ENC else std_logic_vector(to_unsigned(counter, Small_bytes_bits));
	bram_rho_data_in_a    <= secret_key_in;
	bram_rho_write_a_pipe <= secret_key_valid when state_dec_wrap = LOAD_RHO else '0';

	bram_rho_write_a <= bram_rho_write_a_pipe when rising_edge(clock);

	sha_pk_cache_in       <= secret_key_in;
	sha_pk_cache_in_valid <= secret_key_valid when state_dec_wrap = LOAD_PK_CACHE or (counter = Small_bytes - 1 and state_dec_wrap = LOAD_RHO) else '0'; -- TODO clean

	encode_Zx_input       <= key_encap_r_secret;
	encode_Zx_input_valid <= key_encap_r_secret_valid;

	masked_r_enc <= bram_r_enc_data_out_a XOR (differentbits(7 downto 0) AND (bram_r_enc_data_out_a XOR bram_rho_data_out_a));

	sha_r_encoded_in       <= masked_r_enc when state_dec_wrap = MASK_R_ENC else encode_Zx_output;
	sha_r_encoded_in_valid <= masked_r_enc_valid when state_dec_wrap = MASK_R_ENC else encode_Zx_output_valid;

	sha_c_encoded_in       <= bram_c_diff_data_out_a;
	sha_c_encoded_in_valid <= c_diff_bram_valid when sha_ack_new_input = '1' else '0';

	sha_diff_mask <= differentbits(7 downto 0);

	encode_Rq_m_input <= std_logic_vector(to_unsigned((q + 2) / 3, 16));
	encode_Rq_input   <= bram_c_data_out_a;

	bram_c_diff_address_a <= cipher_input_address_pipe when state_Rq_cipher = LOAD_CIPHER
	                         else std_logic_vector(to_unsigned(counter_c_diff - 1, Cipher_bytes_bits)) when (sha_ack_new_input = '0' and state_dec_wrap = HASH_SESSION)
	                         else std_logic_vector(to_unsigned(counter_c_hash - 1, Cipher_bytes_bits)) when state_Rq_cipher = LOAD_CIPHER_HASH or state_Rq_cipher = LOAD_CIPHER_DONE
	                         else std_logic_vector(to_unsigned(counter_c_diff, Cipher_bytes_bits)) when encode_Rq_output_valid = '0' --
	                         else std_logic_vector(to_unsigned(counter_c_diff + 1, Cipher_bytes_bits));

	bram_c_diff_data_in_a <= cipher_input;
	--bram_c_diff_write_a   <= cipher_input_valid when (state_dec_wrap = LOAD_CIPHER) or state_dec_wrap = LOAD_CIPHER_HASH else '0';

	bram_r_enc_address_a <= std_logic_vector(to_unsigned(counter, Small_bytes_bits));
	bram_r_enc_data_in_a <= encode_Zx_output;
	bram_r_enc_write_a   <= encode_Zx_output_valid when state_dec_wrap = DECAP_CORE_WAIT else '0';

	k_hash_out(63 downto 0) <= sha_out;

	key_decapsulation_inst : entity work.key_decapsulation
		port map(
			clock                => clock,
			reset                => reset,
			start                => key_decap_start,
			done                 => key_decap_done,
			output               => key_decap_r_output,
			output_valid         => key_decap_r_output_valid,
			key_ready            => key_decap_key_ready,
			bram_ginv_address_a  => key_decap_ginv_address_a,
			bram_ginv_data_out_a => key_decap_ginv_data_out_a,
			bram_ginv_address_b  => key_decap_ginv_address_b,
			bram_ginv_data_out_b => key_decap_ginv_data_out_b,
			f_address_a          => key_decap_f_address_a,
			f_data_out_a         => key_decap_f_data_out_a,
			f_address_b          => key_decap_f_address_b,
			f_data_out_b         => key_decap_f_data_out_b,
			c_address_a          => key_decap_c_address_a,
			c_data_out_a         => key_decap_c_data_out_a,
			c_address_b          => key_decap_c_address_b,
			c_data_out_b         => key_decap_c_data_out_b,
			to_rq_mult           => key_decap_to_rq_mult,
			from_rq_mult         => key_decap_from_rq_mult,
			to_freeze_round      => to_freeze_round,
			from_freeze_round    => from_freeze_round
		);

	to_encap_core.start_encap      <= key_encap_start_encap;
	to_encap_core.new_public_key   <= key_encap_new_public_key;
	to_encap_core.public_key_in    <= key_encap_public_key_in;
	to_encap_core.public_key_valid <= key_encap_public_key_valid;

	to_encap_core.small_weights_out   <= key_encap_small_weights_out;
	to_encap_core.small_weights_valid <= key_encap_small_weights_valid;
	to_encap_core.small_weights_done  <= key_encap_small_weights_done;

	key_encap_ready <= from_encap_core.ready;
	key_encap_done  <= from_encap_core.done;

	key_encap_public_key_ready    <= from_encap_core.public_key_ready;
	key_encap_c_encrypt           <= from_encap_core.c_encrypt;
	key_encap_c_encrypt_valid     <= from_encap_core.c_encrypt_valid;
	key_encap_r_secret            <= from_encap_core.r_secret;
	key_encap_r_secret_valid      <= from_encap_core.r_secret_valid;
	key_encap_small_weights_start <= from_encap_core.small_weights_start;

	reencap_true <= '1' when state_dec_wrap = REENCAP or (state_dec_wrap = DECAP_CORE_WAIT and key_decap_done = '1') or (state_dec_wrap = DECAP_CORE_WAIT and counter_pipe /= 0) else '0';

	to_rq_mult             <= key_decap_to_rq_mult;
	key_decap_from_rq_mult <= from_rq_mult;

	rq_mult_done <= from_rq_mult.done;

	sha_record_in.new_public_key        <= '0';
	sha_record_in.public_key_in         <= (others => '0');
	sha_record_in.public_key_ready      <= '0';
	sha_record_in.new_pk_cache          <= sha_new_pk_cache;
	sha_record_in.pk_cache_in           <= sha_pk_cache_in;
	sha_record_in.pk_cache_in_valid     <= sha_pk_cache_in_valid when rising_edge(clock);
	sha_record_in.start_confirm         <= sha_start_confirm;
	sha_record_in.r_encoded_in          <= sha_r_encoded_in;
	sha_record_in.r_encoded_in_valid    <= sha_r_encoded_in_valid;
	sha_record_in.start_session         <= sha_start_session;
	sha_record_in.re_encap_session      <= sha_re_encap_session;
	sha_record_in.diff_mask             <= sha_diff_mask;
	sha_record_in.c_encoded_in          <= sha_c_encoded_in;
	sha_record_in.c_encoded_in_valid    <= sha_c_encoded_in_valid;
	sha_record_in.decode_Rq_input_ack   <= decode_Rq_input_ack;
	sha_record_in.decode_Rq_input_valid <= decode_Rq_input_valid;
	sha_record_in.hash_out_address      <= std_logic_vector(to_unsigned(sha_out_address, 2));
	sha_record_in.hash_out_read_en      <= sha_out_read_en;
	sha_record_in.hash_out_read_pub_key <= '0';
	sha_record_in.hash_out_read_confirm <= '1' when state_dec_wrap /= HASH_SESSION_END and state_dec_wrap /= DONE_STATE else '0';

	sha_finished      <= sha_record_out.hash_finished;
	sha_ack_new_input <= sha_record_out.hash_ack_new_input;
	sha_out           <= sha_record_out.hash_out;

	to_sha         <= sha_record_in;
	sha_record_out <= from_sha;

	decode_cipher_input <= cipher_input;

	decode_cipher_input_valid <= '0';

	to_decode_Rq.input          <= decode_Rq_input;
	to_decode_Rq.input_valid    <= decode_Rq_input_valid;
	to_decode_Rq.rounded_decode <= decode_rounded_true;

	decode_Rq_input_ack    <= from_decode_Rq.input_ack;
	decode_Rq_output       <= from_decode_Rq.output;
	decode_Rq_output_valid <= from_decode_Rq.output_valid;
	decode_Rq_done         <= from_decode_Rq.done;
	decode_Rq_read_address <= from_decode_Rq.read_address;

	to_decode_Rq.write_address <= std_logic_vector(to_unsigned(counter - 2 * Small_bytes, SecretKey_length_bits)) when rising_edge(clock);

	decode_R3_inst : entity work.decode_R3
		port map(
			clock        => clock,
			reset        => reset,
			input        => decode_Zx_input,
			input_valid  => decode_Zx_input_valid,
			input_ack    => decode_Zx_input_ack,
			output       => decode_Zx_output,
			output_valid => decode_Zx_output_valid,
			done         => decode_Zx_done
		);

	to_encode_Rq.input       <= encode_Rq_input;
	to_encode_Rq.input_valid <= encode_Rq_input_valid;
	to_encode_Rq.m_input     <= encode_Rq_m_input;
	to_encode_Rq.start       <= encode_Rq_start;

	encode_Rq_input_ack    <= from_encode_Rq.input_ack;
	encode_Rq_output       <= from_encode_Rq.output;
	encode_Rq_output_valid <= from_encode_Rq.output_valid;
	encode_Rq_done         <= from_encode_Rq.done;

	encode_R3_inst : entity work.encode_R3
		port map(
			clock        => clock,
			reset        => reset,
			input        => encode_Zx_input,
			input_valid  => encode_Zx_input_valid,
			output       => encode_Zx_output,
			output_valid => encode_Zx_output_valid,
			done         => encode_Zx_done
		);

	bram_f_write_b <= '0';

	gen_cipher_decoder : if seperate_cipher_decode generate
		decode_ciphertext_inst : entity work.decode_ciphertext
			port map(
				clock               => clock,
				reset               => reset,
				start               => decode_cipher_start,
				input               => decode_cipher_input,
				input_read_address  => decode_cipher_input_read_address,
				input_write_address => (others => '0'),
				input_valid         => decode_cipher_input_valid,
				input_ack           => decode_cipher_input_ack,
				output              => decode_cipher_output,
				output_valid        => decode_cipher_output_valid,
				done                => decode_cipher_done
			);

		to_decode_Rq.start <= decode_Rq_start;
	end generate gen_cipher_decoder;

	gen_shared_cipher_decode : if seperate_cipher_decode = false generate
		decode_cipher_input_ack          <= from_decode_Rq.input_ack;
		decode_cipher_output             <= from_decode_Rq.output;
		decode_cipher_output_valid       <= from_decode_Rq.output_valid;
		decode_cipher_done               <= from_decode_Rq.done;
		decode_cipher_input_read_address <= from_decode_Rq.read_address;

		to_decode_Rq.start <= decode_Rq_start or decode_cipher_start;
	end generate gen_shared_cipher_decode;

	block_ram_inst_f : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => p_num_bits,
			DATA_WIDTH    => 2
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

	bram_ginv_write_b <= '0';

	block_ram_inst_ginv : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => p_num_bits,
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
	block_ram_inst_c : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => p_num_bits,
			DATA_WIDTH    => q_num_bits
		)
		port map(
			clock      => clock,
			address_a  => bram_c_address_a,
			write_a    => bram_c_write_a,
			data_in_a  => bram_c_data_in_a,
			data_out_a => bram_c_data_out_a,
			address_b  => bram_c_address_b,
			write_b    => bram_c_write_b,
			data_in_b  => bram_c_data_in_b,
			data_out_b => bram_c_data_out_b
		);

	block_ram_inst_rand_reject : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => Small_bytes_bits,
			DATA_WIDTH    => 8,
			DUAL_PORT     => FALSE
		)
		port map(
			clock      => clock,
			address_a  => bram_rho_address_a,
			write_a    => bram_rho_write_a,
			data_in_a  => bram_rho_data_in_a,
			data_out_a => bram_rho_data_out_a,
			address_b  => (others => '0'),
			write_b    => '0',
			data_in_b  => (others => '0'),
			data_out_b => open
		);

	block_ram_inst_c_diff : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => Cipher_bytes_bits,
			DATA_WIDTH    => 8,
			DUAL_PORT     => FALSE
		)
		port map(
			clock      => clock,
			address_a  => bram_c_diff_address_a,
			write_a    => bram_c_diff_write_a,
			data_in_a  => bram_c_diff_data_in_a,
			data_out_a => bram_c_diff_data_out_a,
			address_b  => (others => '0'),
			write_b    => '0',
			data_in_b  => (others => '0'),
			data_out_b => open
		);

	block_ram_inst_r_enc : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => Small_bytes_bits,
			DATA_WIDTH    => 8,
			DUAL_PORT     => FALSE
		)
		port map(
			clock      => clock,
			address_a  => bram_r_enc_address_a,
			write_a    => bram_r_enc_write_a,
			data_in_a  => bram_r_enc_data_in_a,
			data_out_a => bram_r_enc_data_out_a,
			address_b  => (others => '0'),
			write_b    => '0',
			data_in_b  => (others => '0'),
			data_out_b => open
		);

	FIFO_buffer_inst : entity work.FIFO_buffer
		generic map(
			RAM_WIDTH => 8,
			RAM_DEPTH => 382
		)
		port map(
			clock      => clock,
			reset      => reset,
			wr_en      => secret_key_fifo_write_enable,
			wr_data    => secret_key_fifo_input,
			rd_en      => secret_key_fifo_read_enable,
			rd_valid   => secret_key_fifo_output_valid,
			rd_data    => secret_key_fifo_output,
			empty      => secret_key_fifo_empty,
			empty_next => secret_key_fifo_empty_next,
			full       => secret_key_fifo_full,
			full_next  => secret_key_fifo_full_next
		);

end architecture RTL;
