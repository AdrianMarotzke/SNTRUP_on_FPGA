library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use ieee.math_real.all;

-- contains of the memories for the reciprocal calculation of rq polynomials
entity bram_rq_reciprocal_3_vector is
	generic(
		bram_address_width : integer := integer(ceil(log2(real(p + 1))));
		bram_data_width    : integer := q_num_bits;
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
end entity bram_rq_reciprocal_3_vector;

architecture RTL of bram_rq_reciprocal_3_vector is

	signal bram_fg_one_address_a  : std_logic_vector(bram_address_width - vector_width - 1 downto 0);
	signal bram_fg_one_write_a    : std_logic;
	signal bram_fg_one_data_in_a  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_one_data_out_a : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_one_address_b  : std_logic_vector(bram_address_width - vector_width - 1 downto 0);
	signal bram_fg_one_write_b    : std_logic;
	signal bram_fg_one_data_in_b  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_one_data_out_b : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);

	signal bram_fg_two_address_a  : std_logic_vector(bram_address_width - vector_width - 1 downto 0);
	signal bram_fg_two_write_a    : std_logic;
	signal bram_fg_two_data_in_a  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_two_data_out_a : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_two_address_b  : std_logic_vector(bram_address_width - vector_width - 1 downto 0);
	signal bram_fg_two_write_b    : std_logic;
	signal bram_fg_two_data_in_b  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_fg_two_data_out_b : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);

	signal bram_vr_one_address_a  : std_logic_vector(bram_address_width - vector_width - 1 downto 0);
	signal bram_vr_one_write_a    : std_logic;
	signal bram_vr_one_data_in_a  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_one_data_out_a : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_one_address_b  : std_logic_vector(bram_address_width - vector_width - 1 downto 0);
	signal bram_vr_one_write_b    : std_logic;
	signal bram_vr_one_data_in_b  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_one_data_out_b : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);

	signal bram_vr_two_address_a  : std_logic_vector(bram_address_width - vector_width - 1 downto 0);
	signal bram_vr_two_write_a    : std_logic;
	signal bram_vr_two_data_in_a  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_two_data_out_a : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_two_address_b  : std_logic_vector(bram_address_width - vector_width - 1 downto 0);
	signal bram_vr_two_write_b    : std_logic;
	signal bram_vr_two_data_in_b  : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);
	signal bram_vr_two_data_out_b : STD_LOGIC_VECTOR(bram_data_width * vector_size - 1 downto 0);

begin
	bram_fg_one_data_in_b <= bram_f_data_in_b when swap_mask_s = '0' else bram_g_data_in_b;
	bram_fg_two_data_in_b <= bram_g_data_in_b when swap_mask_s = '0' else bram_f_data_in_b;

	bram_fg_one_address_b <= bram_f_address_b when swap_mask_s = '0' else bram_g_address_b;
	bram_fg_two_address_b <= bram_g_address_b when swap_mask_s = '0' else bram_f_address_b;

	bram_fg_one_write_b <= bram_f_write_b when swap_mask_s = '0' else bram_g_write_b;
	bram_fg_two_write_b <= bram_g_write_b when swap_mask_s = '0' else bram_f_write_b;

	bram_vr_one_data_in_b <= bram_v_data_in_b when swap_mask_s = '0' else bram_r_data_in_b;
	bram_vr_two_data_in_b <= bram_r_data_in_b when swap_mask_s = '0' else bram_v_data_in_b;

	bram_vr_one_address_b <= bram_v_address_b when swap_mask_s = '0' else bram_r_address_b;
	bram_vr_two_address_b <= bram_r_address_b when swap_mask_s = '0' else bram_v_address_b;

	bram_vr_one_write_b <= bram_v_write_b when swap_mask_s = '0' else bram_r_write_b;
	bram_vr_two_write_b <= bram_r_write_b when swap_mask_s = '0' else bram_v_write_b;

	bram_fg_one_address_a <= bram_f_address_a when swap_mask_s = '0' else bram_g_address_a;
	bram_fg_two_address_a <= bram_g_address_a when swap_mask_s = '0' else bram_f_address_a;
	bram_vr_one_address_a <= bram_v_address_a when swap_mask_s = '0' else bram_r_address_a;
	bram_vr_two_address_a <= bram_r_address_a when swap_mask_s = '0' else bram_v_address_a;

	bram_f_data_out_a <= bram_fg_one_data_out_a when swap_mask_s = '0' else bram_fg_two_data_out_a;
	bram_g_data_out_a <= bram_fg_two_data_out_a when swap_mask_s = '0' else bram_fg_one_data_out_a;
	bram_v_data_out_a <= bram_vr_one_data_out_a when swap_mask_s = '0' else bram_vr_two_data_out_a;
	bram_r_data_out_a <= bram_vr_two_data_out_a when swap_mask_s = '0' else bram_vr_one_data_out_a;

	dist_ram_gen : if keygen_vector_width >= 2 generate
		block_ram_inst_fg_one : entity work.SDP_dist_RAM
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size
			)
			port map(
				clock      => clock,
				address_a  => bram_fg_one_address_a,
				data_out_a => bram_fg_one_data_out_a,
				address_b  => bram_fg_one_address_b,
				write_b    => bram_fg_one_write_b,
				data_in_b  => bram_fg_one_data_in_b
			);

		block_ram_inst_fg_two : entity work.SDP_dist_RAM
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size
			)
			port map(
				clock      => clock,
				address_a  => bram_fg_two_address_a,
				data_out_a => bram_fg_two_data_out_a,
				address_b  => bram_fg_two_address_b,
				write_b    => bram_fg_two_write_b,
				data_in_b  => bram_fg_two_data_in_b
			);

		block_ram_inst_vr_one : entity work.SDP_dist_RAM
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size
			)
			port map(
				clock      => clock,
				address_a  => bram_vr_one_address_a,
				data_out_a => bram_vr_one_data_out_a,
				address_b  => bram_vr_one_address_b,
				write_b    => bram_vr_one_write_b,
				data_in_b  => bram_vr_one_data_in_b
			);

		block_ram_inst_vr_two : entity work.SDP_dist_RAM
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size
			)
			port map(
				clock      => clock,
				address_a  => bram_vr_two_address_a,
				data_out_a => bram_vr_two_data_out_a,
				address_b  => bram_vr_two_address_b,
				write_b    => bram_vr_two_write_b,
				data_in_b  => bram_vr_two_data_in_b
			);

	end generate dist_ram_gen;

	block_ram_gen : if keygen_vector_width <= 1 generate
		block_ram_inst_fg_one : entity work.block_ram
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size,
				DUAL_PORT     => TRUE
			)
			port map(
				clock      => clock,
				address_a  => bram_fg_one_address_a,
				write_a    => '0',
				data_in_a  => (others => '0'),
				data_out_a => bram_fg_one_data_out_a,
				address_b  => bram_fg_one_address_b,
				write_b    => bram_fg_one_write_b,
				data_in_b  => bram_fg_one_data_in_b,
				data_out_b => open
			);

		block_ram_inst_fg_two : entity work.block_ram
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size,
				DUAL_PORT     => TRUE
			)
			port map(
				clock      => clock,
				address_a  => bram_fg_two_address_a,
				write_a    => '0',
				data_in_a  => (others => '0'),
				data_out_a => bram_fg_two_data_out_a,
				address_b  => bram_fg_two_address_b,
				write_b    => bram_fg_two_write_b,
				data_in_b  => bram_fg_two_data_in_b,
				data_out_b => open
			);

		block_ram_inst_vr_one : entity work.block_ram
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size,
				DUAL_PORT     => TRUE
			)
			port map(
				clock      => clock,
				address_a  => bram_vr_one_address_a,
				write_a    => '0',
				data_in_a  => (others => '0'),
				data_out_a => bram_vr_one_data_out_a,
				address_b  => bram_vr_one_address_b,
				write_b    => bram_vr_one_write_b,
				data_in_b  => bram_vr_one_data_in_b,
				data_out_b => open
			);

		block_ram_inst_vr_two : entity work.block_ram
			generic map(
				ADDRESS_WIDTH => bram_address_width - vector_width,
				DATA_WIDTH    => bram_data_width * vector_size,
				DUAL_PORT     => TRUE
			)
			port map(
				clock      => clock,
				address_a  => bram_vr_two_address_a,
				write_a    => '0',
				data_in_a  => (others => '0'),
				data_out_a => bram_vr_two_data_out_a,
				address_b  => bram_vr_two_address_b,
				write_b    => bram_vr_two_write_b,
				data_in_b  => bram_vr_two_data_in_b,
				data_out_b => open
			);

	end generate block_ram_gen;

end architecture RTL;
