module c4
(
    input               RESET_N,
    input               CLOCK,          // 50 MHZ
    input      [3:0]    KEY,
    output     [3:0]    LED,
    output              BUZZ,           // Пищалка
    input               RX,             // Прием
    output              TX,             // Отправка
    output              SCL,            // Температурный сенсор :: LM75
    inout               SDA,
    output              I2C_SCL,        // Память 1Кб :: AT24C08
    inout               I2C_SDA,
    output              PS2_CLK,
    inout               PS2_DAT,
    input               IR,             // Инфракрасный приемник
    output              VGA_R,
    output              VGA_G,
    output              VGA_B,
    output              VGA_HS,
    output              VGA_VS,
    output  [ 3:0]      DIG,            // 4x8 Семисегментный
    output  [ 7:0]      SEG,
    inout   [ 7:0]      LCD_D,          // LCD экран
    output              LCD_E,
    output              LCD_RW,
    output              LCD_RS,
    inout   [15:0]      SDRAM_DQ,
    output  [11:0]      SDRAM_A,        // Адрес
    output  [ 1:0]      SDRAM_B,        // Банк
    output              SDRAM_RAS,      // Строка
    output              SDRAM_CAS,      // Столбце
    output              SDRAM_WE,       // Разрешение записи
    output              SDRAM_L,        // LDQM
    output              SDRAM_U,        // UDQM
    output              SDRAM_CKE,      // Активация тактов
    output              SDRAM_CLK,      // Такты
    output              SDRAM_CS        // Выбор чипа (=0)
);

assign BUZZ = 1'b1;
assign DIG  = 4'b1111;
assign LED  = 4'b1111;

// -----------------------------------------------------------------------------
wire clock_25, clock_100, reset_n;

pll UPLL
(
    .clock      (CLOCK),
    .c0         (clock_25),
    .c1         (clock_100),
    .locked     (reset_n)
);

// Провода
// -----------------------------------------------------------------------------

// Процессор
wire [15:0] a;
wire [ 7:0] o;
wire        w, port_we, port_rd, iff1;
reg [7:0]   pin;

// Адаптер
wire [12:0] vga_a;
wire [ 7:0] vga_i;
reg  [ 2:0] border;

// Клавиатура
wire [7:0]  ascii;
wire        kdone, hit;
reg [7:0]   keyb;
reg         irq_keyb_p;
reg         irq_keyb_n;
wire        irq_keyb = irq_keyb_p ^ irq_keyb_n;

// Источники памяти
wire m32a = a  < 16'h8000;
wire m8a  = a >= 16'h8000 && a < 16'hA000;

wire [ 7:0] m32_i, m8_i;
wire [ 7:0] i = m32a ? m32_i : (m8a  ? m8_i : 8'hFF);

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
    .iff1       (iff1)
);

// Видеоадаптеры
// -----------------------------------------------------------------------------

vga UVGA
(
    .clock      (clock_25),
    .r          (VGA_R),
    .g          (VGA_G),
    .b          (VGA_B),
    .hs         (VGA_HS),
    .vs         (VGA_VS),
    .a          (vga_a),
    .i          (vga_i),
    .border     (border)
);

// Блоки оперативной памяти 32+8+4+2
// -----------------------------------------------------------------------------

m32 M32
(
    .clock      (clock_100),
    .a          (a[14:0]),
    .q          (m32_i),
    .d          (o),
    .w          (w & m32a),
    .ax         ({2'b10, vga_a}),
    .qx         (vga_i)
);

m8 M8
(
    .clock      (clock_100),
    .a          (a[12:0]),
    .q          (m8_i),
    .d          (o),
    .w          (w & m8a)
);

// Периферия
// -----------------------------------------------------------------------------

keyboard K1
(
    .clock      (clock_25),
    .reset_n    (reset_n),
    .ps_clk     (PS2_CLK),
    .ps_dat     (PS2_DAT),
    .hit        (hit),
    .ascii      (ascii),
    .kdone      (kdone)
);

endmodule

`include "../lcr580.v"
`include "../keyboard.v"
`include "../vga.v"
