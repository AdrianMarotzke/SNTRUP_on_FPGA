library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use work.constants.all;

entity tb_ntru_prime_top is
end entity tb_ntru_prime_top;

architecture RTL of tb_ntru_prime_top is
	signal clock : std_logic := '0';
	signal reset : std_logic := '0';
	signal ready : std_logic;
	signal done  : std_logic;

	signal public_key_in       : std_logic_vector(7 downto 0);
	signal public_key_in_valid : std_logic;
	signal public_key_in_ack   : std_logic;
	signal set_new_public_key  : std_logic;
	signal public_key_is_set   : std_logic;
	signal random_enable       : std_logic;
	signal random_output       : std_logic_vector(31 downto 0);
	signal start_encap         : std_logic;
	signal cipher_output       : std_logic_vector(7 downto 0);
	signal output_tb           : std_logic_vector(7 downto 0);
	signal cipher_output_valid : std_logic;
	signal k_hash_out          : std_logic_vector(63 downto 0);
	--signal k_hash_out          : std_logic_vector(127 downto 0);
	signal k_hash_out_tb       : std_logic_vector(255 downto 0);
	signal k_out_valid         : std_logic;

	signal start_key_gen        : std_logic;
	signal start_decap          : std_logic;
	signal set_new_private_key  : std_logic;
	signal private_key_in       : std_logic_vector(7 downto 0);
	signal private_key_in_valid : std_logic;
	signal private_key_in_ack   : std_logic;

	type mem_type is array (0 to 1024 * 4) of std_logic_vector(7 downto 0);
	signal cipher_ram           : mem_type;
	signal cipher_input_address : std_logic_vector(Cipher_bytes_bits - 1 downto 0);

	signal cipher_input       : std_logic_vector(7 downto 0);
	signal cipher_input_valid : std_logic;
	signal cipher_input_ack   : std_logic;
	signal private_key_is_set : std_logic;

	signal private_key_out       : std_logic_vector(7 downto 0);
	signal private_key_out_valid : std_logic;

	signal private_key_ram           : mem_type;
	signal private_key_input_address : std_logic_vector(SecretKey_length_bits - 1 downto 0);

	signal public_key_out       : std_logic_vector(7 downto 0);
	signal public_key_out_valid : std_logic;

	signal public_key_ram           : mem_type;
	signal public_key_input_address : std_logic_vector(Cipher_bytes_bits - 1 downto 0);

	signal private_key_out_tb : std_logic_vector(7 downto 0);

	function to_std_logic_vector(a : string) return std_logic_vector is
		variable ret : std_logic_vector(a'length * 4 - 1 downto 0);
	begin
		for i in a'range loop
			case a(i) is
				when '0'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "0000";
				when '1'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "0001";
				when '2'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "0010";
				when '3'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "0011";
				when '4'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "0100";
				when '5'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "0101";
				when '6'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "0110";
				when '7'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "0111";
				when '8'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "1000";
				when '9'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "1001";
				when 'A'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "1010";
				when 'B'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "1011";
				when 'C'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "1100";
				when 'D'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "1101";
				when 'E'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "1110";
				when 'F'    => ret((a'length - i) * 4 + 3 downto (a'length - i) * 4) := "1111";
				when others => null;
			end case;

		end loop;
		return ret;
	end function to_std_logic_vector;

	signal kat_num : integer := 0;

	constant param_set : string(1 to 3) := integer'image(p);

	procedure encap_test(signal set_new_public_key : out std_logic; signal start_encap : out std_logic) is
	begin
		wait for 200 ns;
		wait until rising_edge(clock);
		wait for 1 ns;
		set_new_public_key <= '1';
		start_encap        <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		set_new_public_key <= '0';
		start_encap        <= '0';
		wait until rising_edge(clock) and done = '1';
		--wait for 7000 ns;
		wait until rising_edge(clock) and public_key_is_set = '1' and ready = '1';

		wait for 1 ns;
		set_new_public_key <= '1';
		start_encap        <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		set_new_public_key <= '0';
		start_encap        <= '0';
		wait until rising_edge(clock) and done = '1';
		--wait for 1000 ns;
		wait until rising_edge(clock) and public_key_is_set = '1' and ready = '1';

		wait for 1 ns;
		set_new_public_key <= '1';
		start_encap        <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		set_new_public_key <= '0';
		start_encap        <= '0';
		wait until rising_edge(clock) and done = '1';
		wait for 1000 ns;
		wait until rising_edge(clock) and public_key_is_set = '1' and ready = '1';

		wait for 1 ns;
		set_new_public_key <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		set_new_public_key <= '0';
		wait until rising_edge(clock) and public_key_is_set = '1' and ready = '1';

		wait for 1 ns;
		start_encap <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		start_encap <= '0';
		wait until rising_edge(clock) and done = '1';
		wait for 1000 ns;
		wait until rising_edge(clock) and public_key_is_set = '1' and ready = '1';
	end procedure encap_test;

	procedure decap_test(signal set_new_private_key : out std_logic; signal start_decap : out std_logic) is
	begin
		wait for 200 ns;
		wait until rising_edge(clock);
		wait for 1 ns;
		set_new_private_key <= '1';
		start_decap         <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		set_new_private_key <= '0';
		start_decap         <= '0';

		wait until rising_edge(clock) and ready = '1' and private_key_is_set = '1';
		wait for 1 ns;
		start_decap <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		start_decap <= '0';
		wait until rising_edge(clock) and done = '1';

		wait for 1 ns;
		start_decap <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		start_decap <= '0';
		wait until rising_edge(clock) and done = '1';
		wait for 1 ns;

		start_decap         <= '0';
		set_new_private_key <= '0';
		wait for 200 ns;
		wait until rising_edge(clock);
		wait for 1 ns;
		set_new_private_key <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		set_new_private_key <= '0';
		wait until rising_edge(clock) and ready = '1' and private_key_is_set = '1';

		wait for 1 ns;
		start_decap <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		start_decap <= '0';
		wait until rising_edge(clock) and done = '1';
		wait for 1 ns;
		start_decap <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		start_decap <= '0';
		wait until rising_edge(clock) and done = '1';
		wait for 1 ns;
	end procedure decap_test;

	procedure keygen_test(signal start_key_gen : out std_logic) is

	begin
		wait for 200 ns;
		wait until rising_edge(clock);
		wait for 1 ns;
		start_key_gen <= '1';
		wait until rising_edge(clock);
		wait for 1 ns;
		start_key_gen <= '0';
		wait until rising_edge(clock) and done = '1';
	end procedure keygen_test;

	signal counter  : integer;
	signal counter2 : integer;

	signal start_key_gen_tb       : std_logic;
	signal start_encap_tb         : std_logic;
	signal start_decap_tb         : std_logic;
	signal set_new_public_key_tb  : std_logic;
	signal public_key_in_tb       : std_logic_vector(7 downto 0);
	signal set_new_private_key_tb : std_logic;
	signal private_key_in_tb      : std_logic_vector(7 downto 0);
	signal cipher_input_tb        : std_logic_vector(7 downto 0);
	signal random_output_tb       : std_logic_vector(31 downto 0);

begin
	ntru_prime_top_inst : entity work.ntru_prime_top
		port map(
			clock                    => clock,
			reset                    => reset,
			ready                    => ready,
			done                     => done,
			start_key_gen            => start_key_gen_tb,
			start_encap              => start_encap_tb,
			start_decap              => start_decap_tb,
			set_new_public_key       => set_new_public_key_tb,
			public_key_in            => public_key_in_tb,
			public_key_input_address => public_key_input_address,
			public_key_is_set        => public_key_is_set,
			set_new_private_key      => set_new_private_key_tb,
			private_key_in           => private_key_in_tb,
			private_key_in_address   => private_key_input_address,
			private_key_is_set       => private_key_is_set,
			cipher_output            => cipher_output,
			cipher_output_valid      => cipher_output_valid,
			cipher_input             => cipher_input_tb,
			cipher_input_address     => cipher_input_address,
			k_hash_out               => k_hash_out,
			k_out_valid              => k_out_valid,
			private_key_out          => private_key_out,
			private_key_out_valid    => private_key_out_valid,
			public_key_out           => public_key_out,
			public_key_out_valid     => public_key_out_valid,
			random_enable            => random_enable,
			random_output            => random_output_tb
		);

	start_key_gen_tb       <= start_key_gen after 0.5 ns;
	start_encap_tb         <= start_encap after 0.5 ns;
	start_decap_tb         <= start_decap after 0.5 ns;
	set_new_public_key_tb  <= set_new_public_key after 0.5 ns;
	public_key_in_tb       <= public_key_in after 0.5 ns;
	set_new_private_key_tb <= set_new_private_key after 0.5 ns;
	private_key_in_tb      <= private_key_in after 0.5 ns;
	cipher_input_tb        <= cipher_input after 0.5 ns;
	random_output_tb       <= random_output after 0.5 ns;

	clock_gen : process is
	begin
		clock <= not clock;
		wait for 2 ns;
	end process clock_gen;

	reset_gen : process is
	begin
		reset <= '1';
		wait for 110 ns;
		wait until rising_edge(clock);
		wait for 1 ns;
		reset <= '0';
		wait;
	end process reset_gen;

	enable_gen : process is
	begin
		start_encap         <= '0';
		set_new_public_key  <= '0';
		start_decap         <= '0';
		set_new_private_key <= '0';
		start_key_gen       <= '0';

		wait for 50 us;

		--		if kat_num mod 6 = 0 then
		--			encap_test(set_new_public_key, start_encap);
		--			--keygen_test(start_key_gen);
		--			decap_test(set_new_private_key, start_decap);
		--		elsif kat_num mod 6 = 1 then
		--			keygen_test(start_key_gen);
		--			encap_test(set_new_public_key, start_encap);
		--			decap_test(set_new_private_key, start_decap);
		--		elsif kat_num mod 6 = 2 then
		encap_test(set_new_public_key, start_encap);
		decap_test(set_new_private_key, start_decap);
		keygen_test(start_key_gen);
		--		elsif kat_num mod 6 = 3 then
		--			keygen_test(start_key_gen);
		--			decap_test(set_new_private_key, start_decap);
		--			encap_test(set_new_public_key, start_encap);
		--		elsif kat_num mod 6 = 4 then
		--			decap_test(set_new_private_key, start_decap);
		--			keygen_test(start_key_gen);
		--			encap_test(set_new_public_key, start_encap);
		--		else
		--			decap_test(set_new_private_key, start_decap);
		--			encap_test(set_new_public_key, start_encap);
		--			keygen_test(start_key_gen);
		--		end if;

		if kat_num < 50 then
			kat_num <= kat_num + 1;
		else
			wait;
		end if;

		--wait;
	end process enable_gen;

	stimulus_pk : process is
		file read_file    : text;
		variable line_v   : line;
		variable temp8bit : string(1 to 2);

	begin
		public_key_in_valid <= '0';
		wait until set_new_public_key = '1';
		wait for 1 ns;

		file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/pk_tb", read_mode);

		for i in 0 to kat_num loop
			readline(read_file, line_v);
		end loop;

		for i in 0 to PublicKeys_bytes - 1 loop
			read(line_v, temp8bit);
			public_key_ram(i) <= to_std_logic_vector(temp8bit);
		end loop;

		public_key_in_valid <= '0';
		file_close(read_file);

	end process stimulus_pk;

	public_key_in <= public_key_ram(to_integer(unsigned(public_key_input_address))) when rising_edge(clock);

	stimulus_rand_32bit : process is
		file read_file    : text;
		variable line_v   : line;
		variable temp8bit : string(1 to 8);

		variable counter_v : integer := 0;

		variable counter_cache : integer := 0;

		variable line_v2 : line;
		file read_file2  : text;
	begin
		--wait until start_encap = '1' or start_key_gen = '1';
		if counter_cache >= 4 then
			file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/short_random_tb", read_mode);

			for i in 0 to kat_num loop
				readline(read_file, line_v);
			end loop;

			if BATCH_SIZE /= 0 then
				for y in 0 to BATCH_SIZE * 3 loop

					counter <= counter_v;

					if y <= BATCH_SIZE then

						if y = BATCH_SIZE then
							file_open(read_file2, "./tb_stimulus/KAT_" & param_set & "/inputs_random_tb", read_mode);

							for i in 0 to kat_num + 1 loop
								readline(read_file2, line_v);
							end loop;

							for i in 0 to p - 1 loop
								read(line_v, temp8bit);
								random_output <= to_std_logic_vector(temp8bit);
								wait until rising_edge(clock) and random_enable = '1';
								wait for 1 ns;
							end loop;

							file_close(read_file2);
						else
							for i in 0 to y - 1 loop
								if endfile(read_file) then
									file_close(read_file);
									file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/short_random_tb", read_mode);
								end if;

								readline(read_file, line_v);
							end loop;

							for i in 0 to p - 1 loop
								read(line_v, temp8bit);
								random_output <= to_std_logic_vector(temp8bit);
								wait until rising_edge(clock) and random_enable = '1';
								wait for 1 ns;
							end loop;
						end if;

						counter_v := counter_v + 1;

					elsif y >= BATCH_SIZE + 1 and y <= BATCH_SIZE * 2 then
						for i in BATCH_SIZE + 1 to y - 1 loop
							if endfile(read_file) then
								file_close(read_file);
								file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/short_random_tb", read_mode);
							end if;

							readline(read_file, line_v);
						end loop;

						for i in 0 to p - 1 loop
							read(line_v, temp8bit);
						end loop;

						for i in 0 to p - 1 loop
							read(line_v, temp8bit);
							random_output <= to_std_logic_vector(temp8bit);
							wait until rising_edge(clock) and random_enable = '1'; -- TODO fix testing when g is not invertable
							wait for 1 ns;
						end loop;

						counter_v := counter_v + 1;
					elsif y >= BATCH_SIZE * 2 + 1 and y <= BATCH_SIZE * 3 then
						for i in BATCH_SIZE * 2 + 1 to y - 1 loop
							if endfile(read_file) then
								file_close(read_file);
								file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/short_random_tb", read_mode);
							end if;

							readline(read_file, line_v);
						end loop;

						for i in 0 to p - 1 loop
							read(line_v, temp8bit);
						end loop;

						for i in 0 to p - 1 loop
							read(line_v, temp8bit);
						end loop;

						for i in 0 to (Small_bytes / 4) loop
							read(line_v, temp8bit);
							random_output <= to_std_logic_vector(temp8bit);
							wait until rising_edge(clock) and random_enable = '1';
							wait for 1 ns;
						end loop;

						counter_v := counter_v + 1;

					else
						wait until rising_edge(clock);
					end if;

					counter <= counter_v;

					file_close(read_file);
					file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/short_random_tb", read_mode);

					for i in 0 to kat_num loop
						readline(read_file, line_v);
					end loop;
				end loop;

				counter_v     := 0;
				counter       <= counter_v;
				counter_cache := 0;
			else
				if line_v'length > (p + p + Small_bytes / 4 + 1 + 50) * 8 then
					for i in 0 to p + p + p - 1 + Small_bytes / 4 + 1 loop
						read(line_v, temp8bit);
						random_output <= to_std_logic_vector(temp8bit);
						wait until rising_edge(clock) and random_enable = '1';
						wait for 1 ns;
					end loop;

				else

					for i in 0 to p - 1 loop
						read(line_v, temp8bit);
						random_output <= to_std_logic_vector(temp8bit);
						wait until rising_edge(clock) and random_enable = '1';
						wait for 1 ns;
					end loop;

					file_open(read_file2, "./tb_stimulus/KAT_" & param_set & "/inputs_random_tb", read_mode);

					for i in 0 to kat_num + 1 loop
						readline(read_file2, line_v2);
					end loop;

					for i in 0 to p - 1 loop
						read(line_v2, temp8bit);
						random_output <= to_std_logic_vector(temp8bit);
						wait until rising_edge(clock) and random_enable = '1';
						wait for 1 ns;
					end loop;

					file_close(read_file2);

					for i in 0 to p - 1 + Small_bytes / 4 + 1 loop
						read(line_v, temp8bit);
						random_output <= to_std_logic_vector(temp8bit);
						wait until rising_edge(clock) and random_enable = '1';
						wait for 1 ns;
					end loop;
				end if;

				counter_cache := 0;
			end if;

		elsif counter_cache <= 3 then
			file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/inputs_random_tb", read_mode);

			wait until random_enable = '1';

			for i in 0 to kat_num loop
				readline(read_file, line_v);
			end loop;

			for i in 0 to p - 1 loop
				read(line_v, temp8bit);
				random_output <= to_std_logic_vector(temp8bit);
				wait until rising_edge(clock) and random_enable = '1';
				wait for 1 ns;
			end loop;

			if (counter_cache = 2 and kat_num > 0) then
				counter_cache := counter_cache + 1;
			end if;

			counter_cache := counter_cache + 1;
		end if;

		file_close(read_file);
	end process stimulus_rand_32bit;

	check_encap_output : process is
		file read_file    : text;
		variable line_v   : line;
		variable temp8bit : string(1 to 2);
	begin
		file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/ct_tb", read_mode);

		wait until cipher_output_valid = '1';

		for i in 0 to kat_num loop
			readline(read_file, line_v);
		end loop;

		for i in 0 to ct_with_confirm_bytes - 1 loop
			read(line_v, temp8bit);
			output_tb <= to_std_logic_vector(temp8bit);
			wait until rising_edge(clock) and cipher_output_valid = '1';
			assert output_tb = cipher_output or (cipher_output_valid /= '1') report "Mismatch in encap output" severity failure;
		end loop;

		file_close(read_file);
		wait until rising_edge(clock);
	end process check_encap_output;

	check_sk_key_gen_output : process is
		file read_file    : text;
		variable line_v   : line;
		variable temp8bit : string(1 to 2);

		variable counter_b : integer := 0;

	begin
		file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/sk_tb", read_mode);

		wait until private_key_out_valid = '1';

		for i in 0 to kat_num loop
			readline(read_file, line_v);
		end loop;
		counter2 <= counter_b;

		if BATCH_SIZE /= 0 then
			for y in 0 to counter_b - 1 loop

				if endfile(read_file) then
					file_close(read_file);
					file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/sk_tb", read_mode);
				end if;

				readline(read_file, line_v);

			end loop;

			counter_b := counter_b + 1;
		end if;

		for i in 0 to SecretKey_bytes - 1 loop
			read(line_v, temp8bit);
			private_key_out_tb <= to_std_logic_vector(temp8bit);
			wait until rising_edge(clock) and (private_key_out_valid = '1' or public_key_out_valid = '1');
			assert private_key_out_tb = private_key_out or (private_key_out_valid /= '1') report "Mismatch in sk key_gen output" severity failure;
			assert private_key_out_tb = public_key_out or (public_key_out_valid /= '1') report "Mismatch in pk key_gen output" severity failure;

		end loop;

		wait until rising_edge(clock);

		file_close(read_file);

		if counter_b = BATCH_SIZE then
			counter_b := 0;
		end if;

	end process check_sk_key_gen_output;

	stimulus_sk : process is
		file read_file    : text;
		variable line_v   : line;
		variable temp8bit : string(1 to 2);
	begin
		file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/sk_tb", read_mode);

		private_key_in_valid <= '0';

		wait until set_new_private_key = '1';
		wait for 1 ns;

		for i in 0 to kat_num loop
			readline(read_file, line_v);
		end loop;

		for i in 0 to SecretKey_bytes - 1 loop
			read(line_v, temp8bit);
			private_key_ram(i) <= to_std_logic_vector(temp8bit);
		end loop;

		file_close(read_file);

	end process stimulus_sk;

	private_key_in <= private_key_ram(to_integer(unsigned(private_key_input_address))) when rising_edge(clock);

	stimulus_c : process is
		file read_file    : text;
		variable line_v   : line;
		variable temp8bit : string(1 to 2);

	begin
		file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/ct_tb", read_mode);

		cipher_input_valid <= '0';
		wait until start_decap = '1';
		wait for 1 ns;

		for i in 0 to kat_num loop
			readline(read_file, line_v);
		end loop;

		for i in 0 to ct_with_confirm_bytes - 1 loop
			read(line_v, temp8bit);
			cipher_ram(i) <= to_std_logic_vector(temp8bit);
		end loop;

		wait until rising_edge(clock) and done = '1';
		cipher_input_valid <= '0';
		file_close(read_file);
	end process stimulus_c;

	cipher_input <= cipher_ram(to_integer(unsigned(cipher_input_address))) when rising_edge(clock);

	check_hash_output : process is
		file read_file    : text;
		variable line_v   : line;
		variable temp8bit : string(1 to 64);
	begin
		file_open(read_file, "./tb_stimulus/KAT_" & param_set & "/hash_tb", read_mode);

		wait until k_out_valid = '1';

		for i in 0 to kat_num loop
			readline(read_file, line_v);
		end loop;

		read(line_v, temp8bit);
		k_hash_out_tb <= to_std_logic_vector(temp8bit);

		wait until rising_edge(clock) and k_out_valid = '1';

		assert k_hash_out_tb(255 downto 192) = k_hash_out report "Mismatch in k hash output 0" severity failure;

		wait until rising_edge(clock) and k_out_valid = '1';

		assert k_hash_out_tb(191 downto 128) = k_hash_out report "Mismatch in k hash output 1" severity failure;

		wait until rising_edge(clock) and k_out_valid = '1';

		assert k_hash_out_tb(127 downto 64) = k_hash_out report "Mismatch in k hash output 2" severity failure;

		wait until rising_edge(clock) and k_out_valid = '1';

		assert k_hash_out_tb(63 downto 0) = k_hash_out report "Mismatch in k hash output 3" severity failure;

		file_close(read_file);

		wait until rising_edge(clock);
	end process check_hash_output;

end architecture RTL;
