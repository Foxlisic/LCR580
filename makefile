VLIB="/usr/share/verilator/include"
ILIB=$(VLIB)/verilated_threads.cpp $(VLIB)/verilated.cpp obj_dir/Vlcr580__ALL.a

all: ica # app
ica:
	iverilog -g2005-sv -DICARUS=1 -o tb.qqq tb.v lcr580.v io.v
	vvp tb.qqq >> /dev/null
	rm tb.qqq
app: syn
	g++ -Ofast -Wno-unused-result -o lcr580 -I$(VLIB) main.cc -lSDL2 $(ILIB)
	./lcr580
syn:
	verilator --threads 1 -cc lcr580.v > /dev/null
	cd obj_dir && make -f Vlcr580.mk > /dev/null
vcd:
	gtkwave tb.vcd
wav:
	gtkwave tb.gtkw
