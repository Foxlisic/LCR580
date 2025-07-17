module de0
(
      // Reset
      input              RESET_N,

      // Clocks
      input              CLOCK_50,
      input              CLOCK2_50,
      input              CLOCK3_50,
      inout              CLOCK4_50,

      // DRAM
      output             DRAM_CS,
      output             DRAM_CKE,
      output             DRAM_CLK,
      output      [12:0] DRAM_A,
      output      [1:0]  DRAM_B,
      inout       [15:0] DRAM_DQ,
      output             DRAM_CAS,
      output             DRAM_RAS,
      output             DRAM_W,
      output             DRAM_L,
      output             DRAM_U,

      // GPIO
      inout       [35:0] GPIO_0,
      inout       [35:0] GPIO_1,

      // 7-Segment LED
      output      [6:0]  HEX0,
      output      [6:0]  HEX1,
      output      [6:0]  HEX2,
      output      [6:0]  HEX3,
      output      [6:0]  HEX4,
      output      [6:0]  HEX5,

      // Keys
      input       [3:0]  KEY,

      // LED
      output reg  [9:0]  LEDR,

      // PS/2
      inout              PS2_CLK,
      inout              PS2_DAT,
      inout              PS2_CLK2,
      inout              PS2_DAT2,

      // SD-Card
      output             SD_CLK,
      inout              SD_CMD,
      inout       [3:0]  SD_DATA,

      // Switch
      input       [9:0]  SW,

      // VGA
      output      [3:0]  VGA_R,
      output      [3:0]  VGA_G,
      output      [3:0]  VGA_B,
      output             VGA_HS,
      output             VGA_VS
);

// High-Impendance-State
assign DRAM_DQ = 16'hzzzz;
assign GPIO_0  = 36'hzzzzzzzz;
assign GPIO_1  = 36'hzzzzzzzz;

// LED OFF
assign HEX0 = 7'b1111111;
assign HEX1 = 7'b1111111;
assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;

// ФРЕНКИ нарезался в провода и лежит бухой под забором как козёл %)
// ---------------------------------------------------------------------

// Процессор
wire [15:0] a;
wire [ 7:0] o;
wire [ 7:0] i;
wire        w;

// Порты и прерывания
wire        irq, iff1;
wire [ 7:0] pin;
wire [ 3:0] vect;
wire        port_we, port_rd;

// Адаптер
wire [12:0] vga_a;
wire [ 7:0] vga_i;
wire [ 2:0] border;

// Клавиатура
wire [ 7:0] kdata, kbd;
wire        hit, kdone;
wire        vretrace;

// Тактовый генератор
// ---------------------------------------------------------------------
wire clock_25, clock_50, clock_75, clock_100, clock_106;

pll u0
(
    // Источник тактирования
    .clkin (CLOCK_50),

    // Производные частоты
    .m25    (clock_25),
    .m50    (clock_50),
    .m75    (clock_75),
    .m100   (clock_100),
    .m106   (clock_106),
    .locked (reset_n)
);

// Порты ввода и вывода
// -----------------------------------------------------------------------------

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
    .vretrace   (vretrace),
    .port_rd    (port_rd),
    .port_we    (port_we),
    .border     (border),
);

// Процессор
// -----------------------------------------------------------------------------

LCR580 cpu
(
    // --- Управление
    .clock      (clock_25),
    .reset_n    (reset_n),
    .ce         (1'b1),
    .m0         (m0),
    // --- Память
    .address    (a),
    .in         (i),
    .out        (o),
    .we         (w),
    // --- Порты
    .port_in    (pin),
    .port_rd    (port_rd),
    .port_we    (port_we),
    // --- Прерывания
    .irq        (irq),
    .vect       (vect),
    .iff1       (iff1)
);

// Видеоадаптеры
// -----------------------------------------------------------------------------

vga UVGA
(
    .clock      (clock_25),
    .r          (VGA_R[3]),
    .g          (VGA_G[3]),
    .b          (VGA_B[3]),
    .hs         (VGA_HS),
    .vs         (VGA_VS),
    .a          (vga_a),
    .i          (vga_i),
    .border     (border),
    .vretrace   (vretrace)
);

// Блоки оперативной памяти 64K
// -----------------------------------------------------------------------------

m64 M64
(
    .clock      (clock_100),
    // Процессор
    .a          (a),
    .q          (i),
    .d          (o),
    .w          (w),
    // Видеоданные
    .ax         ({3'b010, vga_a[12:0]}),
    .qx         (vga_i)
);

// Клавиатура
// -----------------------------------------------------------------------------
keyboard K1
(
    .clock      (clock_25),
    .reset_n    (reset_n),
    .ps_clk     (PS2_CLK),
    .ps_dat     (PS2_DAT),
    .hit        (hit),
    .kbd        (kbd),
    .kdone      (kdone),
    .ascii      (kdata),
);

endmodule

`include "../lcr580.v"
`include "../keyboard.v"
`include "../io.v"
`include "../vga.v"
