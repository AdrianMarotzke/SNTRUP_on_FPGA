library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use ieee.math_real.all;

-- contains of the memories for the reciprocal calculation of r3 polynomials
entity bram_r3_reciprocal_vector is
	generic(
		bram_address_width : integer := 10;
		bram_data_width    : integer := 2;
		vector_size        : integer := 16;
		vector_width       : integer := 4
	);
	port(
		clock             : in  std_logic;
		swap_mask_s       : in  std_logic;
		---
		bram_f_address_a  : in  std_logic_vector(bram_address_width - vector_width - 1 downto 0);
		bram_g_address_a  : in  std_logic_vector(bram_address_width - vector_width - 1 downto 0);
		bram_v_address_a  : in  std_logic_vector(bram_address_width - vector_width - 1 downto 0);
		bram_r_address_a  : in  std_logic_vector(bram_address_width - vector_width - 1 downto 0);
		bram_f_data_out_a : out std_logic_vector(bram_data_width * vector_size - 1 downto 0);
		bram_g_data_out_a : out std_logic_vector(bram_data_width * vector_size - 1 downto 0);
		bram_v_data_out_a : out std_logic_vector(bram_data_width * vector_size - 1 downto 0);
		bram_r_data_out_a : out std_logic_vector(bram_data_width * vector_size - 1 downto 0);
		---
		bram_f_data_in_b  : in  std_logic_vector(bram_data_width * vector_size - 1 downto 0);
		bram_g_data_in_b  : in  std_logic_vector(bram_data_width * vector_size - 1 downto 0);
		bram_v_data_in_b  : in  std_logic_vector(bram_data_width * vector_size - 1 downto 0);
		bram_r_data_in_b  : in  std_logic_vector(bram_data_width * vector_size - 1 downto 0);
		bram_f_write_b    : in  std_logic;
		bram_g_write_b    : in  std_logic;
		bram_v_write_b    : in  std_logic;
		bram_r_write_b    : in  std_logic;
		bram_f_address_b  : in  std_logic_vector(bram_address_width - vector_width - 1 downto 0);
		bram_g_address_b  : in  std_logic_vector(bram_address_width - vector_width - 1 downto 0);
		bram_v_address_b  : in  std_logic_vector(bram_address_width - vector_width - 1 downto 0);
		bram_r_address_b  : in  std_logic_vector(bram_address_width - vector_width - 1 downto 0)
	);
end entity bram_r3_reciprocal_vector;

architecture RTL of bram_r3_reciprocal_vector is

	type vector_address_type is array (vector_size downto 0) of STD_LOGIC_VECTOR(bram_address_width - vector_width - 1 downto 0);

	signal bram_fg_one_address_a  : vector_address_type;
	signal bram_fg_one_write_a    : std_logic_vector(vector_size - 1 downto 0);
	signal bram_fg_one_data_in_a  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_one_data_out_a : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_one_address_b  : vector_address_type;
	signal bram_fg_one_write_b    : std_logic_vector(vector_size - 1 downto 0);
	signal bram_fg_one_data_in_b  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_one_data_out_b : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);

	signal bram_fg_two_address_a  : vector_address_type;
	signal bram_fg_two_write_a    : std_logic_vector(vector_size - 1 downto 0);
	signal bram_fg_two_data_in_a  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_two_data_out_a : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_two_address_b  : vector_address_type;
	signal bram_fg_two_write_b    : std_logic_vector(vector_size - 1 downto 0);
	signal bram_fg_two_data_in_b  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_two_data_out_b : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);

	signal bram_vr_one_address_a  : vector_address_type;
	signal bram_vr_one_write_a    : std_logic_vector(vector_size - 1 downto 0);
	signal bram_vr_one_data_in_a  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_one_data_out_a : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_one_address_b  : vector_address_type;
	signal bram_vr_one_write_b    : std_logic_vector(vector_size - 1 downto 0);
	signal bram_vr_one_data_in_b  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_one_data_out_b : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);

	signal bram_vr_two_address_a  : vector_address_type;
	signal bram_vr_two_write_a    : std_logic_vector(vector_size - 1 downto 0);
	signal bram_vr_two_data_in_a  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_two_data_out_a : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_two_address_b  : vector_address_type;
	signal bram_vr_two_write_b    : std_logic_vector(vector_size - 1 downto 0);
	signal bram_vr_two_data_in_b  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_two_data_out_b : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);

begin

	generate_label : for i in 0 to vector_size - 1 generate

		bram_fg_one_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width) <= bram_f_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width) when swap_mask_s = '0' else bram_g_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width);
		bram_fg_two_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width) <= bram_g_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width) when swap_mask_s = '0' else bram_f_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width);
		bram_fg_one_address_b(i)                                                        <= bram_f_address_b when swap_mask_s = '0' else bram_g_address_b;
		bram_fg_two_address_b(i)                                                        <= bram_g_address_b when swap_mask_s = '0' else bram_f_address_b;

		bram_fg_one_write_b(i) <= bram_f_write_b when swap_mask_s = '0' else bram_g_write_b;
		bram_fg_two_write_b(i) <= bram_g_write_b when swap_mask_s = '0' else bram_f_write_b;

		bram_vr_one_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width) <= bram_v_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width) when swap_mask_s = '0' else bram_r_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width);
		bram_vr_two_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width) <= bram_r_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width) when swap_mask_s = '0' else bram_v_data_in_b((i + 1) * bram_data_width - 1 downto i * bram_data_width);

		bram_vr_one_address_b(i) <= bram_v_address_b when swap_mask_s = '0' else bram_r_address_b;
		bram_vr_two_address_b(i) <= bram_r_address_b when swap_mask_s = '0' else bram_v_address_b;

		bram_vr_one_write_b(i) <= bram_v_write_b when swap_mask_s = '0' else bram_r_write_b;
		bram_vr_two_write_b(i) <= bram_r_write_b when swap_mask_s = '0' else bram_v_write_b;

		bram_fg_one_address_a(i) <= bram_f_address_a when swap_mask_s = '0' else bram_g_address_a;
		bram_fg_two_address_a(i) <= bram_g_address_a when swap_mask_s = '0' else bram_f_address_a;
		bram_vr_one_address_a(i) <= bram_v_address_a when swap_mask_s = '0' else bram_r_address_a;
		bram_vr_two_address_a(i) <= bram_r_address_a when swap_mask_s = '0' else bram_v_address_a;

		bram_f_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width) <= bram_fg_one_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width) when swap_mask_s = '0' else bram_fg_two_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width);
		bram_g_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width) <= bram_fg_two_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width) when swap_mask_s = '0' else bram_fg_one_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width);
		bram_v_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width) <= bram_vr_one_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width) when swap_mask_s = '0' else bram_vr_two_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width);
		bram_r_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width) <= bram_vr_two_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width) when swap_mask_s = '0' else bram_vr_one_data_out_a((i + 1) * bram_data_width - 1 downto i * bram_data_width);
	end generate generate_label;

	bram_fg_one_data_in_a <= (others => '0');
	bram_fg_two_data_in_a <= (others => '0');
	bram_vr_one_data_in_a <= (others => '0');
	bram_vr_two_data_in_a <= (others => '0');

	bram_fg_one_write_a <= (others => '0');
	bram_fg_two_write_a <= (others => '0');
	bram_vr_one_write_a <= (others => '0');
	bram_vr_two_write_a <= (others => '0');

	--gen_ram : for i in 0 to vector_size - 1 generate
		block_ram_inst_fg_one : entity work.SDP_dist_RAM
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size
			)
			port map(
				clock      => clock,
				address_a  => bram_fg_one_address_a(0),
				data_out_a => bram_fg_one_data_out_a,
				address_b  => bram_fg_one_address_b(0),
				write_b    => bram_fg_one_write_b(0),
				data_in_b  => bram_fg_one_data_in_b
			);

		block_ram_inst_fg_two : entity work.SDP_dist_RAM
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size
			)
			port map(
				clock      => clock,
				address_a  => bram_fg_two_address_a(0),
				data_out_a => bram_fg_two_data_out_a,
				address_b  => bram_fg_two_address_b(0),
				write_b    => bram_fg_two_write_b(0),
				data_in_b  => bram_fg_two_data_in_b
			);

		block_ram_inst_vr_one : entity work.SDP_dist_RAM
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size
			)
			port map(
				clock      => clock,
				address_a  => bram_vr_one_address_a(0),
				data_out_a => bram_vr_one_data_out_a,
				address_b  => bram_vr_one_address_b(0),
				write_b    => bram_vr_one_write_b(0),
				data_in_b  => bram_vr_one_data_in_b
			);

		block_ram_inst_vr_two : entity work.SDP_dist_RAM
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size
			)
			port map(
				clock      => clock,
				address_a  => bram_vr_two_address_a(0),
				data_out_a => bram_vr_two_data_out_a,
				address_b  => bram_vr_two_address_b(0),
				write_b    => bram_vr_two_write_b(0),
				data_in_b  => bram_vr_two_data_in_b
			);
	--end generate gen_ram;
end architecture RTL;
