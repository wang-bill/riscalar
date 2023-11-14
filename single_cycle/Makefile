test: branchAlu decode

branchAlu: # BRANCH ALU TEST
	echo "=========== BRANCH AND ALU TEST =========="
	if [ -f "foo.out" ]; then \
		rm foo.out; \
	fi
	iverilog -g2012 -o foo.out sim/branchAlu_tb.sv hdl/* > /dev/null 2>&1
	vvp foo.out
	echo "=========== BRANCH AND ALU TEST =========="
	echo ""

decode: # DECODE TEST
	echo "=========== DECODE TEST =========="
	if [ -f "foo.out" ]; then \
		rm foo.out; \
	fi
	iverilog -g2012 -o foo.out sim/id_1_tb.sv hdl/* > /dev/null 2>&1
	vvp foo.out
	echo "=========== DECODE TEST =========="
	echo ""

test3: 