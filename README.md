### RISC-V Superscalar Processor

TODO:
 - Cross-module test cases
 - Memory access
 - Superscalar

November 10th: Finish single-cycle and pipelined processor, start implementing superscalar
November 17th: Finish superscalar
November 24th: Implement Branch Prediction + Speculative Execution; Finish setting up read/write to SD Card
December 1st: SD Card Flashing + Caches
December 8th: Benchmarking, Begin writing final report (½ done)
December 12th (Due December 14th): Finish final report

Next Steps (Catherine):
Integrate the instruction memory into the processor (how should we load the memory with instructions?)\n

Pipeline the processor (I anticipate this will be more of a challenge than we expect logistically); we might need to add depth to the registers for the pc for example to calculate on multiple pc values at a time...?\n

Questions for OH:

How do we handle branches?

ALU as a functional unit?

How to resolve common data bus sharing issue?

Is it a good idea to group all RS into one 3D array?

TODO: 
- Superscalar: Ask above questions in OH
- Single Cycle: Copy the processor.sv into this top_level and integrate together for single cycle processor testbench
- Pipeline: Make sure changes are consistent and test with testbenches

BRAM Read Delay
- BRAM Reads take two clock cycles, can we change from High perforamnce -> low latency to reduce to one clock cycle?
- Should we implement a cache to store instruction reads?

Common Data Bus
- Should we expand the width or should we add a buffer of some sort?
- Should we make a wider bus?

Issues Detected:
- Solving stopping the BRAM once we read end of file
- Issues with gtkwave having an off-by-one clock cycle issue/slightly strange results

11/25
- Single Cycle: Resolve load/store + branching issues (4/5 clock cycles)
- Pipeline: Set up load/stores + branching, resolve multi-cycle bram read/writes
- Begin implementing Superscalar (9:00)

11/29 TA Discussion:
- genvar for loop with "break" condition
- how to create write-first bram memory