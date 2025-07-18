module vga
(
    input               clock,
    output  reg [ 3:0]  r,
    output  reg [ 3:0]  g,
    output  reg [ 3:0]  b,
    output              hs,
    output              vs,
    output  reg [12:0]  a,
    input       [ 7:0]  i,
    input       [ 2:0]  border,
    output  reg         vretrace
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
wire [ 8:0] xa = x - hzb - 48;
wire [ 8:0] ya = y - vtb - 8;
// ---------------------------------------------------------------------
wire xmax  = (x == hzw - 1);
wire ymax  = (y == vtw - 1);
wire show  = (x >= hzb && x < hzb + hzv) && (y >= vtb && y < vtb + vtv);
wire paper = (xc >= 64 && yc >= 8 && xc < 576 && yc < 392);
// ---------------------------------------------------------------------
wire        mb  = m[~xa[3:1]];
wire [ 3:0] cin = paper ? (mb ? c[3:0] : c[7:4]) : border;
// ---------------------------------------------------------------------
wire [11:0] color =
    cin ==  0 ? 12'h111 : cin ==  1 ? 12'h008 : cin == 2  ? 12'h080 : cin ==  3 ? 12'h088 :
    cin ==  4 ? 12'h800 : cin ==  5 ? 12'h808 : cin == 6  ? 12'h880 : cin ==  7 ? 12'h888 :
    cin ==  8 ? 12'h555 : cin ==  9 ? 12'h55F : cin == 10 ? 12'h5F5 : cin == 11 ? 12'h5FF :
    cin == 12 ? 12'hF55 : cin == 13 ? 12'hF5F : cin == 14 ? 12'hFF5 :             12'hFFF;
// ---------------------------------------------------------------------
always @(posedge clock) begin

    // Черный цвет по краям
    {r, b, g} <= 3'b000;

    // Как только заканчивается рисование кадра, вызвать прерывание
    vretrace <= 0;
    if (xmax & y == vtb + vtv + vtf) vretrace <= 1;

    // Кадровая развертка
    x <= xmax ?         0 : x + 1;
    y <= xmax ? (ymax ? 0 : y + 1) : y;

    case (xa[3:0])
    4'hD: begin a <= {ya[8:1], xa[8:4]} | 13'h0000; end
    4'hE: begin a <= {ya[8:4], xa[8:4]} | 13'h1800; t <= i; end
    4'hF: begin {c,m} <= {i,t}; end
    endcase

    // Вывод окна видеоадаптера
    if (show) begin {r, g, b} <= color; end

end

endmodule
