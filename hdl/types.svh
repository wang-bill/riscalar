typedef enum {OP, OPIMM, BRANCH, LUI, JAL, JALR, LOAD, STORE, AUIPC} IType; //9 ITypes
typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc; //10 AluFuncs
typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu, Dbr} BrFunc;