# Streamlined NTRU Prime on FPGA

**WARNING This is experimental code, do NOT use in production systems**

This is a constant time hardware implementation of round 3 Streamlined NTRU Prime. This is the code from the paper https://eprint.iacr.org/2021/1444.

The following table contains the performance numbers for the parameter set sntrup761, on a Xilinx Zynq Ultrascale +:
| Design     | Module  | Slices  | LUT     | FF      | BRAM | DSP | Freq MHz| Cycles | Time     |
|------------|---------|--------:|--------:|--------:|-----:|----:|--------:|-------:|---------:|
| High speed | Key Gen | 6,038   | 37,813  | 25,368  | 33   | 23  | 285     | 64,026 | 224.7 us |
|            | Encap   | 5,381   | 31,996  | 22,425  | 4.5  | 6   | 289     | 5,007  | 17.3 us  |
|            | Decap   | 5,432   | 32,301  | 22,724  | 3.5  | 9   | 285     | 10,989 | 38.6 us  |
| Low area   | Key Gen | 1,232   | 7,216   | 3,726   | 5.5  | 12  | 285     | 629,367| 2,208 us |
|            | Encap   | 1,074   | 6,030   | 3,211   | 4.5  | 7   | 290     | 29,245 | 100.8 us |
|            | Decap   | 1,051   | 6,016   | 3,194   | 3    | 7   | 283     | 85,628 | 302.6 us |


The following table contains the performance numbers for the parameter set sntrup761, on a Xilinx Artix 7:
| Design     | Module  | Slices | LUT    | FF     |  BRAM | DSP  | Freq MHz| Cycles | Time     |
|------------|---------|-------:|-------:|-------:|------:|-----:|--------:|-------:|---------:|
| high speed | Key Gen | 10,827 | 39,200 | 25,536 | 33.5  | 23   | 143     | 64,026 | 447.7 us |
|            | Encap   | 11,218 | 40,879 | 22,382 | 4.5   | 6    | 144     | 5,007  | 34.8 us  |
|            | Decap   | 10,169 | 36,789 | 22,700 | 3.5   | 9    | 137     | 10,989 | 80.2 us  |
| low area   | Key Gen | 2,376  | 7,579  | 3,824  | 5.5   | 12   | 159     | 629,367| 3,958 us |
|            | Encap   | 1,945  | 6,379  | 3,069  | 4.5   | 6    | 147     | 29,245 | 198.9 us |
|            | Decap   | 1,842  | 6,279  | 3,086  | 3     | 7    | 131     | 85,628 | 653.6 us |


The following table contains the numbers for full implementation, with all operations merged.
| Design     | Platform         | Slices   | LUT      | FF       | BRAM | DSP | Freq (MHz) |
|------------|------------------|----------:|----------:|----------:|------:|-----:|------------:|
| High speed | Zynq Ultrascale+ | 7051     | 40,060   | 26,384   | 36.5 | 31  | 285        |
|            | Artix-7          | 11,745   | 41,428   | 26,381   | 36.5 | 31  | 140        |
| Low area   | Zynq Ultrascale+ | 1,539    | 9,154    | 4,423    | 8.5  | 18  | 285        |
|            | Artix-7          | 2,968    | 9,574    | 4,399    | 8.5  | 18  | 128        |

The file constants.pkg.vhd contains some use configurable constants.

Only the parameter set sntrup761 is currently supported fully, others can be selected with the constant "use_parameter_set" in the file constants.pkg.vhd.

Batch key generation and the batch size can be set with the constant "BATCH_SIZE". Batch sizes of 5, 21 and 42 are recomended. Set to 0 to disable batch keygen.

The constant "keygen_vector_width" sets the vector width during rq inversion. 2 to the power of this constant are the number of parallel divsteps.

Set "use_rq_mult_parallel_ram" to true to use the smaller, but also smaller multiplier.

Set "seperate_cipher_decode" to false to remove the second decoder during decapsulation. Decoding then happens sequentially.


The top module is ntru_prime_top, the corrosponding testbench is tb_ntru_prime_top.

The testbench is in the folder tb. The testbench uses stimulus data gathered from the KAT from the NIST submission of Streamlined NTRU Prime (https://ntruprime.cr.yp.to/nist.html). Data for 50 KAT for the three parameter sets are in folder tb\tb_stimulus\, tb_ntru_prime_top will automatically select the correct test data.

The folder sha-512 contains the implementation of the hash function from https://github.com/dsaves/SHA-512, as well as the wrapper used to integrate it into my implementation.

The folder misc contains some miscellaneous items, such as block ram and stack memory, that are need across the design.

The folders encapsulation, decapsulation, keygen, multiplication and encoding contain the respective vhdl files for that operation.

