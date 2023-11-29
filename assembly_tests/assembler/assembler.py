import os
import sys

from riscv_assembler.convert import AssemblyConverter as AC
# instantiate object, by default outputs to a file in nibbles, not in hexademicals
convert = AC(output_mode = 'f', nibble_mode = False, hex_mode = True)

# Convert a whole .s file to text file
test_file = str(sys.argv[1])
convert(test_file, "output.txt")

f = open("output.txt", "r")
g = open("output1.txt", "w")

hex_dict = {'0': '0000', '1': '0001', '2': '0010', '3': '0011', '4': '0100', '5': '0101', '6': '0110', '7': '0111', '8': '1000', '9': '1001', 'a': '1010', 'b': '1011', 'c': '1100', 'd': '1101', 'e': '1110', 'f': '1111'}

arr= []
for i in f:
  arr.append(i.strip()[2:])

print(arr)
for i in arr:
  binary = ''
  for digit in i:
    binary += hex_dict[digit]
  g.write(binary + "\n")

f.close()
g.close()

os.remove("output.txt")
os.rename("output1.txt", "output.txt")

'''
convert(test_file, "data/inst.txt")

f = open("data/inst.txt", "r")
insts = [i for i in f]
f.close()

os.remove("data/inst.txt")

f = open("data/inst.mem", "w")

for inst in insts:
  f.write(inst[2:])
f.write("00000000")
f.close()
'''
