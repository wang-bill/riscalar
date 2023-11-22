`ifndef MY_GUARD
`define MY_GUARD
typedef enum {OP, OPIMM, BRANCH, LUI, JAL, JALR, LOAD, STORE, AUIPC, NOP} IType; //9 ITypes
typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra, NoAlu} AluFunc; //10 AluFuncs
typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu, Dbr} BrFunc; //7 BrFuncs
`endif // MY_GUARD
