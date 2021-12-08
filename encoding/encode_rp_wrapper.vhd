library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;

entity encode_rp_wrapper is
	port(
		clock               : in  std_logic;
		reset               : in  std_logic;
		start               : in  std_logic;
		m_input             : in  std_logic_vector(15 downto 0);
		input               : in  std_logic_vector(q_num_bits - 1 downto 0);
		encode_read_address : out std_logic_vector(p_num_bits - 1 downto 0);
		output              : out std_logic_vector(7 downto 0);
		output_valid        : out std_logic;
		done                : out std_logic
	);
end entity encode_rp_wrapper;

architecture RTL of encode_rp_wrapper is
	signal state_l : std_logic_vector(4 downto 0);
	signal state_s : std_logic_vector(4 downto 0);

	signal rp_rd_addr : std_logic_vector(p_num_bits - 1 downto 0);
	signal rp_rd_data : std_logic_vector(q_num_bits downto 0);

	signal cd_wr_addr : std_logic_vector(Cipher_bytes_bits - 1 downto 0);
	signal cd_wr_data : std_logic_vector(8 - 1 downto 0);

	signal cd_wr_en : std_logic;

	signal state_max   : std_logic_vector(4 downto 0);
	signal param_r_max : std_logic_vector(p_num_bits - 1 downto 0);
	signal param_m0    : std_logic_vector(q_num_bits downto 0);

	signal param_1st_round : std_logic;
	signal param_outs1     : std_logic_vector(2 downto 0);
	signal param_outsl     : std_logic_vector(2 downto 0);

	signal ciphertext_state_max   : std_logic_vector(4 downto 0);
	signal ciphertext_param_r_max : std_logic_vector(p_num_bits - 1 downto 0);
	signal ciphertext_param_m0    : std_logic_vector(q_num_bits downto 0);

	signal ciphertext_param_1st_round : std_logic;
	signal ciphertext_param_outs1     : std_logic_vector(2 downto 0);
	signal ciphertext_param_outsl     : std_logic_vector(2 downto 0);

	signal publickey_state_max   : std_logic_vector(4 downto 0);
	signal publickey_param_r_max : std_logic_vector(p_num_bits - 1 downto 0);
	signal publickey_param_m0    : std_logic_vector(q_num_bits downto 0);

	signal publickey_param_1st_round : std_logic;
	signal publickey_param_outs1     : std_logic_vector(2 downto 0);
	signal publickey_param_outsl     : std_logic_vector(2 downto 0);

	signal start_check : std_logic;

	signal rp_rd_addr_reg : std_logic_vector(p_num_bits - 1 downto 0);
	signal input_reg      : std_logic_vector(q_num_bits - 1 downto 0);

begin
	encode_rp_inst : entity work.encode_rp
		port map(
			clk             => clock,
			start           => start,
			done            => done,
			state_l         => state_l,
			state_s         => state_s,
			rp_rd_addr      => rp_rd_addr,
			rp_rd_data      => rp_rd_data,
			cd_wr_addr      => cd_wr_addr,
			cd_wr_data      => cd_wr_data,
			cd_wr_en        => cd_wr_en,
			state_max       => state_max,
			param_r_max     => param_r_max,
			param_m0        => param_m0,
			param_1st_round => param_1st_round,
			param_outs1     => param_outs1,
			param_outsl     => param_outsl
		);

	state_max       <= ciphertext_state_max when unsigned(m_input) /= to_unsigned(q, 16) else publickey_state_max;
	param_r_max     <= ciphertext_param_r_max when unsigned(m_input) /= to_unsigned(q, 16) else publickey_param_r_max;
	param_m0        <= ciphertext_param_m0 when unsigned(m_input) /= to_unsigned(q, 16) else publickey_param_m0;
	param_1st_round <= ciphertext_param_1st_round when unsigned(m_input) /= to_unsigned(q, 16) else publickey_param_1st_round;
	param_outs1     <= ciphertext_param_outs1 when unsigned(m_input) /= to_unsigned(q, 16) else publickey_param_outs1;
	param_outsl     <= ciphertext_param_outsl when unsigned(m_input) /= to_unsigned(q, 16) else publickey_param_outsl;

	encode_read_address <= rp_rd_addr when start = '1' else std_logic_vector(unsigned(rp_rd_addr)+1) when rp_rd_addr /= param_r_max else (others => '0');
	rp_rd_data          <= std_logic_vector(resize(unsigned(input_reg), q_num_bits + 1)) when rp_rd_addr_reg = rp_rd_addr  else std_logic_vector(resize(unsigned(input), q_num_bits + 1));
	output              <= cd_wr_data;
	output_valid        <= cd_wr_en when start_check = '1' and start = '0' else '0';

	sart_check_proc : process(clock, reset) is
	begin
		if reset = '1' then
			start_check <= '0';
		elsif rising_edge(clock) and start = '1' then
			start_check <= '1';
		end if;
	end process sart_check_proc;

	name : process(clock) is
	begin
		if rising_edge(clock) then
			rp_rd_addr_reg <= rp_rd_addr;

			if rp_rd_addr_reg /= rp_rd_addr or start = '1' then
				input_reg <= input;
			end if;

		end if;
	end process name;

	rp761q1531encode_param_inst : entity work.rp761q1531encode_param
		port map(
			state_max       => ciphertext_state_max,
			state_l         => state_l,
			state_s         => state_s,
			param_r_max     => ciphertext_param_r_max,
			param_m0        => ciphertext_param_m0,
			param_1st_round => ciphertext_param_1st_round,
			param_outs1     => ciphertext_param_outs1,
			param_outsl     => ciphertext_param_outsl
		);

	rp761q4591encode_param_inst : entity work.rp761q4591encode_param
		port map(
			state_max       => publickey_state_max,
			state_l         => state_l,
			state_s         => state_s,
			param_r_max     => publickey_param_r_max,
			param_m0        => publickey_param_m0,
			param_1st_round => publickey_param_1st_round,
			param_outs1     => publickey_param_outs1,
			param_outsl     => publickey_param_outsl
		);

end architecture RTL;
