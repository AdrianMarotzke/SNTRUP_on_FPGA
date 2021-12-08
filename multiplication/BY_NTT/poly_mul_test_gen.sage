#!/usr/local/bin/sage
#####!/usr/bin/env python3

import random
from datetime import datetime

# seed = 1
seed = datetime.now()

p = 761
q = 4591
w = 286  
Fq = GF(q)
q12 = ZZ((q-1)/2)

Q1 = 7681
Q2 = 12289
Q3 = 15361

Q23inv = inverse_mod(Q2*Q3, Q1)
Q13inv = inverse_mod(Q1*Q3, Q2)
Q12inv = inverse_mod(Q1*Q2, Q3)

FQ1 = GF(Q1)
FQ2 = GF(Q2)
FQ3 = GF(Q3)
Q1_12 = ZZ((Q1-1)/2)
Q2_12 = ZZ((Q2-1)/2)
Q3_12 = ZZ((Q3-1)/2)
FQ1x.<xq1> = FQ1[]
FQ2x.<xq2> = FQ2[]
FQ3x.<xq3> = FQ3[]

Zx.<x> = ZZ[]
R.<xp> = Zx.quotient(x^p-x-1)

Fqx.<xq> = Fq[]
Rq.<xqp> = Fqx.quotient(x^p-x-1)

random.seed(seed)

# ----- PRNG
def random8():
  return random.randrange(256)
  
# ----- higher-level randomness
def randomq():
  return random.randrange(q)

def urandom32():
  c0 = random8()
  c1 = random8()
  c2 = random8()
  c3 = random8()
  return c0 + 256*c1 + 65536*c2 + 16777216*c3

def randomrange3():
  return ((urandom32() & 0x3fffffff) * 3) >> 30

def random_polyq():
  r = R([randomq()-q12 for i in range(p)])
  return r

def random_small():
  r = R([randomrange3()-1 for i in range(p)])
  return r

# ----- arithmetic mod q
def ZZ_fromFq(c):
  assert c in Fq
  return ZZ(c+q12)-q12

def R_fromRq(r):
  assert r in Rq
  return R([ZZ_fromFq(r[i]) for i in range(p)])

def Rq_fromR(r):
  assert r in R
  return Rq([r[i] for i in range(p)])

# ----- arithmetic mod Q1
def ZZ_fromFQ1(c):
  assert c in FQ1
  return ZZ(c+Q1_12)-Q1_12

def Zx_fromFQ1x(r):
  assert r in FQ1x
  return Zx([ZZ_fromFQ1(r[i]) for i in range(2*p)])

def FQ1x_fromR(r):
  assert r in R
  return FQ1x([r[i] for i in range(p)])

# ----- arithmetic mod Q2
def ZZ_fromFQ2(c):
  assert c in FQ2
  return ZZ(c+Q2_12)-Q2_12

def Zx_fromFQ2x(r):
  assert r in FQ2x
  return Zx([ZZ_fromFQ2(r[i]) for i in range(2*p)])

def FQ2x_fromR(r):
  assert r in R
  return FQ2x([r[i] for i in range(p)])

# ----- arithmetic mod Q3
def ZZ_fromFQ3(c):
  assert c in FQ3
  return ZZ(c+Q3_12)-Q3_12

def Zx_fromFQ3x(r):
  assert r in FQ3x
  return Zx([ZZ_fromFQ3(r[i]) for i in range(2*p)])

def FQ3x_fromR(r):
  assert r in R
  return FQ3x([r[i] for i in range(p)])

# ----- arithmetic in Z
def Zx_fromFqx(r):
  assert r in Fqx
  return Zx([ZZ_fromFq(r[i]) for i in range(2*p)])

def Fqx_fromR(r):
  assert r in R
  return Fqx([r[i] for i in range(p)])

# ----- polynomial output
def print_polynomial(r_module, r):
  print(     'module {mname:s} ('.format(mname=r_module))
  print(     '  input                    clk,')
  print(     '  input                    rst,')
  print(     '  input             [10:0] addr,')
  print(     '  output reg signed [13:0] dout')
  print(     ') ;')
  print(     '')
  print(     '  always @ (posedge clk) begin')
  print(     '    if(rst) begin')
  print(     '      dout <= \'sd0;')
  print(     '    end else begin')
  print(     '      case(addr)')

  for index,value in enumerate(r):
    if(value < 0):
      print( '        \'d{i:d}: dout <= -\'sd{v:d};'.format(i=index, v=-value))
    else:
      print( '        \'d{i:d}: dout <= \'sd{v:d};'.format(i=index, v=value))

  print(     '        default: dout <= \'sd0;')
  print(     '      endcase')
  print(     '    end')
  print(     '  end')
  print(     '')
  print(     'endmodule')
  print(     '')

# ----- main
def __main__():
  f = random_polyq()
  # f = random_small()
  g = random_polyq()
  # g = random_small()

  h = Zx_fromFqx(Fqx_fromR(f)*Fqx_fromR(g))
  hq1 = Zx_fromFQ1x(FQ1x_fromR(f)*FQ1x_fromR(g))
  hq2 = Zx_fromFQ2x(FQ2x_fromR(f)*FQ2x_fromR(g))
  hq3 = Zx_fromFQ3x(FQ3x_fromR(f)*FQ3x_fromR(g))
  hq0 = R_fromRq(Rq_fromR(f)*Rq_fromR(g))

  h_crt = [ZZ_fromFQ1(mod(hq1[i]*Q23inv,Q1)) * Q2 * Q3 + \
           ZZ_fromFQ2(mod(hq2[i]*Q13inv,Q2)) * Q3 * Q1 + \
           ZZ_fromFQ3(mod(hq3[i]*Q12inv,Q3)) * Q1 * Q2 for i in range(2*p)]
  h_crt = [h_crt[i]-Q1*Q2*Q3 if h_crt[i] >  (Q1*Q2*Q3-1)/2 else h_crt[i] for i in range(2*p)]
  h_crt = [h_crt[i]+Q1*Q2*Q3 if h_crt[i] < -(Q1*Q2*Q3-1)/2 else h_crt[i] for i in range(2*p)]
  h_crt = Zx_fromFqx(Fqx([mod(h_crt[i],q) for i in range(2*p)]))

  assert h == h_crt
  
  print_polynomial('f_rom', f)
  print_polynomial('g_rom', g)
  print_polynomial('h_rom', h)
  print_polynomial('hp_rom', hq0)
  print_polynomial('hq1_rom', hq1)
  print_polynomial('hq2_rom', hq2)
  print_polynomial('hq3_rom', hq3)

__main__()

