module vga
(
    input               clock,
    output  reg         r,
    output  reg         g,
    output  reg         b,
    output              hs,
    output              vs,
    output  reg [12:0]  a,
    input       [ 7:0]  i,
    input       [ 2:0]  border
);

// ---------------------------------------------------------------------
// Тайминги для горизонтальной и вертикальной развертки
parameter
//  Visible     Front       Sync        Back        Whole
    hzv =  640, hzf =   16, hzs =   96, hzb =   48, hzw =  800,
    vtv =  400, vtf =   12, vts =    2, vtb =   35, vtw =  449;
// ---------------------------------------------------------------------
assign hs = x < (hzb + hzv + hzf);
assign vs = y < (vtb + vtv + vtf);
// ---------------------------------------------------------------------
reg  [ 9:0] x = 0;
reg  [ 9:0] y = 0;
reg  [ 7:0] t,c,m;
wire [ 9:0] xc = x - hzb;
wire [ 9:0] yc = y - vtb;
wire [ 8:0] xa = x - hzb - 64;
wire [ 8:0] ya = y - vtb - 8;
// ---------------------------------------------------------------------
wire xmax  = (x == hzw - 1);
wire ymax  = (y == vtw - 1);
wire show  = (x >= hzb && x < hzb + hzv) && (y >= vtb && y < vtb + vtv);
wire paper = (xc >= 64 && yc >= 8 && xc < 576 && yc < 392);
// ---------------------------------------------------------------------
wire mb    = m[~xa[3:1]];
// ---------------------------------------------------------------------

always @(posedge clock) begin

    // Черный цвет по краям
    {r, b, g} <= 3'b000;

    // Кадровая развертка
    x <= xmax ?         0 : x + 1;
    y <= xmax ? (ymax ? 0 : y + 1) : y;

    case (xa[3:0])
    4'hD: begin a <= {ya[8:1], xa[8:4]} | 13'h0000; end
    4'hE: begin a <= {ya[8:4], xa[8:4]} | 13'h1800; t <= i; end
    4'hF: begin {c,m} <= {i,t}; end
    endcase

    // Вывод окна видеоадаптера
    if (show) begin {r, g, b} <= paper ? (mb ? c[2:0] : c[5:3]) : border; end

end

endmodule
