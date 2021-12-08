#!/usr/local/bin/sage
#####!/usr/bin/env python3

import sys

def find_gen(quotient):
  #S = [];
  for gen in range(2, quotient):
    if(mod(power(gen, 256), quotient) == quotient - 1):
      #S += [gen]
      break
  #print('Quotient = {q}:'.format(q=quotient))
  #print(S[0:10])
  #print('Quotient = {q}: Gen = {g}'.format(q=quotient, g=gen))
  return gen

def gen_gen(gen, quo):
  I = list(range(0, 512))
  S = map(lambda x : int(mod(power(gen, x), quo)), I)
  S = map(lambda x : x - quo if 2 * x + 1 > quo else x, S)
  for index, value in enumerate(S):
    print('        data[{i:d}] <= {v:d};'.format(i=index, v=value))
  #print(S)

def main():
  cli_args = sys.argv[1:]

  try:
    assert len(cli_args) == 1
    quotient = int(cli_args[0])
    assert is_prime(quotient)
    gen = find_gen(quotient)
    gen_gen(gen, quotient)
  except AssertionError:
    print('  Usage: {a:s} {{Quotient}}'.format(a=sys.argv[0]))
    print('         Quotient: needs to be a prime.');

main()

