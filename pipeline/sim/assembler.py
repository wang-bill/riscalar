import os
import sys

from riscv_assembler.convert import AssemblyConverter as AC
# instantiate object, by default outputs to a file in nibbles, not in hexademicals
convert = AC(output_mode = 'f', nibble_mode = False, hex_mode = True)

# Convert a whole .s file to text file
test_file = str(sys.argv[1])
convert(test_file, "data/inst.txt")

f = open("data/inst.txt", "r")
insts = [i for i in f]
f.close()

os.remove("data/inst.txt")

f = open("data/inst.mem", "w")

for inst in insts:
  f.write(inst[2:])
f.close()