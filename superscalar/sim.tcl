create_project -force -part  xc7s50csga324-1 ip_tb ip_tb

read_verilog -sv [ glob ./hdl/types.svh]
read_verilog -sv [ glob ./hdl/multiplier.sv ]
read_verilog  [ glob ./hdl/*.v ]
#read_mem [ glob ./data/*.mem ]
read_verilog -sv [ glob ./sim/multiplier_tb.sv ]

read_ip ./ip/mult_gen_0/mult_gen_0.xci
read_ip ./ip/mult_gen_1/mult_gen_1.xci
generate_target all [get_ips]
synth_ip [get_ips]

set_property top multiplier_tb [get_fileset sim_1]
synth_design -top multiplier_tb
launch_simulation
restart
open_vcd
log_vcd *
run all
flush_vcd
close_vcd
