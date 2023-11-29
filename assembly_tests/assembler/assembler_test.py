f = open("inst.mem", "r")
g = open("output.txt", "r")
sol = [line.strip() for line in g ]

program = [line.strip() for line in f]

print(sol)
print("2r3ewffewafewfewafewaewafewewa")
print(program)
for i in range(len(sol)):
  assert sol[i] == program[i], "difference at line " + str(i+1)
