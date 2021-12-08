library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

-- Dual port bram, with different widths port A and B
entity block_ram_dual_width is
	Generic(
		ADDRESS_WIDTH_A : integer := 8;
		DATA_WIDTH_A    : integer := 8;
		ADDRESS_WIDTH_B : integer := 7;
		DATA_WIDTH_B    : integer := 16
	);
	Port(clock      : in  STD_LOGIC;
	     address_a  : in  STD_LOGIC_VECTOR(ADDRESS_WIDTH_A - 1 downto 0);
	     write_a    : in  STD_LOGIC;
	     data_in_a  : in  STD_LOGIC_VECTOR(DATA_WIDTH_A - 1 downto 0);
	     data_out_a : out STD_LOGIC_VECTOR(DATA_WIDTH_A - 1 downto 0);
	     address_b  : in  STD_LOGIC_VECTOR(ADDRESS_WIDTH_B - 1 downto 0);
	     write_b    : in  STD_LOGIC;
	     data_in_b  : in  STD_LOGIC_VECTOR(DATA_WIDTH_B - 1 downto 0);
	     data_out_b : out STD_LOGIC_VECTOR(DATA_WIDTH_B - 1 downto 0)
	    );
end entity block_ram_dual_width;

architecture RTL of block_ram_dual_width is

	function max(L, R : INTEGER) return INTEGER is
	begin
		if L > R then
			return L;
		else
			return R;
		end if;
	end;

	function min(L, R : INTEGER) return INTEGER is
	begin
		if L < R then
			return L;
		else
			return R;
		end if;
	end;

	constant MIN_WIDTH : integer := min(DATA_WIDTH_A, DATA_WIDTH_B);
	constant MAX_WIDTH : integer := max(DATA_WIDTH_A, DATA_WIDTH_B);
	constant MAX_SIZE  : integer := max(2**ADDRESS_WIDTH_A, 2**ADDRESS_WIDTH_B);

	constant RATIO : integer := MAX_WIDTH / MIN_WIDTH;

	type memory is array (0 to MAX_SIZE - 1) of std_logic_vector(MIN_WIDTH - 1 downto 0);

	shared variable RAM : memory;
begin

	port_a : process(clock) is
	begin
		if rising_edge(clock) then
			if (write_a = '1') then
				RAM(to_integer(unsigned(address_a))) := data_in_a;
			end if;
			data_out_a <= RAM(to_integer(unsigned(address_a)));
		end if;
	end process port_a;

	port_b : process(clock) is
	begin
		if rising_edge(clock) then
			for i in 0 to RATIO - 1 loop
				if write_b = '1' then
					RAM(to_integer(unsigned(address_b) & to_unsigned(i, integer(ceil(log2(REAL(RATIO))))))) := data_in_b((i + 1) * MIN_WIDTH - 1 downto i * MIN_WIDTH);
				end if;

				data_out_b((i + 1) * MIN_WIDTH - 1 downto i * MIN_WIDTH) <= RAM(to_integer(unsigned(address_b) & to_unsigned(i, integer(ceil(log2(REAL(RATIO)))))));
			end loop;
		end if;
	end process port_b;
end architecture RTL;
