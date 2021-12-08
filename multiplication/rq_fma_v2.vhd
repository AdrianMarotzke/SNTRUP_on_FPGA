library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;

entity rq_fma_v2 is
	port(
		a      : in  signed(2 downto 0);
		b      : in  signed(q_num_bits - 1 downto 0);
		c      : in  signed(p_num_bits + q_num_bits - 1 downto 0);
		output : out signed(p_num_bits + q_num_bits - 1 downto 0)
	);
end entity rq_fma_v2;

architecture RTL of rq_fma_v2 is
	-- calculate a*b+c
--	signal b_mux   : signed(q_num_bits * 2 - 1 downto 0);
	signal b_mux_a : signed(q_num_bits * 2 - 1 downto 0);
	signal b_mux_b : signed(q_num_bits * 2 - 1 downto 0);
--	signal b_mux_c : signed(q_num_bits * 2 - 1 downto 0);

begin

	--q_fma_process : process(a, b, c) is
	--begin
	--	output <= rq_fma_function(a, b, c);
	--end process q_fma_process;

	b_mux_a <= resize(b, q_num_bits * 2) when a(0) = '1'
	           else shift_left(resize(b, q_num_bits * 2), 1) when a(1) = '1'
	           else (others => '0');

	b_mux_b <= b_mux_a when a(2) = '0' else (NOT b_mux_a)+1;
	
--	b_mux <= (others => '0') when a = "000"
--	         else resize(b, q_num_bits * 2) when a = "001"
--	         else shift_left(resize(b, q_num_bits * 2), 1) when a = "010"
--	         else shift_left(resize(-1 * b, q_num_bits * 2), 1) when a = "110"
--	         else resize(-1 * b, q_num_bits * 2);

	output <= resize(c + b_mux_b, p_num_bits + q_num_bits);
end architecture RTL;
