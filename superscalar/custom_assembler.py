import sys
import os

inst_names = ["add", "sub", "xor", "or", "and", "sll", "srl", "sra", "slt", "sltu", # 10, R
              "addi", "xori", "ori", "andi", "slli", "srli", "srai", "slti", "sltiu", # 9, I
              "lb", "lh", "lw", "lbu", "lhu", # 5, I
              "sb", "sh", "sw", # 3, S
              "beq", "bne", "blt", "bge", "bltu", "bgeu", # 6, B
              "jal", "jalr", # 2, J, I
              "lui", "aupic", # 2, U 
              "ecall", "ebreak", # 2, I
              "mul", "mulh", "mulsu", "mulu", "div", "divu", "rem", "remu"] # 8, R 

bin_to_hex = {
  "0000": "0",
  "0001": "1",
  "0010": "2",
  "0011": "3",
  "0100": "4",
  "0101": "5",
  "0110": "6",
  "0111": "7",
  "1000": "8",
  "1001": "9",
  "1010": "A",
  "1011": "B",
  "1100": "C",
  "1101": "D",
  "1110": "E",
  "1111": "F"
}

def convert_to_hex(n):
  result = ""
  for i in range(0, 32, 4):
    result += bin_to_hex[n[i:i+4]]
  return result

def dtb_register(n):
    '''
    decimal to binary converter
    NOT a general conversion, tailored for REGISTER number conversion
    '''
    bin_str = bin(n).replace("0b", "") 
    while len(bin_str) < 5:
      bin_str = "0" + bin_str
    return bin_str

def dtb_imm(n):
    '''
    decimal to binary converter
    NOT a general conversion, tailored for IMMEDIATE number conversion
    in particular, this dtb is signed and returns 32 bits
    '''
    n = int(n)
    val = abs(n)
    bin_str = bin(val).replace("0b", "") 
    while len(bin_str) < 32:
      bin_str = "0" + bin_str
    
    if n < 0:
      result = ["1" if i == "0" else "0" for i in bin_str]
      for i in range(len(result)-1, -1, -1):
        if result[i] == "0":
          result[i] = "1"
          break
        if i == 0:
          result = 32 * "0"
      bin_str = ''.join(result)


    return bin_str



def register_map(register):
  '''
  converts register string to number
  '''
  reg_len = len(register)
  reg_num = None

  if register == "zero":
    reg_num = 0
  
  if register == "ra":
    reg_num = 1

  if register == "sp":
    reg_num = 2
  
  if register == "gp":
    reg_num = 3

  if register == "tp":
    reg_num = 4

  if register == "fp":
    reg_num = 8

  assert reg_len == 2 or reg_len == 3, "check your register declaration"

  if register[0] == "x":
    reg_num = int(register[1:])
    assert reg_num >= 0 and reg_num <= 31, "check register number (x)"
  
  elif register[0] == "a":
    reg_num = int(register[1:])
    assert reg_num >= 0 and reg_num <= 7, "check register number (a)"
    reg_num = reg_num + 10
  
  elif register[0] == "s":
    reg_num = int(register[1:])
    assert reg_num >= 0 and reg_num <= 11, "check register number (s)"
    if reg_num <= 1:
      reg_num = reg_num + 8
    else:
      reg_num = reg_num + 16

  elif register[0] == "t":
    reg_num = int(register[1:])
    assert reg_num >= 0 and reg_num <= 6, "check register number (t)"
    if reg_num <= 2:
      reg_num = reg_num + 5
    else:
      reg_num = reg_num + 25

  else:
    raise Exception("Invalid register letter")
  
  assert reg_num != None, "Unchecked case in register map"
  
  return dtb_register(reg_num)

def R_type(funct7, rs2, rs1, funct3, rd, opcode):
  return funct7 + rs2 + rs1 + funct3 + rd + opcode

def I_type(imm, rs1, funct3, rd, opcode):
  imm = imm[20:32]
  return imm + rs1 + funct3 + rd + opcode

def S_type(imm, rs2, rs1, funct3, opcode):
  l_imm = imm[20:27]
  r_imm = imm[27:32]
  return l_imm + rs2 + rs1 + funct3 + r_imm + opcode

def B_type(imm, rs2, rs1, funct3, opcode):
  l_imm = imm[19] + imm[21:27]
  r_imm = imm[27:31] + imm[20]
  return l_imm + rs2 + rs1 + funct3 + r_imm + opcode

def U_type(imm, rd, opcode):
  return imm[0:20] + rd + opcode

def J_type(imm, rd, opcode):
  return imm[11] + imm[21:31] + imm[20] + imm[12:20] + rd + opcode

def find_type(inst_name):
  '''
  Finds the type (R, I, S, B, U, J) of the instruction
  '''
  for i in range(len(inst_names)):
    if inst_names[i] == inst_name:
      if i < 10:
        return "R"
      if i < 19:
        return "I"
      if i < 24:
        return "I"
      if i < 27:
        return "S"
      if i < 33:
        return "B"
      if i < 34:
        return "J"
      if i < 35:
        return "I"
      if i < 37:
        return "U"
      if i < 39:
        return "I"
      if i < 47:
        return "R"
  return "Something, not sure what, is wrong with the assembly instructions"

def find_funct7(inst_name): 
  '''
  finds the funct7 number 
  funct7 only exists for R type instructions
  '''
  funct7 = None
  if inst_name in ["sub", "sra"]:
    funct7 = "0100000" # 0x20
  elif inst_name in ["mul", "mulh", "mulsu", "mulu", "div", "divu", "rem", "remu"]:
    funct7 = "0000001" # 0x01
  else:
    funct7 = "0000000" # 0x00
  
  assert funct7 != None, "Unchecked case in funct7"
  
  return funct7

def find_funct3(inst_type, inst_name):
  '''
  Find the funct3 number
  '''

  funct3 = None
  
  if inst_type == "R":
    if inst_name == "add":
      funct3 = "000"
    if inst_name == "sub":
      funct3 = "000"
    if inst_name == "xor":
      funct3 = "100"
    if inst_name == "or":
      funct3 = "110"
    if inst_name == "and":
      funct3 = "111"
    if inst_name == "sll":
      funct3 = "001"
    if inst_name == "srl":
      funct3 = "101"
    if inst_name == "sra":
      funct3 = "101"
    if inst_name == "slt":
      funct3 = "010"
    if inst_name == "sltu":
      funct3 = "011"
    if inst_name == "mul":
      funct3 = "000"
    if inst_name == "mulh":
      funct3 = "001"
    if inst_name == "mulsu":
      funct3 = "010"
    if inst_name == "mulu":
      funct3 = "011"
    if inst_name == "div":
      funct3 = "100"
    if inst_name == "divu":
      funct3 = "101"
    if inst_name == "rem":
      funct3 = "110"
    if inst_name == "remu":
      funct3 = "111"

  if inst_type == "I":
    if inst_name == "addi":
      funct3 = "000"
    if inst_name == "xori":
      funct3 = "100"
    if inst_name == "ori":
      funct3 = "110"
    if inst_name == "andi":
      funct3 = "111"
    if inst_name == "slli":
      funct3 = "001"
    if inst_name == "srli":
      funct3 = "101"
    if inst_name == "srai":
      funct3 = "101"
    if inst_name == "slti":
      funct3 = "010"
    if inst_name == "sltiu":
      funct3 = "011"
    
    if inst_name == "lb":
      funct3 = "000"
    if inst_name == "lh":
      funct3 = "001"
    if inst_name == "lw":
      funct3 = "010"
    if inst_name == "lbu":
      funct3 = "100"
    if inst_name == "lhu":
      funct3 = "101"
    
    if inst_name == "jalr":
      funct3 = "000"

  if inst_type == "S":
    if inst_name == "sb":
      funct3 = "000"
    if inst_name == "sh":
      funct3 = "001"
    if inst_name == "sw":
      funct3 = "010"
  
  if inst_type == "B":
    if inst_name == "beq":
      funct3 = "000"
    if inst_name == "bne":
      funct3 = "001"
    if inst_name == "blt":
      funct3 = "100"
    if inst_name == "bge":
      funct3 = "101"
    if inst_name == "bltu":
      funct3 = "110"
    if inst_name == "bgeu":
      funct3 = "111"

  assert funct3 != None, "there's an unchecked case in funct3"

  return funct3
  

def find_opcode(inst_type, inst_name):
  opcode = None
  if inst_type == "R":
    opcode = "0110011"

  if inst_type == "I":
    if inst_name in ["lb", "lh", "lw", "lbu", "lhu"]:
      opcode = "0000011"
    else:
      opcode = "0010011"
  
  if inst_type == "S":
    opcode = "0100011"
  
  if inst_type == "B":
    opcode = "1100011"
  
  if inst_type == "J":
    opcode = "1101111"
  
  if inst_type == "U":
    if inst_name == "lui":
      opcode = "0110111"
    else:
      opcode = "0010111"

  assert opcode != None, "There's an unchecked case in opcode"

  return opcode

def find_imm(inst_type, inst_components):
  imm = None

  if inst_type == "I":
    inst_name = inst_components[0]
    if inst_name in ["lb", "lh", "lw", "lbu", "lhu"]:
      imm = inst_components[2]
    else:
      imm = inst_components[3]

  if inst_type == "S":
    imm = inst_components[2]
  
  if inst_type == "B":
    imm = inst_components[3]

  if inst_type == "J":
    imm = inst_components[2]
  
  if inst_type == "U":
    imm = inst_components[2]
  
  assert imm != None, "There's an unchecked case in imm"

  return dtb_imm(imm)

def sanitize_inst(inst_type, inst_components):
  '''
  Sanitizes instruction (get rid of commas, spaces, etc.)
  Extracts values from parantheses
  '''
  sanitized_inst = []
  if inst_type == "R": # add a1, a1, a2 -> [add, a1, a1, a2]
    for i in range(len(inst_components)):
      if i == 1 or i == 2:
        sanitized_inst.append(inst_components[i][:-1].strip()) # get rid of trailing comma
      else:
        sanitized_inst.append(inst_components[i].strip())
  
  if inst_type == "I":
    inst_name = inst_components[0]
    if inst_name in ["lb", "lh", "lw", "lbu", "lhu"]: # lw a1 40(x0) -> [lw, a1, 40, x0]
      for i in range(len(inst_components)):
        if i == 1:
          sanitized_inst.append(inst_components[i][:-1].strip())
        elif i == 2:
          offset_rs1 = inst_components[2].split("(")
          sanitized_inst.append(offset_rs1[0].strip())
          sanitized_inst.append(offset_rs1[1][:-1].strip()) # get rid of parantheses
        else:
          sanitized_inst.append(inst_components[i].strip())
    else: # addi a1, a1, 6 -> [addi, a1, a1, 6]
      for i in range(len(inst_components)):
        if i == 1 or i == 2:
          sanitized_inst.append(inst_components[i][:-1].strip()) # get rid of trailing comma
        else:
          sanitized_inst.append(inst_components[i].strip())
  
  if inst_type == "S": # sw a2, 40(a1) -> [sw, a2, 40, a1]
    for i in range(len(inst_components)):
      if i == 1:
        sanitized_inst.append(inst_components[i][:-1].strip())
      elif i == 2:
        offset_rs1 = inst_components[2].split("(")
        sanitized_inst.append(offset_rs1[0].strip())
        sanitized_inst.append(offset_rs1[1][:-1].strip()) # get rid of parantheses
      else:
        sanitized_inst.append(inst_components[i].strip())
  
  if inst_type == "B": # beq a1, a2, 40 -> [beq, a1, a2, 40]
    for i in range(len(inst_components)):
      if i == 1 or i == 2:
        sanitized_inst.append(inst_components[i][:-1].strip()) # get rid of trailing comma
      else:
        sanitized_inst.append(inst_components[i].strip())
  
  if inst_type == "J": # jal a1, 40 -> [jal, a1, 40]
    for i in range(len(inst_components)):
      if i == 1:
        sanitized_inst.append(inst_components[i][:-1].strip()) # get rid of trailing comma
      else:
        sanitized_inst.append(inst_components[i].strip())
  
  if inst_type == "U": # lui a1, 44 -> [lui, a1, 44]
    for i in range(len(inst_components)):
      if i == 1:
        sanitized_inst.append(inst_components[i][:-1].strip()) # get rid of trailing comma
      else:
        sanitized_inst.append(inst_components[i].strip())
  

  assert len(sanitized_inst) == 3 or len(sanitized_inst) == 4, "Either your instruction: " + str(inst_components[0]) + " is wrong or sanitize_inst is implemented wrong"

  return sanitized_inst

################################

assembly_file = sys.argv[1]
f = open(assembly_file, "r")

inst_arr = [line.strip() for line in f if len(line.strip())]

f.close()
if os.path.isfile("data/inst.mem"):
  os.remove("data/inst.mem")

f = open("data/inst.mem", "w")

for inst in inst_arr:
  inst_components = inst.split(" ")
  assert len(inst_components) == 3 or len(inst_components) == 4, "Instruction: " + str(inst) + " is written improperly"

  inst_name = inst_components[0]

  assert inst_name in inst_names, inst_name + " is not supported"

  inst_type = find_type(inst_name)
  sanitized_inst = sanitize_inst(inst_type, inst_components)

  if inst_type == "R":
    funct7 = find_funct7(inst_name)
    um_rs2, um_rs1, um_rd = sanitized_inst[3], sanitized_inst[2], sanitized_inst[1] # unampped rs2, rs1, rd
    rs2, rs1, rd = register_map(um_rs2), register_map(um_rs1), register_map(um_rd)
    funct3 = find_funct3(inst_type, inst_name)
    opcode = find_opcode(inst_type, inst_name)

    final_inst = R_type(funct7, rs2, rs1, funct3, rd, opcode)
  
  if inst_type == "I":
    imm = find_imm(inst_type, sanitized_inst)
    if inst_name in ["lb", "lh", "lw", "lbu", "lhu"]:
      um_rs1, um_rd = sanitized_inst[3], sanitized_inst[1]
    else:
      um_rs1, um_rd = sanitized_inst[2], sanitized_inst[1]
    rs1, rd = register_map(um_rs1), register_map(um_rd)
    funct3 = find_funct3(inst_type, inst_name)
    opcode = find_opcode(inst_type, inst_name)

    final_inst = I_type(imm, rs1, funct3, rd, opcode)
  
  if inst_type == "S":
    imm = find_imm(inst_type, sanitized_inst)
    um_rs2, um_rs1 = sanitized_inst[1], sanitized_inst[3]
    rs2, rs1 = register_map(um_rs2), register_map(um_rs1)
    funct3 = find_funct3(inst_type, inst_name)
    opcode = find_opcode(inst_type, inst_name)
    
    final_inst = S_type(imm, rs2, rs1, funct3, opcode)
  
  if inst_type == "B":
    imm = find_imm(inst_type, sanitized_inst)
    um_rs2, um_rs1 = sanitized_inst[2], sanitized_inst[1]
    rs2, rs1 = register_map(um_rs2), register_map(um_rs1)
    funct3 = find_funct3(inst_type, inst_name)
    opcode = find_opcode(inst_type, inst_name)

    final_inst = B_type(imm, rs2, rs1, funct3, opcode)
  
  if inst_type == "J":
    imm = find_imm(inst_type, sanitized_inst)
    um_rd = sanitized_inst[1]
    rd = register_map(um_rd)
    opcode = find_opcode(inst_type, inst_name)

    final_inst = J_type(imm, rd, opcode)
  
  if inst_type == "U":
    imm = find_imm(inst_type, sanitized_inst)
    um_rd = sanitized_inst[1]
    rd = register_map(um_rd)
    opcode = find_opcode(inst_type, inst_name)

    final_inst = U_type(imm, rd, opcode)


  
  f.write(convert_to_hex(final_inst) + "\n")
f.write("00000000" + "\n")
f.write("00000000" + "\n")
f.write("00000000")
f.close() 
