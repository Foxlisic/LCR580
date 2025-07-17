`timescale 10ns / 1ns
module tb;
// ---------------------------------------------------------------------
reg         clock, clock_25, reset_n;
always #0.5 clock       = ~clock;
always #2.0 clock_25    = ~clock_25;
// ---------------------------------------------------------------------
initial begin reset_n = 0; clock = 0; clock_25 = 0; #3.0 reset_n = 1; #2500 $finish; end
initial begin $dumpfile("tb.vcd"); $dumpvars(0, tb); end
initial begin $readmemh("tb.hex", mem, 0); end
// ---------------------------------------------------------------------
reg  [ 7:0] mem[65536]; always @(posedge clock) if (w) mem[a] <= o;
// ---------------------------------------------------------------------
wire [15:0] a;
wire [ 7:0] i = mem[a];
wire [ 7:0] pin;
wire [ 7:0] o;
wire        w, pr, pw;
wire        iff1, irq;
wire [ 3:0] vect;
wire [ 2:0] border;
wire [ 7:0] kdata;
wire        kdone;
// ---------------------------------------------------------------------
LCR580 cpu
(
    .clock      (clock_25),
    .reset_n    (reset_n),
    .ce         (1'b1),
    .m0         (m0),
    .address    (a),
    .in         (i),
    .out        (o),
    .we         (w),
    .irq        (irq),
    .iff1       (iff1),
    .vect       (vect),
    .port_in    (pin),
    .port_rd    (pr),
    .port_we    (pw)
);
// ---------------------------------------------------------------------
io IO
(
    .clock      (clock_25),
    .reset_n    (reset_n),
    .address    (a),
    .out        (o),
    .irq        (irq),
    .iff1       (iff1),
    .vect       (vect),
    .pin        (pin),
    .kdone      (kdone),
    .kdata      (kdata),
    .port_rd    (port_rd),
    .port_we    (port_we),
    .border     (border)
);

endmodule
