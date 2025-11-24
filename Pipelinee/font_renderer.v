module font_renderer (
    input  wire        clk,
    input  wire [7:0]  ascii_code,
    input  wire [3:0]  row_in_char,
    input  wire [2:0]  col_in_char,
    output reg         pixel_on  // Cambiar a reg
);

    wire [10:0] rom_addr;
    wire [7:0]  rom_data;
    reg  [2:0]  col_in_char_reg;  // Registrar coordenada

    assign rom_addr = {ascii_code[6:0], row_in_char};

    font_rom rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    // Pipeline: Registrar la columna para alinear con la salida de ROM
    always @(posedge clk) begin
        col_in_char_reg <= col_in_char;
        pixel_on <= rom_data[7 - col_in_char_reg];
    end

endmodule
