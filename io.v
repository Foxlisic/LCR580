module io
(
    input               clock,
    input               reset_n,
    // Управление
    input       [15:0]  address,
    input       [ 7:0]  out,
    input               port_rd,
    input               port_we,
    // Клава и периферия разная
    input               kdone,
    input       [ 7:0]  kdata,
    input               vretrace,
    // Прерывания
    input               iff1,
    output  reg         irq,
    output  reg [ 3:0]  vect,
    // Пины на выход
    output  reg [ 7:0]  pin,
    output  reg [ 2:0]  border
);

reg [7:0]   keyb;
reg [3:0]   queue;

// Вывод в порты сквозь регистры, но мне плевать
always @* begin

    pin = 8'hFF;
    case (address)
    16'h00FE: pin = keyb;
    endcase

end

// Главная логика
always @(posedge clock)
if (reset_n == 0) begin

    irq     <= 0;
    vect    <= 0;
    queue   <= 4'b0001;

end
else begin

    // Контроллер прерываний
    if (iff1) begin

        if      (queue[0]) begin vect <= 1; irq <= ~irq; queue[0] <= 1'b0; end // KEYB
        else if (queue[1]) begin vect <= 2; irq <= ~irq; queue[1] <= 1'b0; end // VRETRACE
        else if (queue[2]) begin vect <= 3; irq <= ~irq; queue[2] <= 1'b0; end // TIMER

    end

    // Запись в порты
    if (port_we)
    case (address)
    16'h00FE: begin border <= out[2:0]; end
    endcase

    // Отслеживание нажатия на кнопку клавиатуры
    if (kdone)    begin queue[0] <= 1'b1; keyb <= kdata; end
    if (vretrace) begin queue[1] <= 1'b1; end

end

endmodule

