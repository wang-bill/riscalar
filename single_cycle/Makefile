test: branchAlu decode processor clean

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

processor: # PROCESSOR TEST
	echo "========== PROCESSOR TEST =========="
	if [ -f "foo.out" ]; then \
		rm foo.out; \
	fi
	python3 sim/assembler.py sim/addtest.s

	iverilog -g2012 -o foo.out sim/processor1_tb.sv hdl/* > /dev/null 2>&1
	vvp foo.out
	echo "=========== PROCESSOR TEST =========="
	echo ""

clean: # CLEAN UP FILES CREATED DURING TESTING
	rm *.out
	if [ -f *.vcd ]; then \
		rm *.vcd; \
	fi

test3: 