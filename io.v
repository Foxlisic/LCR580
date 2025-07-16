module io
(
    input               clock,
    input               reset_n,
    // Управление
    input       [15:0]  address,
    input       [ 7:0]  out,
    input               port_rd,
    input               port_we,
    // Клава
    input               kdone,
    input       [ 7:0]  kdata,
    // Пины на выход
    output  reg [ 7:0]  pin,
    output  reg [ 2:0]  border
);

reg [7:0]   keyb;
reg         keyb_irq;

// Вывод в порты сквозь регистры, но мне плевать
always @* begin

    pin = 8'hFF;
    case (address)
    16'h0001: pin = keyb_irq;
    16'h00FE: pin = keyb;
    endcase

end

// Главная логика
always @(posedge clock)
begin

    // Запись в порты
    if (port_we)
    case (address)
    16'h00FE: begin border <= out[2:0]; end
    endcase

    // Отслеживание клавы
    if (kdone) begin keyb <= kdata; keyb_irq <= 1; end

end

endmodule

