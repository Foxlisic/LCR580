/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off CASEX */
/* verilator lint_off CASEOVERLAP */
/* verilator lint_off CASEINCOMPLETE */

module LCR580
(
    input               clock,
    input               reset_n,
    input               ce,
    output              m0,
    output      [15:0]  address,        // Адрес в памяти или порт
    input       [ 7:0]  in,
    output reg  [ 7:0]  out,
    output reg          we,
    // Регистры
    output reg  [15:0]  bc,
    output reg  [15:0]  de,
    output reg  [15:0]  hl,
    output reg  [15:0]  sp,
    output      [15:0]  af,
    // -----------------------
    input       [ 7:0]  port_in,        // Данные из порта
    output reg          port_rd,        // Сигнал на чтени из порта
    output reg          port_we,        // Сигнал на запись в порт
    output reg          iff1            // Разрешение прерываний
);
// ---------------------------------------------------------------------
`define TERM begin sw <= 0; t <= 0; end
// ---------------------------------------------------------------------
assign address = sw ? cp : pc;
assign m0 = (t == 0);
assign af = {a, psw};
// ---------------------------------------------------------------------
localparam
    CF  = 0, PF  = 2, HF  = 4, ZF  = 6, SF  = 7,
    ADD = 0, ADC = 1, SUB = 2, SBB = 3, AND = 4,
    XOR = 5, OR  = 6, CMP = 7;
// ---------------------------------------------------------------------
reg [15:0]  pc;
reg [ 7:0]  a   = 8'h09,
            //       NZ H P C
            psw = 8'b00000011;
// ---------------------------------------------------------------------
reg         sw;         // =1 Адрес указывает на CP, иначе =0 PC
reg [15:0]  cp;         // Адрес для считывания данных из памяти
reg [ 7:0]  opcode;     // Сохраненный опкод
reg [ 4:0]  t;          // Исполняемый такт опкода [0..31]
// ---------------------------------------------------------------------
reg         b;          // =1 Запись d в 8-битный регистр n
reg         w;          // =1 Запись d в 16-битный регистр n
reg         x;          // Ex DE,HL
reg [16:0]  d;          // Данные
reg [ 2:0]  n;          // Номер регистра для записи
// Выбор 8/16-битного регистров
// ---------------------------------------------------------------------
wire [15:0] r16 =
    opc[5:4] == 2'b00 ? bc :
    opc[5:4] == 2'b01 ? de :
    opc[5:4] == 2'b10 ? hl : sp;
// ---------------------------------------------------------------------
wire [ 7:0] op53 =
    opc[5:3] == 3'b000 ? bc[15:8] : opc[5:3] == 3'b001 ? bc[ 7:0] :
    opc[5:3] == 3'b010 ? de[15:8] : opc[5:3] == 3'b011 ? de[ 7:0] :
    opc[5:3] == 3'b100 ? hl[15:8] : opc[5:3] == 3'b101 ? hl[ 7:0] :
    opc[5:3] == 3'b110 ? in       : a;
// ---------------------------------------------------------------------
wire [ 7:0] op20 =
    opc[2:0] == 3'b000 ? bc[15:8] : opc[2:0] == 3'b001 ? bc[ 7:0] :
    opc[2:0] == 3'b010 ? de[15:8] : opc[2:0] == 3'b011 ? de[ 7:0] :
    opc[2:0] == 3'b100 ? hl[15:8] : opc[2:0] == 3'b101 ? hl[ 7:0] :
    opc[2:0] == 3'b110 ? in       : a;
// ---------------------------------------------------------------------
wire [ 7:0] opc = t ? opcode : in;
wire [15:0] pcn  = pc + 1;
wire [15:0] cpn  = cp + 1;
wire        m53  = opc[5:3] == 3'b110;
wire        m20  = opc[2:0] == 3'b110;
wire [15:0] sign = {{8{in[7]}}, in[7:0]};
wire [3:0]  cond = {psw[SF], psw[PF], psw[CF], psw[ZF]};
wire        cc   = (cond[{1'b0,opc[4]}] == opc[3]);
wire        ccc  = (cond[opc[5:4]]      == opc[3]) || (opc == 8'hC9) || (opc == 8'hCD);
wire        cmp  = (opc[5:3] != CMP);
// ---------------------------------------------------------------------
wire [8:0]  alur =
    opc[5:3] == ADD ? a + op20 :             // ADD
    opc[5:3] == ADC ? a + op20 + psw[CF] :   // ADC
    opc[5:3] == SBB ? a - op20 - psw[CF] :   // SBB
    opc[5:3] == AND ? a & op20 :             // ANA
    opc[5:3] == XOR ? a ^ op20 :             // XRA
    opc[5:3] == OR  ? a | op20 :             // ORA
                      a - op20;              // SUB|CMP

wire sf =   alur[7];
wire zf =   alur[7:0] == 0;
wire hf =   a[4] ^ op20[4] ^ alur[4];
wire ha =  (a[4] | op20[4]) & (opc[5:3] == AND);
wire pf = ~^alur[7:0];
wire cf =   alur[8];

wire [7:0] aluf =
    opc[5:3] == AND || opc[5:3] == XOR || opc[5:3] == OR ?
        {sf, zf, 1'b0, ha, 1'b0, pf, 1'b1, 1'b0} : // AND, XOR, OR
        {sf, zf, 1'b0, hf, 1'b0, pf, 1'b1,   cf};  // ADD, ADC, SUB, SBB, CMP

// Инкремент и декремент NZ H P C
// ----------------------------------------------------------------------
wire [7:0] idsrc = m53 ? in : op53;
wire [7:0] idres = opc[0] ? idsrc - 1 : idsrc + 1;
wire [7:0] idpsw = {
    idres[7],       // N
    idres == 0,     // Z
    psw[5:3],       // 5,H,3
    ~^d[7:0],       // P
    1'b0,           // 1
    idres == {4{opc[0]}} // 0,F
};
// ----------------------------------------------------------------------
wire daa1 = psw[HF] || a[3:0] > 9;
wire daa2 = psw[CF] || a[7:4] > 9 || (a[7:4] >= 9 && a[3:0] > 9);
wire [ 7:0] daa   = a + (daa1 ? 6 : 0) + (daa2 ? 8'h60 : 0);
wire [16:0] addhl = hl + r16;
// ----------------------------------------------------------------------

always @(posedge clock)
if (reset_n == 0) begin
    t   <= 0;           // Установить чтение кода на начало
    d   <= 0;
    we  <= 0;
    cp  <= 0;
    sw  <= 0;           // Позиционировать память к PC
    pc  <= 16'h0000;    // Указатель на СТАРТ
    psw <= 8'b00000001;
    opcode <= 0;
    iff1 <= 0;          // Отключение прерываний
end
else if (ce) begin

    t  <= t + 1;        // Счетчик микрооперации
    x  <= 0;            // Ex DE,HL если =1
    b  <= 0;            // Выключить запись в регистр (по умолчанию) 8bit
    w  <= 0;            // Выключить запись в регистр (по умолчанию) 16bit
    we <= 0;            // Аналогично, выключить запись в память (по умолчанию)
    port_rd <= 0;       // Чтение из порта
    port_we <= 0;       // Запись в порт

    // Запись опкода на первом такте выполнения инструкции
    if (m0) begin opcode <= in; pc <= pcn; end

    // Исполнение инструкции
    casex (opc)

    // === ИНСТРУКЦИИ 00-3F ===
    8'b00000000: case (t) // 1T NOP

        0: begin `TERM; end

    endcase
    8'b00010000: case (t) // 1T+ DJNZ

        0: begin

            b <= 1;
            n <= 0;
            d <= bc[15:8] - 1;
            if (bc[15:8] == 1) begin `TERM; pc <= pc + 2; end

        end

        1: begin pc <= pcn + sign; `TERM; end

    endcase
    8'b00011000: case (t) // 2T JR *

        1: begin pc <= pcn + sign; `TERM; end

    endcase
    8'b001xx000: case (t) // 1T JR cc,*

        0: begin if (!cc) begin pc <= pc + 2; `TERM; end end
        1: begin pc <= pcn + sign; `TERM; end

    endcase
    8'b00xx0001: case (t) // 3T LD R16,**

        1: begin pc <= pcn; d[ 7:0] <= in; n <= opcode[5:4]; end
        2: begin pc <= pcn; d[15:8] <= in; w <= 1; `TERM; end

    endcase
    8'b00xx1001: case (t) // 1T ADD HL,R16

        0: begin d <= addhl; w <= 1; n <= 2; psw[CF] <= addhl[16]; `TERM; end

    endcase
    8'b000x0010: case (t) // 2T LD (BC|DE),A

        0: begin we <= 1; out <= a; cp <= r16; sw <= 1; end
        1: begin `TERM; end

    endcase
    8'b000x1010: case (t) // 2T LD A,(BC|DE)

        0: begin sw <= 1; cp <= r16; end
        1: begin b  <= 1; n <= 7; d <= in; `TERM; end

    endcase
    8'b00100010: case (t) // 5T LD (**),HL

        1: begin cp[ 7:0] <= in; pc <= pcn; end
        2: begin cp[15:8] <= in; pc <= pcn; sw <= 1;
                 we <= 1; out <= hl[ 7:0]; end
        3: begin we <= 1; out <= hl[15:8]; cp <= cpn; end
        4: begin `TERM; end

    endcase
    8'b00101010: case (t) // 5T LD HL,(**)

        1: begin cp[ 7:0] <= in; pc <= pcn; end
        2: begin cp[15:8] <= in; pc <= pcn; sw <= 1; end
        3: begin d [ 7:0] <= in; cp <= cpn; end
        4: begin d [15:8] <= in; w  <= 1; n <= 2; `TERM; end

    endcase
    8'b0011x010: case (t) // 4T LD A,(**) :: LD (**),A

        1: begin cp[ 7:0] <= in; pc <= pcn; end
        2: begin cp[15:8] <= in; pc <= pcn; sw <= 1; we <= ~opc[3]; out <= a; end
        3: begin d <= in; b <= opc[3]; n <= 7; `TERM; end

    endcase
    8'b00xxx011: case (t) // 1T INC|DEC R16

        0: begin w <= 1; n <= in[5:4]; d <= in[3] ? r16 - 1 : r16 + 1; `TERM; end

    endcase
    8'b0011010x: case (t) // 3T INC|DEC (M)

        0: begin sw <= 1; cp  <= hl; end
        1: begin we <= 1; psw <= idpsw; out <= idres; end
        2: begin `TERM; end

    endcase
    8'b00xxx10x: case (t) // 1T INC|DEC R8

        0: begin psw <= idpsw; d <= idres; n <= opc[5:3]; b <= 1; `TERM; end

    endcase
    8'b00xxx110: case (t) // 2T+ LD R,*

        1: begin

            pc  <= pcn;         // PC = PC + 1
            cp  <= hl;          // Указатель HL
            n   <= opc[5:3];    // Номер регистра
            b   <= !m53;        // Запись в регистр, если не M
            we  <= m53;         // Запись в память,  если M
            sw  <= m53;         // Активация указателя CP
            d   <= in;          // Данные для записи в регистр
            out <= in;          // Данные для записи в память

            if (!m53) `TERM;

        end
        2: begin `TERM; end

    endcase
    8'b000xx111: case (t) // 1T RLCA, RRCA, RLA, RRA

        0: begin

            b <= 1;
            n <= 7;

            case (opc[4:3])
            2'b00: d <= {a[6:0],  a[7]};    // RLCA
            2'b01: d <= {a[0],    a[7:1]};  // RRCA
            2'b10: d <= {a[6:0],  psw[CF]}; // RLA
            2'b11: d <= {psw[CF], a[7:1]};  // RRA
            endcase

            psw[CF] <= a[opc[3] ? 0 : 7];

            `TERM;

        end

    endcase
    8'b00100111: case (t) // 1T DAA

        0: begin

            psw[SF] <= d[7];
            psw[ZF] <= d[7:0] == 0;
            psw[HF] <= a[4] ^ daa[4];
            psw[PF] <= ~^d[7:0];
            psw[CF] <= daa2 | psw[0];

            d <= daa;
            b <= 1;
            n <= 7;
            `TERM;

        end

    endcase
    8'b00101111: case (t) // 1T CPL

        0: begin d <= ~a; b <= 1; n <= 7; `TERM; end

    endcase
    8'b0011x111: case (t) // 1T SCF, CCF

        0: begin psw[CF] <= opc[3] ? ~psw[CF] : 1'b1; `TERM; end

    endcase
    // === ИНСТРУКЦИИ 40-BF ===
    8'b01110110: case (t) // 1T HALT

        0: begin pc <= pc; `TERM; end

    endcase
    8'b01110xxx: case (t) // 2T LD (M),R

        0: begin sw <= 1; cp <= hl; out <= op20; we <= 1; end
        1: begin `TERM; end

    endcase
    8'b01xxx110: case (t) // 2T LD R,(M)

        0: begin sw <= 1; cp <= hl; end
        1: begin d  <= in; b <= 1; n <= opc[5:3]; `TERM; end

    endcase
    8'b01xxxxxx: case (t) // 1T LD R,R

        0: begin d <= op20; b <= 1; n <= opc[5:3]; `TERM; end

    endcase
    8'b10xxx110: case (t) // 2T ALU A,(M)

        0: begin cp <= hl;   sw <= 1; end
        1: begin d  <= alur; b <= cmp; n <= 7; psw <= aluf; `TERM; end

    endcase
    8'b10xxxxxx: case (t) // 1T [ALU] A,R

        0: begin d  <= alur; b <= cmp; n <= 7; psw <= aluf; `TERM; end

    endcase
    // === ИНСТРУКЦИИ С0-FF ===
    8'b11xxx000,
    8'b11001001: case (t) // 1/3T RET ccc

        0: if (ccc) begin

            sw <= ccc;
            w  <= ccc;
            n  <= 3;        // SP
            d  <= sp + 2;   // Запись в SP+2, если есть RET
            cp <= sp;

        end else `TERM
        1: begin d  <= in; cp <= cpn; end
        2: begin pc <= {in, d[7:0]}; `TERM; end

    endcase
    8'b11xx0001: case (t) // 3T POP

        0: begin cp <= sp;  d <= sp + 2; w <= 1; n <= 3; sw <= 1; end
        1: begin cp <= cpn; d <= in; end
        2: begin

            d[15:8] <= in;

            // POP AF
            if (opc[5:4] == 2'b11) begin

                d   <= in;
                psw <= d[ 7:0];
                b   <= 1;
                n   <= 7;

            end else begin

                n   <= opc[5:4];
                w   <= 1;

            end

            `TERM;

        end

    endcase
    8'b11101001: case (t) // 1T JP (HL)

        0: begin pc <= hl; `TERM; end

    endcase
    8'b11111001: case (t) // 1T LD SP, HL

        0: begin d <= hl; w <= 1; n <= 3; `TERM; end

    endcase
    8'b11xxx010,
    8'b11000011: case (t) // 1/3T JP ccc, **

        0: begin pc <= ccc ? pcn : pc+3; if (!ccc) `TERM; end
        1: begin pc <= pcn; cp <= in; end
        2: begin pc <= {in, cp[7:0]}; `TERM; end

    endcase
    8'b1111x011: case (t) // 1T DI, EI

        0: begin iff1 <= opc[3]; `TERM; end

    endcase
    8'b11010011: case (t) // 3T OUT (*), A

        1: begin sw <= 1; cp <= in; port_we <= 1; out <= a; pc <= pcn; end
        2: begin `TERM; end

    endcase
    8'b11011011: case (t) // 3T IN A, (*)

        1: begin sw <= 1; cp <= in; pc <= pcn; port_rd <= 1; end
        2: begin b  <= 1; n <= 7; d <= port_in; `TERM; end

    endcase
    8'b11100011: case (t) // 6T EX (SP),HL

        0: begin sw <= 1; cp <= sp; end
        1: begin d[ 7:0] <= in; cp <= cpn; end
        2: begin d[15:8] <= in; w  <= 1; n <= 2; cp <= hl; end
        3: begin we <= 1; out <= cp[7:0]; d[7:0] <= cp[15:8]; cp <= sp; end
        4: begin we <= 1; out <= d[7:0]; cp <= cpn; end
        5: begin `TERM; end

    endcase
    8'b11101011: case (t) // 4T EX DE,HL

        0: begin x <= 1; `TERM; end

    endcase
    8'b11xxx100,
    8'b11001101: case (t) // 1/5T CALL ccc

        0: begin pc <= ccc ? pcn : pc+3; if (!ccc) `TERM; end
        1: begin d[ 7:0] <= in; pc <= pcn; end
        2: begin d[15:8] <= in;
                 we <= 1; out <= pcn[ 7:0]; sw <= 1;   cp <= sp - 2; end
        3: begin we <= 1; out <= pcn[15:8]; cp <= cpn; pc <= d; end
        4: begin w  <= 1; n <= 3; d <= sp - 2; `TERM; end

    endcase
    8'b11xx0101: case (t) // 3T PUSH R16

        0: begin

            sw <= 1;
            we <= 1;
            cp <= sp - 2;
            d  <= sp - 2;
            w  <= 1;
            n  <= 3; // SP

            case (opc[5:4])
            2'b00: out <= bc[7:0];
            2'b01: out <= de[7:0];
            2'b10: out <= hl[7:0];
            2'b11: out <=  a;
            endcase

        end

        1: begin

            cp <= cpn;
            we <= 1;

            case (opc[5:4])
            2'b00: out <= bc[15:8];
            2'b01: out <= de[15:8];
            2'b10: out <= hl[15:8];
            2'b11: out <= (psw & 8'b11010101) | 2'b10;
            endcase

        end

        2: begin `TERM; end

    endcase
    8'b11xxx110: case (t) // 2T [ALU] Imm

        1: begin d <= alur; pc <= pcn; b <= cmp; n <= 7; psw <= aluf; `TERM; end

    endcase
    8'b11xxx111: case (t) // 4T RST #

        1: begin we <= 1; d <= sp - 2; n <= 3; w <= 1; cp <= sp - 2; sw <= 1; out <= pc[7:0]; end
        2: begin we <= 1; out <= pc[15:8]; cp <= cpn; pc <= {opc[5:3], 3'b000}; end
        3: begin `TERM; end

    endcase

    endcase

end

// Запись данных в регистры
always @(negedge clock)
if (reset_n == 0) begin
    bc <= 16'hAF02;
    de <= 16'h0000;
    hl <= 16'h0000;
    sp <= 16'h0000;
end
else if (ce) begin

    // Ex DE,HL
    if (x) begin de <= hl; hl <= de; end

    // 8-bit
    if (b)
    case (n)
    0: bc[15:8] <= d[7:0]; 1: bc[ 7:0] <= d[7:0]; // BC
    2: de[15:8] <= d[7:0]; 3: de[ 7:0] <= d[7:0]; // DE
    4: hl[15:8] <= d[7:0]; 5: hl[ 7:0] <= d[7:0]; // HL
    7:  a       <= d[7:0];
    endcase

    // 16-bit
    if (w)
    case (n)
    2'b00: bc <= d[15:0];
    2'b01: de <= d[15:0];
    2'b10: hl <= d[15:0];
    2'b11: sp <= d[15:0];
    endcase

end

endmodule
