library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.constants.all;

entity sort_bram_radix is
	generic(
		WIDTH : natural := 32
	);
	port(
		clock               : in  std_logic;
		reset               : in  std_logic;
		start               : in  std_logic;
		done                : out std_logic;
		bram_address_a      : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_write_a_enable : out std_logic;
		bram_data_in_a      : out std_logic_vector(WIDTH - 1 downto 0);
		bram_data_out_a     : in  std_logic_vector(WIDTH - 1 downto 0);
		bram_address_b      : out std_logic_vector(p_num_bits - 1 downto 0);
		bram_write_b_enable : out std_logic;
		bram_data_in_b      : out std_logic_vector(WIDTH - 1 downto 0);
		bram_data_out_b     : in  std_logic_vector(WIDTH - 1 downto 0)
	);
end entity sort_bram_radix;

architecture RTL of sort_bram_radix is
	-- state variable to track main fsm, as well as wehter bram is currently being read or written
	type state_type is (reset_state, RESET_RAM, INIT, READ_BRAM_START, READ_BRAM, READ_BRAM_END, READ_BRAM_END_2, T_LOOP, T_LOOP_END, T_LOOP_END_2,
	                    C0_LOOP, C0_LOOP_END, C0_LOOP_END_2, C1_LOOP_BEGIN, C1_LOOP, C1_LOOP_END, C1_LOOP_END_2, C2_LOOP, C2_LOOP_END, C2_LOOP_END_2,
	                    C3_LOOP_BEGIN, C3_LOOP, C3_LOOP_END, C3_LOOP_END_2, final, done_state
	                   );
	signal state_sort : state_type;

	type c_address_type is array (3 downto 0) of std_logic_vector(7 downto 0);
	type c_data_type is array (3 downto 0) of std_logic_vector(15 downto 0);

	signal c_address_a  : c_address_type;
	signal c_data_out_a : c_data_type;

	signal c_address_b : c_address_type;
	signal c_data_in_b : c_data_type;
	signal c_write_b   : std_logic_vector(3 downto 0);

	signal counter : integer range 0 to p;

	signal u_var   : std_logic_vector(WIDTH - 1 downto 0);
	signal u_var_y : std_logic_vector(WIDTH - 1 downto 0);

	signal t_var        : c_data_type;
	signal y_address_a  : STD_LOGIC_VECTOR(p_num_bits - 1 downto 0);
	signal y_write_a    : STD_LOGIC;
	signal y_data_in_a  : STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
	signal y_data_out_a : STD_LOGIC_VECTOR(WIDTH - 1 downto 0);

begin

	process(clock, reset) is
	begin
		if reset = '1' then
			state_sort <= reset_state;

			done <= '0';

		elsif rising_edge(clock) then
			case state_sort is
				when reset_state =>
					counter             <= 0;
					c_write_b           <= (others => '1');
					state_sort          <= RESET_RAM;
					bram_write_b_enable <= '0';
				when RESET_RAM =>
					counter <= counter + 1;

					if counter = 255 then
						c_write_b  <= (others => '0');
						state_sort <= INIT;
					end if;

				when INIT =>

					done <= '0';

					counter   <= p - 1;
					c_write_b <= (others => '0');

					t_var <= (others => (others => '0'));

					if start = '1' then
						state_sort <= READ_BRAM_START;
					else
						state_sort <= INIT;
					end if;
					y_write_a <= '0';
				when READ_BRAM_START =>
					state_sort <= READ_BRAM;
					counter    <= counter - 1;
				when READ_BRAM =>
					counter <= counter - 1;

					c_write_b <= (others => '1');

					if counter = 0 then
						state_sort <= READ_BRAM_END;
						counter    <= 0;
					end if;
				when READ_BRAM_END =>
					state_sort <= READ_BRAM_END_2;
				when READ_BRAM_END_2 =>
					counter    <= counter + 1;
					c_write_b  <= (others => '0');
					state_sort <= T_LOOP;
				when T_LOOP =>

					counter <= counter + 1;

					for i in 0 to 3 loop
						t_var(i) <= std_logic_vector(unsigned(t_var(i)) + unsigned(c_data_out_a(i)));
					end loop;

					c_write_b <= (others => '1');

					if counter = 256 then
						state_sort <= T_LOOP_END;
					end if;
				when T_LOOP_END =>
					state_sort <= T_LOOP_END_2;
					counter    <= p - 1;
					c_write_b  <= (others => '0');
				when T_LOOP_END_2 =>
					state_sort <= C0_LOOP;
					counter    <= counter - 1;
				when C0_LOOP =>
					c_write_b(0) <= '1';
					counter      <= counter - 1;
					if counter = 0 then
						state_sort <= C0_LOOP_END;
						counter    <= p - 1;
					end if;
					y_write_a    <= '1';
				when C0_LOOP_END =>
					state_sort <= C0_LOOP_END_2;
				when C0_LOOP_END_2 =>
					state_sort <= C1_LOOP_BEGIN;
					c_write_b  <= (others => '0');
					y_write_a  <= '0';
				when C1_LOOP_BEGIN =>
					state_sort <= C1_LOOP;
					counter    <= counter - 1;

				when C1_LOOP =>
					c_write_b(1)        <= '1';
					counter             <= counter - 1;
					if counter = 0 then
						state_sort <= C1_LOOP_END;
						counter    <= p - 1;
					end if;
					bram_write_b_enable <= '1';
				when C1_LOOP_END =>
					state_sort <= C1_LOOP_END_2;
				when C1_LOOP_END_2 =>
					state_sort          <= C2_LOOP;
					c_write_b           <= (others => '0');
					bram_write_b_enable <= '0';
					counter             <= counter - 1;
				when C2_LOOP =>
					c_write_b(2) <= '1';
					counter      <= counter - 1;
					if counter = 0 then
						state_sort <= C2_LOOP_END;
						counter    <= p - 1;
					end if;
					y_write_a    <= '1';
				when C2_LOOP_END =>
					state_sort <= C2_LOOP_END_2;
				when C2_LOOP_END_2 =>
					state_sort <= C3_LOOP_BEGIN;
					c_write_b  <= (others => '0');
					y_write_a  <= '0';
				when C3_LOOP_BEGIN =>
					state_sort <= C3_LOOP;
					counter    <= counter - 1;
				when C3_LOOP =>
					c_write_b(3)        <= '1';
					counter             <= counter - 1;
					if counter = 0 then
						state_sort <= C3_LOOP_END;
						counter    <= p - 1;
					end if;
					bram_write_b_enable <= '1';
				when C3_LOOP_END =>
					state_sort <= C3_LOOP_END_2;
				when C3_LOOP_END_2 =>
					c_write_b           <= (others => '0');
					bram_write_b_enable <= '0';
					state_sort          <= final;
				when final =>
					state_sort <= done_state;
					done       <= '1';
				when done_state =>
					done                <= '0';
					c_write_b           <= (others => '1');
					state_sort          <= RESET_RAM;
					bram_write_b_enable <= '0';
					counter             <= 0;
			end case;

		end if;
	end process;

	generate_label : for i in 0 to 3 generate
		SDP_dist_RAM_inst : entity work.SDP_dist_RAM_write_first
			generic map(
				ADDRESS_WIDTH => 8,
				DATA_WIDTH    => 16
			)
			port map(
				clock      => clock,
				address_a  => c_address_a(i),
				data_out_a => c_data_out_a(i),
				address_b  => c_address_b(i),
				write_b    => c_write_b(i),
				data_in_b  => c_data_in_b(i)
			);

		c_data_in_b(i) <= (others => '0') when state_sort = RESET_RAM
		                  else std_logic_vector(unsigned(c_data_out_a(i)) + 1) when state_sort = READ_BRAM OR state_sort = READ_BRAM_END OR state_sort = READ_BRAM_END_2
		                  else t_var(i) when state_sort = T_LOOP OR state_sort = T_LOOP_END OR state_sort = T_LOOP_END_2
		                  else std_logic_vector(unsigned(c_data_out_a(i)) - 1) when state_sort = C0_LOOP OR state_sort = C0_LOOP_END OR state_sort = C0_LOOP_END_2
		                  else std_logic_vector(unsigned(c_data_out_a(i)) - 1) when state_sort = C1_LOOP OR state_sort = C1_LOOP_END OR state_sort = C1_LOOP_END_2 OR state_sort = C1_LOOP_BEGIN
		                  else std_logic_vector(unsigned(c_data_out_a(i)) - 1) when state_sort = C2_LOOP OR state_sort = C2_LOOP_END OR state_sort = C2_LOOP_END_2
		                  else std_logic_vector(unsigned(c_data_out_a(i)) - 1);

	end generate generate_label;

	c_address_b(0) <= std_logic_vector(to_unsigned(counter, 8)) when state_sort = RESET_RAM
	                  else u_var(7 downto 0) when state_sort = READ_BRAM OR state_sort = READ_BRAM_END OR state_sort = READ_BRAM_END_2
	                  else std_logic_vector(to_unsigned(counter - 2, 8)) when state_sort = T_LOOP OR state_sort = T_LOOP_END OR state_sort = T_LOOP_END_2
	                  else u_var(7 downto 0);

	c_address_b(1) <= std_logic_vector(to_unsigned(counter, 8)) when state_sort = RESET_RAM
	                  else u_var(15 downto 8) when state_sort = READ_BRAM OR state_sort = READ_BRAM_END OR state_sort = READ_BRAM_END_2
	                  else std_logic_vector(to_unsigned(counter - 2, 8)) when state_sort = T_LOOP OR state_sort = T_LOOP_END OR state_sort = T_LOOP_END_2
	                  else u_var_y(15 downto 8);

	c_address_b(2) <= std_logic_vector(to_unsigned(counter, 8)) when state_sort = RESET_RAM
	                  else u_var(23 downto 16) when state_sort = READ_BRAM OR state_sort = READ_BRAM_END OR state_sort = READ_BRAM_END_2
	                  else std_logic_vector(to_unsigned(counter - 2, 8)) when state_sort = T_LOOP OR state_sort = T_LOOP_END OR state_sort = T_LOOP_END_2
	                  else u_var(23 downto 16);

	c_address_b(3) <= std_logic_vector(to_unsigned(counter, 8)) when state_sort = RESET_RAM
	                  else u_var(31 downto 24) XOR "10000000" when state_sort = READ_BRAM OR state_sort = READ_BRAM_END OR state_sort = READ_BRAM_END_2
	                  else std_logic_vector(to_unsigned(counter - 2, 8)) when state_sort = T_LOOP OR state_sort = T_LOOP_END OR state_sort = T_LOOP_END_2
	                  else u_var_y(31 downto 24) XOR "10000000";

	c_address_a(0) <= bram_data_out_a(7 downto 0) when state_sort = READ_BRAM OR state_sort = READ_BRAM_END or state_sort = C0_LOOP OR state_sort = C0_LOOP_END else std_logic_vector(to_unsigned(counter, 8));
	c_address_a(1) <= bram_data_out_a(15 downto 8) when state_sort = READ_BRAM OR state_sort = READ_BRAM_END
	                  else std_logic_vector(to_unsigned(counter, 8)) when state_sort /= C1_LOOP AND state_sort /= C1_LOOP_END AND state_sort /= C1_LOOP_BEGIN
	                  else y_data_out_a(15 downto 8);
	c_address_a(2) <= bram_data_out_a(23 downto 16) when state_sort = READ_BRAM OR state_sort = READ_BRAM_END or state_sort = C2_LOOP OR state_sort = C2_LOOP_END else std_logic_vector(to_unsigned(counter, 8));
	c_address_a(3) <= bram_data_out_a(31 downto 24) XOR "10000000" when state_sort = READ_BRAM OR state_sort = READ_BRAM_END
	                  else std_logic_vector(to_unsigned(counter, 8)) when state_sort /= C3_LOOP AND state_sort /= C3_LOOP_END AND state_sort /= C3_LOOP_BEGIN
	                  else y_data_out_a(31 downto 24) XOR "10000000";

	u_var <= bram_data_out_a when rising_edge(clock);

	bram_address_a <= std_logic_vector(to_unsigned(counter, p_num_bits));

	y_address_a <= std_logic_vector(unsigned(c_data_out_a(0)(p_num_bits - 1 downto 0)) - 1) when state_sort = C0_LOOP OR state_sort = C0_LOOP_END OR state_sort = C0_LOOP_END_2
	               else std_logic_vector(to_unsigned(counter, p_num_bits)) when state_sort = C1_LOOP OR state_sort = C1_LOOP_END OR state_sort = C1_LOOP_END_2 OR state_sort = C1_LOOP_BEGIN
	               else std_logic_vector(unsigned(c_data_out_a(2)(p_num_bits - 1 downto 0)) - 1) when state_sort = C2_LOOP OR state_sort = C2_LOOP_END OR state_sort = C2_LOOP_END_2
	               else std_logic_vector(to_unsigned(counter, p_num_bits));

	y_data_in_a <= u_var;

	u_var_y <= y_data_out_a when rising_edge(clock);

	bram_address_b <= std_logic_vector(unsigned(c_data_out_a(1)(p_num_bits - 1 downto 0)) - 1) when state_sort = C1_LOOP OR state_sort = C1_LOOP_END OR state_sort = C1_LOOP_END_2 OR state_sort = C1_LOOP_BEGIN else std_logic_vector(unsigned(c_data_out_a(3)(p_num_bits - 1 downto 0)) - 1);
	bram_data_in_b <= u_var_y;

	block_ram_inst : entity work.block_ram
		generic map(
			ADDRESS_WIDTH => p_num_bits,
			DATA_WIDTH    => WIDTH,
			DUAL_PORT     => true
		)
		port map(
			clock      => clock,
			address_a  => y_address_a,
			write_a    => y_write_a,
			data_in_a  => y_data_in_a,
			data_out_a => y_data_out_a,
			address_b  => (others => '0'),
			write_b    => '0',
			data_in_b  => (others => '0'),
			data_out_b => open
		);

end architecture RTL;
