// ============================================================
// risc_debug_display.sv - DISPLAY CON VISUALIZADOR DE PIPELINE
// ============================================================

module risc_debug_display(
    input  logic        clock,
    input  logic        sw0,
    input  logic        sw1, sw2, sw3, sw4, sw5,
    input  logic [1:0]  page_select,

    // Registros
    input  logic [31:0] regs_demo [0:31],
    input  logic [31:0] changed_mask,
    
    // PC e Instrucción (Etapa IF/General)
    input  logic [31:0] pc_value,
    input  logic [31:0] instruction,
    input  logic [4:0]  br_op,
    
    // ALU (Etapa EX)
    input  logic [31:0] alu_operand_a,
    input  logic [31:0] alu_operand_b,
    input  logic [31:0] alu_result,
    input  logic [3:0]  alu_op, 
    
    // Inmediato
    input  logic [31:0] immediate,
    
    // Memoria 
    input  logic [31:0] memory [0:31],
    input  logic [31:0] instruction_memory [0:31],

    // --- NUEVAS ENTRADAS DE PIPELINE ---
    // IF Stage
    input logic [31:0] if_pc,
    input logic [31:0] if_instr,
    
    // ID Stage
    input logic [31:0] id_pc,
    input logic [31:0] id_instr,
    input logic        id_valid,

    // EX Stage
    input logic [31:0] ex_pc,
    input logic [31:0] ex_instr,
    input logic [31:0] ex_alu_res,
    input logic        ex_valid,

    // MEM Stage
    input logic [31:0] mem_pc,
    input logic [31:0] mem_instr, 
    input logic [31:0] mem_data,
    input logic        mem_valid,

    // WB Stage
    input logic [31:0] wb_pc,
    input logic [31:0] wb_instr,
    input logic [31:0] wb_data,
    input logic        wb_valid,
    // -----------------------------------

    output logic [7:0]  vga_red,
    output logic [7:0]  vga_green,
    output logic [7:0]  vga_blue,
    output logic        vga_hsync,
    output logic        vga_vsync,
    output logic        vga_clock
);

    // ============================================================
    // Señales VGA base
    // ============================================================
    logic [10:0] x;
    logic [9:0]  y;
    logic        videoOn;
    logic        vgaclk;

    vgaClock vgaclock(
        .ref_clk_clk(clock),
        .ref_reset_reset(sw0),
        .vga_clk_clk(vgaclk),
        .reset_source_reset()
    );
    assign vga_clock = vgaclk;

    vga_controller_1280x800 ctrl(
        .clk(vgaclk),
        .reset(sw0),
        .video_on(videoOn),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .hcount(x),
        .vcount(y)
    );

    // ============================================================
    // SINCRONIZACIÓN CDC
    // ============================================================
    logic [31:0] regs_sync1 [0:31];
    logic [31:0] pc_sync1, instruction_sync1;
    logic [31:0] alu_a_sync1, alu_b_sync1, alu_r_sync1;
    logic [3:0]  alu_op_sync1;
    logic [31:0] imm_sync1;
    logic [31:0] mem_sync1 [0:31];
    logic [31:0] imem_sync1 [0:31];
    logic [4:0]  br_op_sync1;
    logic [1:0]  page_sync1; 

    // Pipeline Sync Signals
    logic [31:0] if_pc_s1, if_instr_s1;
    logic [31:0] id_pc_s1, id_instr_s1; logic id_valid_s1;
    logic [31:0] ex_pc_s1, ex_instr_s1, ex_alu_res_s1; logic ex_valid_s1;
    logic [31:0] mem_pc_s1, mem_instr_s1, mem_data_s1; logic mem_valid_s1;
    logic [31:0] wb_pc_s1, wb_instr_s1, wb_data_s1; logic wb_valid_s1;
    
    always_ff @(posedge clock) begin
        regs_sync1 <= regs_demo;
        pc_sync1 <= pc_value;
        instruction_sync1 <= instruction;
        alu_a_sync1 <= alu_operand_a;
        alu_b_sync1 <= alu_operand_b;
        alu_r_sync1 <= alu_result;
        alu_op_sync1 <= alu_op;
        imm_sync1 <= immediate;
        mem_sync1 <= memory;
        imem_sync1 <= instruction_memory;
        br_op_sync1 <= br_op;  
        page_sync1 <= page_select;

        // Pipeline Sync
        if_pc_s1 <= if_pc; if_instr_s1 <= if_instr;
        id_pc_s1 <= id_pc; id_instr_s1 <= id_instr; id_valid_s1 <= id_valid;
        ex_pc_s1 <= ex_pc; ex_instr_s1 <= ex_instr; ex_alu_res_s1 <= ex_alu_res; ex_valid_s1 <= ex_valid;
        mem_pc_s1 <= mem_pc; mem_instr_s1 <= mem_instr; mem_data_s1 <= mem_data; mem_valid_s1 <= mem_valid;
        wb_pc_s1 <= wb_pc; wb_instr_s1 <= wb_instr; wb_data_s1 <= wb_data; wb_valid_s1 <= wb_valid;
    end
    
    logic [31:0] regs_vga [0:31];
    logic [31:0] pc_vga, instruction_vga;
    logic [31:0] alu_a_vga, alu_b_vga, alu_r_vga;
    logic [3:0]  alu_op_vga;
    logic [31:0] imm_vga;
    logic [31:0] mem_vga [0:31];
    logic [4:0]  br_op_vga; 
    logic [31:0] imem_vga [0:31];
    logic [1:0]  page_vga;

    // Pipeline VGA Signals
    logic [31:0] if_pc_v, if_instr_v;
    logic [31:0] id_pc_v, id_instr_v; logic id_valid_v;
    logic [31:0] ex_pc_v, ex_instr_v, ex_alu_res_v; logic ex_valid_v;
    logic [31:0] mem_pc_v, mem_instr_v, mem_data_v; logic mem_valid_v;
    logic [31:0] wb_pc_v, wb_instr_v, wb_data_v; logic wb_valid_v;
    
    always_ff @(posedge vgaclk) begin
        regs_vga <= regs_sync1;
        pc_vga <= pc_sync1;
        instruction_vga <= instruction_sync1;
        alu_a_vga <= alu_a_sync1;
        alu_b_vga <= alu_b_sync1;
        alu_r_vga <= alu_r_sync1;
        alu_op_vga <= alu_op_sync1; 
        imm_vga <= imm_sync1;
        mem_vga <= mem_sync1;
        br_op_vga <= br_op_sync1;
        imem_vga <= imem_sync1;
        page_vga <= page_sync1;

        // Pipeline VGA
        if_pc_v <= if_pc_s1; if_instr_v <= if_instr_s1;
        id_pc_v <= id_pc_s1; id_instr_s1 <= id_instr_s1; id_valid_v <= id_valid_s1;
        ex_pc_v <= ex_pc_s1; ex_instr_v <= ex_instr_s1; ex_alu_res_v <= ex_alu_res_s1; ex_valid_v <= ex_valid_s1;
        mem_pc_v <= mem_pc_s1; mem_instr_v <= mem_instr_s1; mem_data_v <= mem_data_s1; mem_valid_v <= mem_valid_s1;
        wb_pc_v <= wb_pc_s1; wb_instr_v <= wb_instr_s1; wb_data_v <= wb_data_s1; wb_valid_v <= wb_valid_s1;
    end

    logic is_ebreak;
    assign is_ebreak = (br_op_vga[4:3] == 2'b11);

    logic [7:0] ascii_code;
    logic [3:0] row_in_char;
    logic [2:0] col_in_char;
    logic       pixel_on;

    font_renderer font_inst (
        .clk(vgaclk),
        .ascii_code(ascii_code),
        .row_in_char(row_in_char),
        .col_in_char(col_in_char),
        .pixel_on(pixel_on)
    );

    localparam CHAR_W = 8;
    localparam CHAR_H = 16;
    
    // ... (Ventanas existentes REG, INFO, ALU, MEM, IMEM se mantienen igual) ...
    localparam REG_X = 10;
    localparam REG_Y = 10;
    localparam REG_COL_WIDTH = 21;
    localparam REG_W = REG_COL_WIDTH * 2 * CHAR_W;
    localparam REG_H = 18 * CHAR_H;
    
    localparam INFO_X = 360;
    localparam INFO_Y = 10;
    localparam INFO_W = 25 * CHAR_W;
    localparam INFO_H = 6 * CHAR_H;
    
    localparam ALU_X = 360;
    localparam ALU_Y = 120;
    localparam ALU_W = 25 * CHAR_W;
    localparam ALU_H = 10 * CHAR_H;
    
    localparam MEM_X = 10;
    localparam MEM_Y = 310;
    localparam MEM_W = 60 * CHAR_W;
    localparam MEM_H = 10 * CHAR_H;

    localparam IMEM_X = 10;
    localparam IMEM_Y = 550; // Ya movido abajo según tu petición anterior
    localparam IMEM_W = 60 * CHAR_W;
    localparam IMEM_H = 10 * CHAR_H;

    // ============================================================
    // VENTANA 6: PIPELINE VISUALIZER
    // ============================================================
    localparam PIPE_X = 650;       // Derecha
    localparam PIPE_Y = 10;
    localparam PIPE_W = 35 * CHAR_W;
    localparam PIPE_H = 45 * CHAR_H; // Alto para lista vertical

    // Lógica de selección de ventana
    logic in_reg_window, in_info_window, in_alu_window, in_mem_window, in_imem_window, in_pipe_window;
    
    // ... (Assignments de ventanas existentes) ...
    assign in_reg_window = (x >= REG_X && x < REG_X + REG_W && y >= REG_Y && y < REG_Y + REG_H);
    assign in_info_window = (x >= INFO_X && x < INFO_X + INFO_W && y >= INFO_Y && y < INFO_Y + INFO_H);
    assign in_alu_window = (x >= ALU_X && x < ALU_X + ALU_W && y >= ALU_Y && y < ALU_Y + ALU_H);
    assign in_mem_window = (x >= MEM_X && x < MEM_X + MEM_W && y >= MEM_Y && y < MEM_Y + MEM_H);
    assign in_imem_window = (x >= IMEM_X && x < IMEM_X + IMEM_W && y >= IMEM_Y && y < IMEM_Y + IMEM_H);
    
    // Pipeline Window logic
    logic [10:0] pipe_rel_x; logic [9:0] pipe_rel_y;
    logic [5:0] pipe_char_col; logic [4:0] pipe_char_row;
    assign in_pipe_window = (x >= PIPE_X && x < PIPE_X + PIPE_W && y >= PIPE_Y && y < PIPE_Y + PIPE_H);
    assign pipe_rel_x = in_pipe_window ? (x - PIPE_X) : 11'd0;
    assign pipe_rel_y = in_pipe_window ? (y - PIPE_Y) : 10'd0;
    assign pipe_char_col = pipe_rel_x / CHAR_W;
    assign pipe_char_row = pipe_rel_y / CHAR_H;

    // ... (Lógica de coordenadas relativas existentes para otras ventanas) ...
    logic [10:0] reg_rel_x, reg_rel_y, info_rel_x, info_rel_y, alu_rel_x, alu_rel_y, mem_rel_x, mem_rel_y, imem_rel_x, imem_rel_y;
    logic [5:0] reg_char_col, info_char_col, alu_char_col, mem_char_col, imem_char_col;
    logic [4:0] reg_char_row, info_char_row, alu_char_row, mem_char_row, imem_char_row;
    
    assign reg_rel_x = in_reg_window ? (x - REG_X) : 11'd0;
    assign reg_rel_y = in_reg_window ? (y - REG_Y) : 10'd0;
    assign reg_char_col = reg_rel_x / CHAR_W;
    assign reg_char_row = reg_rel_y / CHAR_H;
    
    assign info_rel_x = in_info_window ? (x - INFO_X) : 11'd0;
    assign info_rel_y = in_info_window ? (y - INFO_Y) : 10'd0;
    assign info_char_col = info_rel_x / CHAR_W;
    assign info_char_row = info_rel_y / CHAR_H;

    assign alu_rel_x = in_alu_window ? (x - ALU_X) : 11'd0;
    assign alu_rel_y = in_alu_window ? (y - ALU_Y) : 10'd0;
    assign alu_char_col = alu_rel_x / CHAR_W;
    assign alu_char_row = alu_rel_y / CHAR_H;

    assign mem_rel_x = in_mem_window ? (x - MEM_X) : 11'd0;
    assign mem_rel_y = in_mem_window ? (y - MEM_Y) : 10'd0;
    assign mem_char_col = mem_rel_x / CHAR_W;
    assign mem_char_row = mem_rel_y / CHAR_H;

    assign imem_rel_x = in_imem_window ? (x - IMEM_X) : 11'd0;
    assign imem_rel_y = in_imem_window ? (y - IMEM_Y) : 10'd0;
    assign imem_char_col = imem_rel_x / CHAR_W;
    assign imem_char_row = imem_rel_y / CHAR_H;

    // Variables auxiliares para visualización (copiadas de tu código anterior)
    logic [5:0] mem_display_idx; logic [1:0] mem_column; logic [3:0] mem_row_offset; logic [3:0] mem_col_pos;
    logic [5:0] imem_display_idx; logic [1:0] imem_column; logic [3:0] imem_row_offset; logic [3:0] imem_col_pos;
    logic reg_column_sel; logic [5:0] reg_local_col; logic [4:0] reg_idx; logic [4:0] actual_reg_idx;

    // Lógica Memoria
    assign mem_row_offset = (mem_char_row >= 2) ? (mem_char_row - 2) : 4'd0;
    always_comb begin
        if (mem_char_col < 15) begin mem_column=0; mem_display_idx = mem_row_offset; end
        else if (mem_char_col < 30) begin mem_column=1; mem_display_idx = 8 + mem_row_offset; end
        else if (mem_char_col < 45) begin mem_column=2; mem_display_idx = 16 + mem_row_offset; end
        else if (mem_char_col < 60) begin mem_column=3; mem_display_idx = 24 + mem_row_offset; end
        else begin mem_column=0; mem_display_idx = 0; end
        mem_col_pos = mem_char_col - (mem_column * 15);
    end

    // Lógica IMEM
    assign imem_row_offset = (imem_char_row >= 2) ? (imem_char_row - 2) : 4'd0;
    always_comb begin
        if (imem_char_col < 15) begin imem_column=0; imem_display_idx = imem_row_offset; end
        else if (imem_char_col < 30) begin imem_column=1; imem_display_idx = 8 + imem_row_offset; end
        else if (imem_char_col < 45) begin imem_column=2; imem_display_idx = 16 + imem_row_offset; end
        else if (imem_char_col < 60) begin imem_column=3; imem_display_idx = 24 + imem_row_offset; end
        else begin imem_column=0; imem_display_idx = 0; end
        imem_col_pos = imem_char_col - (imem_column * 15);
    end

    // Lógica Registros
    assign reg_column_sel = (reg_char_col >= REG_COL_WIDTH);
    assign reg_local_col = reg_column_sel ? (reg_char_col - REG_COL_WIDTH) : reg_char_col;
    assign reg_idx = reg_column_sel ? (reg_char_row - 2 + 5'd16) : (reg_char_row - 2);
    assign actual_reg_idx = 5'd31 - reg_idx;

    // Char Position Logic
    always_comb begin
        if (in_reg_window) begin 
            row_in_char = reg_rel_y[3:0]; 
            col_in_char = reg_rel_x[2:0]; 
        end else if (in_info_window) begin 
            row_in_char = info_rel_y[3:0]; 
            col_in_char = info_rel_x[2:0]; 
        end else if (in_alu_window) begin 
            row_in_char = alu_rel_y[3:0]; 
            col_in_char = alu_rel_x[2:0]; 
        end else if (in_mem_window) begin 
            row_in_char = mem_rel_y[3:0]; 
            col_in_char = mem_rel_x[2:0]; 
        end else if (in_imem_window) begin 
            row_in_char = imem_rel_y[3:0]; 
            col_in_char = imem_rel_x[2:0]; 
        end else if (in_pipe_window) begin 
            row_in_char = pipe_rel_y[3:0]; 
            col_in_char = pipe_rel_x[2:0]; 
        end else begin 
            row_in_char = 4'd0; 
            col_in_char = 3'd0; 
        end
    end
    
    // Helper Functions
    function automatic [7:0] to_hex(input [3:0] nib);
        case (nib)
            4'h0: return "0"; 4'h1: return "1"; 4'h2: return "2"; 4'h3: return "3";
            4'h4: return "4"; 4'h5: return "5"; 4'h6: return "6"; 4'h7: return "7";
            4'h8: return "8"; 4'h9: return "9"; 4'hA: return "A"; 4'hB: return "B";
            4'hC: return "C"; 4'hD: return "D"; 4'hE: return "E"; 4'hF: return "F";
            default: return "?";
        endcase
    endfunction
    
    // ... (alu_op_char function as before) ...
    function automatic [7:0] alu_op_char(input integer pos, input [3:0] op);
          case (op)
               4'b0000: begin case (pos) 0: return "A"; 1: return "D"; 2: return "D"; default: return " "; endcase end
               4'b1000: begin case (pos) 0: return "S"; 1: return "U"; 2: return "B"; default: return " "; endcase end
               4'b0001: begin case (pos) 0: return "S"; 1: return "L"; 2: return "L"; default: return " "; endcase end
               4'b0010: begin case (pos) 0: return "S"; 1: return "L"; 2: return "T"; default: return " "; endcase end
               4'b0011: begin case (pos) 0: return "S"; 1: return "L"; 2: return "T"; 3: return "U"; default: return " "; endcase end
               4'b0100: begin case (pos) 0: return "X"; 1: return "O"; 2: return "R"; default: return " "; endcase end
               4'b0101: begin case (pos) 0: return "S"; 1: return "R"; 2: return "L"; default: return " "; endcase end
               4'b1101: begin case (pos) 0: return "S"; 1: return "R"; 2: return "A"; default: return " "; endcase end
               4'b0110: begin case (pos) 0: return "O"; 1: return "R"; default: return " "; endcase end
               4'b0111: begin case (pos) 0: return "A"; 1: return "N"; 2: return "D"; default: return " "; endcase end
               default: begin case (pos) 0: return "?"; 1: return "?"; 2: return "?"; default: return " "; endcase end
          endcase
     endfunction

    // ============================================================
    // Generación de texto (ASCII)
    // ============================================================
    always_comb begin
        ascii_code = 8'd32;

        // --- PIPELINE WINDOW ---
        if (in_pipe_window) begin
            // Título
            if (pipe_char_row == 0) begin
               case(pipe_char_col)
                   0: ascii_code="P"; 1: ascii_code="I"; 2: ascii_code="P"; 3: ascii_code="E"; 
                   4: ascii_code="L"; 5: ascii_code="I"; 6: ascii_code="N"; 7: ascii_code="E";
                   default: ascii_code=" ";
               endcase
            end 
            else if (pipe_char_row == 1) ascii_code = "-";

            // IF STAGE
            else if (pipe_char_row == 3) begin
               case(pipe_char_col) 0: ascii_code="I"; 1: ascii_code="F"; 2: ascii_code=":"; default: ascii_code=" "; endcase
            end
            else if (pipe_char_row == 4) begin
               case(pipe_char_col)
                   1: ascii_code="P"; 2: ascii_code="C"; 3: ascii_code=":";
                   5: ascii_code=to_hex(if_pc_v[15:12]); 6: ascii_code=to_hex(if_pc_v[11:8]); 
                   7: ascii_code=to_hex(if_pc_v[7:4]); 8: ascii_code=to_hex(if_pc_v[3:0]);
                   11: ascii_code="I"; 12: ascii_code=":";
                   14: ascii_code=to_hex(if_instr_v[31:28]); 15: ascii_code=to_hex(if_instr_v[27:24]);
                   16: ascii_code=to_hex(if_instr_v[23:20]); 17: ascii_code=to_hex(if_instr_v[19:16]);
                   18: ascii_code=to_hex(if_instr_v[15:12]); 19: ascii_code=to_hex(if_instr_v[11:8]);
                   20: ascii_code=to_hex(if_instr_v[7:4]); 21: ascii_code=to_hex(if_instr_v[3:0]);
                   default: ascii_code=" ";
               endcase
            end
            
            // ID STAGE
            else if (pipe_char_row == 7) begin
               case(pipe_char_col) 0: ascii_code="I"; 1: ascii_code="D"; 2: ascii_code=":"; 
                                   4: ascii_code = id_valid_v ? " " : "S"; // STALL indicator
                                   5: ascii_code = id_valid_v ? " " : "T";
                                   6: ascii_code = id_valid_v ? " " : "A";
                                   7: ascii_code = id_valid_v ? " " : "L";
                                   8: ascii_code = id_valid_v ? " " : "L";
                                   default: ascii_code=" "; endcase
            end
            else if (pipe_char_row == 8) begin
               case(pipe_char_col)
                   1: ascii_code="P"; 2: ascii_code="C"; 3: ascii_code=":";
                   5: ascii_code=to_hex(id_pc_v[15:12]); 6: ascii_code=to_hex(id_pc_v[11:8]); 
                   7: ascii_code=to_hex(id_pc_v[7:4]); 8: ascii_code=to_hex(id_pc_v[3:0]);
                   11: ascii_code="I"; 12: ascii_code=":";
                   14: ascii_code=to_hex(id_instr_v[31:28]); 15: ascii_code=to_hex(id_instr_v[27:24]);
                   16: ascii_code=to_hex(id_instr_v[23:20]); 17: ascii_code=to_hex(id_instr_v[19:16]);
                   18: ascii_code=to_hex(id_instr_v[15:12]); 19: ascii_code=to_hex(id_instr_v[11:8]);
                   20: ascii_code=to_hex(id_instr_v[7:4]); 21: ascii_code=to_hex(id_instr_v[3:0]);
                   default: ascii_code=" ";
               endcase
            end

            // EX STAGE
            else if (pipe_char_row == 11) begin
               case(pipe_char_col) 0: ascii_code="E"; 1: ascii_code="X"; 2: ascii_code=":"; 
                                   4: ascii_code = ex_valid_v ? " " : "B"; // BUBBLE indicator
                                   5: ascii_code = ex_valid_v ? " " : "U";
                                   6: ascii_code = ex_valid_v ? " " : "B";
                                   default: ascii_code=" "; endcase
            end
            else if (pipe_char_row == 12) begin
               case(pipe_char_col)
                   1: ascii_code="P"; 2: ascii_code="C"; 3: ascii_code=":";
                   5: ascii_code=to_hex(ex_pc_v[15:12]); 6: ascii_code=to_hex(ex_pc_v[11:8]); 
                   7: ascii_code=to_hex(ex_pc_v[7:4]); 8: ascii_code=to_hex(ex_pc_v[3:0]);
                   11: ascii_code="R"; 12: ascii_code="E"; 13: ascii_code="S"; 14: ascii_code=":";
                   16: ascii_code=to_hex(ex_alu_res_v[31:28]); 17: ascii_code=to_hex(ex_alu_res_v[27:24]);
                   18: ascii_code=to_hex(ex_alu_res_v[23:20]); 19: ascii_code=to_hex(ex_alu_res_v[19:16]);
                   20: ascii_code=to_hex(ex_alu_res_v[15:12]); 21: ascii_code=to_hex(ex_alu_res_v[11:8]);
                   22: ascii_code=to_hex(ex_alu_res_v[7:4]); 23: ascii_code=to_hex(ex_alu_res_v[3:0]);
                   default: ascii_code=" ";
               endcase
            end

            // MEM STAGE
            else if (pipe_char_row == 15) begin
               case(pipe_char_col) 0: ascii_code="M"; 1: ascii_code="E"; 2: ascii_code="M"; 3: ascii_code=":"; default: ascii_code=" "; endcase
            end
            else if (pipe_char_row == 16) begin
               case(pipe_char_col)
                   1: ascii_code="D"; 2: ascii_code="A"; 3: ascii_code="T"; 4: ascii_code=":";
                   6: ascii_code=to_hex(mem_data_v[31:28]); 7: ascii_code=to_hex(mem_data_v[27:24]);
                   8: ascii_code=to_hex(mem_data_v[23:20]); 9: ascii_code=to_hex(mem_data_v[19:16]);
                   10: ascii_code=to_hex(mem_data_v[15:12]); 11: ascii_code=to_hex(mem_data_v[11:8]);
                   12: ascii_code=to_hex(mem_data_v[7:4]); 13: ascii_code=to_hex(mem_data_v[3:0]);
                   default: ascii_code=" ";
               endcase
            end

            // WB STAGE
            else if (pipe_char_row == 19) begin
               case(pipe_char_col) 0: ascii_code="W"; 1: ascii_code="B"; 2: ascii_code=":"; default: ascii_code=" "; endcase
            end
            else if (pipe_char_row == 20) begin
               case(pipe_char_col)
                   1: ascii_code="W"; 2: ascii_code="D"; 3: ascii_code=":";
                   5: ascii_code=to_hex(wb_data_v[31:28]); 6: ascii_code=to_hex(wb_data_v[27:24]);
                   7: ascii_code=to_hex(wb_data_v[23:20]); 8: ascii_code=to_hex(wb_data_v[19:16]);
                   9: ascii_code=to_hex(wb_data_v[15:12]); 10: ascii_code=to_hex(wb_data_v[11:8]);
                   11: ascii_code=to_hex(wb_data_v[7:4]); 12: ascii_code=to_hex(wb_data_v[3:0]);
                   default: ascii_code=" ";
               endcase
            end
        end

        // --- OTHER WINDOWS (Copied directly from your code) ---
        else if (in_reg_window) begin
            if (reg_char_row == 0) begin
                if (!reg_column_sel) begin
                    case (reg_local_col)
                        6'd5: ascii_code = "R"; 6'd6: ascii_code = "E"; 6'd7: ascii_code = "G";
                        6'd8: ascii_code = "I"; 6'd9: ascii_code = "S"; 6'd10: ascii_code = "T";
                        6'd11: ascii_code = "E"; 6'd12: ascii_code = "R"; 6'd13: ascii_code = "S";
                        default: ascii_code = 8'd32;
                    endcase
                end
            end else if (reg_char_row == 1) begin
                if (reg_local_col < 20) ascii_code = 8'd45;
            end else if (reg_char_row >= 2 && reg_char_row < 18) begin
                case (reg_local_col)
                    6'd0: ascii_code = "x";
                    6'd1: ascii_code = 8'd48 + 8'(reg_idx / 10);
                    6'd2: ascii_code = 8'd48 + 8'(reg_idx % 10);
                    6'd3: ascii_code = ":";
                    6'd4: ascii_code = 8'd32;
                    6'd5: ascii_code = "0";
                    6'd6: ascii_code = "x";
                    6'd7:  ascii_code = to_hex(regs_vga[actual_reg_idx][31:28]);
                    6'd8:  ascii_code = to_hex(regs_vga[actual_reg_idx][27:24]);
                    6'd9:  ascii_code = to_hex(regs_vga[actual_reg_idx][23:20]);
                    6'd10: ascii_code = to_hex(regs_vga[actual_reg_idx][19:16]);
                    6'd11: ascii_code = to_hex(regs_vga[actual_reg_idx][15:12]);
                    6'd12: ascii_code = to_hex(regs_vga[actual_reg_idx][11:8]);
                    6'd13: ascii_code = to_hex(regs_vga[actual_reg_idx][7:4]);
                    6'd14: ascii_code = to_hex(regs_vga[actual_reg_idx][3:0]);
                    default: ascii_code = 8'd32;
                endcase
            end
        end
        
        else if (in_info_window) begin
            case (info_char_row)
                5'd0: begin
                    case (info_char_col)
                        6'd0: ascii_code = "P"; 6'd1: ascii_code = "C";
                        6'd3: ascii_code = "&";
                        6'd5: ascii_code = "I"; 6'd6: ascii_code = "N"; 6'd7: ascii_code = "S";
                        6'd8: ascii_code = "T"; 6'd9: ascii_code = "R";
                        6'd15: ascii_code = is_ebreak ? "[" : " ";
                        6'd16: ascii_code = is_ebreak ? "H" : " ";
                        6'd17: ascii_code = is_ebreak ? "A" : " ";
                        6'd18: ascii_code = is_ebreak ? "L" : " ";
                        6'd19: ascii_code = is_ebreak ? "T" : " ";
                        6'd20: ascii_code = is_ebreak ? "E" : " ";
                        6'd21: ascii_code = is_ebreak ? "D" : " ";
                        6'd22: ascii_code = is_ebreak ? "]" : " ";
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd1: if (info_char_col < 20) ascii_code = 8'd45;
                5'd2: begin
                    case (info_char_col)
                        6'd0: ascii_code = "P"; 6'd1: ascii_code = "C"; 6'd2: ascii_code = ":";
                        6'd4: ascii_code = "0"; 6'd5: ascii_code = "x";
                        6'd6:  ascii_code = to_hex(pc_vga[31:28]);
                        6'd7:  ascii_code = to_hex(pc_vga[27:24]);
                        6'd8:  ascii_code = to_hex(pc_vga[23:20]);
                        6'd9:  ascii_code = to_hex(pc_vga[19:16]);
                        6'd10: ascii_code = to_hex(pc_vga[15:12]);
                        6'd11: ascii_code = to_hex(pc_vga[11:8]);
                        6'd12: ascii_code = to_hex(pc_vga[7:4]);
                        6'd13: ascii_code = to_hex(pc_vga[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd3: begin
                    case (info_char_col)
                        6'd0: ascii_code = "I"; 6'd1: ascii_code = "R"; 6'd2: ascii_code = ":";
                        6'd4: ascii_code = "0"; 6'd5: ascii_code = "x";
                        6'd6:  ascii_code = to_hex(instruction_vga[31:28]);
                        6'd7:  ascii_code = to_hex(instruction_vga[27:24]);
                        6'd8:  ascii_code = to_hex(instruction_vga[23:20]);
                        6'd9:  ascii_code = to_hex(instruction_vga[19:16]);
                        6'd10: ascii_code = to_hex(instruction_vga[15:12]);
                        6'd11: ascii_code = to_hex(instruction_vga[11:8]);
                        6'd12: ascii_code = to_hex(instruction_vga[7:4]);
                        6'd13: ascii_code = to_hex(instruction_vga[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                5'd4: begin
                    case (info_char_col)
                        6'd0: ascii_code = "I"; 6'd1: ascii_code = "M"; 6'd2: ascii_code = "M"; 6'd3: ascii_code = ":";
                        6'd5: ascii_code = "0"; 6'd6: ascii_code = "x";
                        6'd7:  ascii_code = to_hex(imm_vga[31:28]);
                        6'd8:  ascii_code = to_hex(imm_vga[27:24]);
                        6'd9:  ascii_code = to_hex(imm_vga[23:20]);
                        6'd10: ascii_code = to_hex(imm_vga[19:16]);
                        6'd11: ascii_code = to_hex(imm_vga[15:12]);
                        6'd12: ascii_code = to_hex(imm_vga[11:8]);
                        6'd13: ascii_code = to_hex(imm_vga[7:4]);
                        6'd14: ascii_code = to_hex(imm_vga[3:0]);
                        default: ascii_code = 8'd32;
                    endcase
                end
                default: ascii_code = 8'd32;
            endcase
        end

        else if (in_alu_window) begin
            case (alu_char_row)
                5'd0: begin
                      case (alu_char_col)
                           6'd0: ascii_code = "A"; 6'd1: ascii_code = "L"; 6'd2: ascii_code = "U";
                           default: ascii_code = 8'd32;
                      endcase
                end
                5'd1: if (alu_char_col < 20) ascii_code = 8'd45;
                5'd2: begin
                      case (alu_char_col)
                           6'd0: ascii_code = "O"; 6'd1: ascii_code = "P"; 6'd2: ascii_code = ":";
                           6'd4: ascii_code = alu_op_char(0, alu_op_vga);
                           6'd5: ascii_code = alu_op_char(1, alu_op_vga);
                           6'd6: ascii_code = alu_op_char(2, alu_op_vga);
                           6'd7: ascii_code = alu_op_char(3, alu_op_vga);
                           6'd9: ascii_code = "(";
                           6'd10: ascii_code = to_hex(alu_op_vga);
                           6'd11: ascii_code = ")";
                           default: ascii_code = 8'd32;
                      endcase
                end
                5'd3: if (alu_char_col < 13) ascii_code = 8'd45;
                5'd4: begin
                      case (alu_char_col)
                           6'd0: ascii_code = "A"; 6'd1: ascii_code = ":";
                           6'd3: ascii_code = "0"; 6'd4: ascii_code = "x";
                           6'd5:  ascii_code = to_hex(alu_a_vga[31:28]);
                           6'd6:  ascii_code = to_hex(alu_a_vga[27:24]);
                           6'd7:  ascii_code = to_hex(alu_a_vga[23:20]);
                           6'd8:  ascii_code = to_hex(alu_a_vga[19:16]);
                           6'd9:  ascii_code = to_hex(alu_a_vga[15:12]);
                           6'd10: ascii_code = to_hex(alu_a_vga[11:8]);
                           6'd11: ascii_code = to_hex(alu_a_vga[7:4]);
                           6'd12: ascii_code = to_hex(alu_a_vga[3:0]);
                           default: ascii_code = 8'd32;
                      endcase
                end
                5'd5: begin
                      case (alu_char_col)
                           6'd0: ascii_code = "B"; 6'd1: ascii_code = ":";
                           6'd3: ascii_code = "0"; 6'd4: ascii_code = "x";
                           6'd5:  ascii_code = to_hex(alu_b_vga[31:28]);
                           6'd6:  ascii_code = to_hex(alu_b_vga[27:24]);
                           6'd7:  ascii_code = to_hex(alu_b_vga[23:20]);
                           6'd8:  ascii_code = to_hex(alu_b_vga[19:16]);
                           6'd9:  ascii_code = to_hex(alu_b_vga[15:12]);
                           6'd10: ascii_code = to_hex(alu_b_vga[11:8]);
                           6'd11: ascii_code = to_hex(alu_b_vga[7:4]);
                           6'd12: ascii_code = to_hex(alu_b_vga[3:0]);
                           default: ascii_code = 8'd32;
                      endcase
                end
                5'd6: if (alu_char_col < 13) ascii_code = 8'd45;
                5'd7: begin
                      case (alu_char_col)
                           6'd0: ascii_code = "R"; 6'd1: ascii_code = ":";
                           6'd3: ascii_code = "0"; 6'd4: ascii_code = "x";
                           6'd5:  ascii_code = to_hex(alu_r_vga[31:28]);
                           6'd6:  ascii_code = to_hex(alu_r_vga[27:24]);
                           6'd7:  ascii_code = to_hex(alu_r_vga[23:20]);
                           6'd8:  ascii_code = to_hex(alu_r_vga[19:16]);
                           6'd9:  ascii_code = to_hex(alu_r_vga[15:12]);
                           6'd10: ascii_code = to_hex(alu_r_vga[11:8]);
                           6'd11: ascii_code = to_hex(alu_r_vga[7:4]);
                           6'd12: ascii_code = to_hex(alu_r_vga[3:0]);
                           default: ascii_code = 8'd32;
                      endcase
                end
                default: ascii_code = 8'd32;
            endcase
        end

        else if (in_mem_window) begin
            if (mem_char_row == 0) begin
                case (mem_char_col)
                    6'd0: ascii_code = "M"; 6'd1: ascii_code = "E"; 6'd2: ascii_code = "M";
                    6'd3: ascii_code = "O"; 6'd4: ascii_code = "R"; 6'd5: ascii_code = "Y";
                    6'd7: ascii_code = "("; 6'd8: ascii_code = "3"; 6'd9: ascii_code = "2";
                    6'd10: ascii_code = ")";
                    default: ascii_code = 8'd32;
                endcase
            end else if (mem_char_row == 1) begin
                ascii_code = (mem_char_col < 60) ? 8'd45 : 8'd32;
            end else if (mem_char_row >= 2 && mem_char_row < 10 && mem_char_col < 60) begin
                case (mem_col_pos)
                    4'd0: ascii_code = "[";
                    4'd1: ascii_code = 8'd48 + (mem_display_idx / 10);
                    4'd2: ascii_code = 8'd48 + (mem_display_idx % 10);
                    4'd3: ascii_code = "]";
                    4'd4: ascii_code = ":";
                    4'd5: ascii_code = "0";
                    4'd6: ascii_code = "x";
                    4'd7:  ascii_code = to_hex(mem_vga[mem_display_idx][31:28]);
                    4'd8:  ascii_code = to_hex(mem_vga[mem_display_idx][27:24]);
                    4'd9:  ascii_code = to_hex(mem_vga[mem_display_idx][23:20]);
                    4'd10: ascii_code = to_hex(mem_vga[mem_display_idx][19:16]);
                    4'd11: ascii_code = to_hex(mem_vga[mem_display_idx][15:12]);
                    4'd12: ascii_code = to_hex(mem_vga[mem_display_idx][11:8]);
                    4'd13: ascii_code = to_hex(mem_vga[mem_display_idx][7:4]);
                    4'd14: ascii_code = to_hex(mem_vga[mem_display_idx][3:0]);
                    default: ascii_code = 8'd32;
                endcase
            end else begin
                ascii_code = 8'd32;
            end
        end

        else if (in_imem_window) begin
            if (imem_char_row == 0) begin
                case (imem_char_col)
                    6'd0: ascii_code = "P"; 6'd1: ascii_code = "R"; 6'd2: ascii_code = "O";
                    6'd3: ascii_code = "G"; 6'd4: ascii_code = "R"; 6'd5: ascii_code = "A";
                    6'd6: ascii_code = "M"; 6'd7: ascii_code = " "; 6'd8: ascii_code = "M";
                    6'd9: ascii_code = "E"; 6'd10: ascii_code = "M";
                    6'd12: ascii_code = "[";
                    6'd13: ascii_code = "P";
                    6'd14: ascii_code = "G";
                    6'd15: ascii_code = ":";
                    6'd16: ascii_code = 8'd48 + page_vga;
                    6'd17: ascii_code = "]";
                    6'd19: ascii_code = "(";
                    6'd20: ascii_code = 8'd48 + ((page_vga * 32) / 10);
                    6'd21: ascii_code = 8'd48 + ((page_vga * 32) % 10);
                    6'd22: ascii_code = "-";
                    6'd23: ascii_code = 8'd48 + ((page_vga * 32 + 31) / 100);
                    6'd24: ascii_code = 8'd48 + (((page_vga * 32 + 31) / 10) % 10);
                    6'd25: ascii_code = 8'd48 + ((page_vga * 32 + 31) % 10);
                    6'd26: ascii_code = ")";
                    default: ascii_code = 8'd32;
                endcase
            end else if (imem_char_row == 1) begin
                ascii_code = (imem_char_col < 60) ? 8'd45 : 8'd32;
            end else if (imem_char_row >= 2 && imem_char_row < 10 && imem_char_col < 60) begin
                logic [7:0] actual_addr; 
                actual_addr = (page_vga * 32) + imem_display_idx;
                
                case (imem_col_pos)
                    4'd0: ascii_code = "[";
                    4'd1: ascii_code = 8'd48 + (actual_addr / 100);
                    4'd2: ascii_code = 8'd48 + ((actual_addr / 10) % 10);
                    4'd3: ascii_code = 8'd48 + (actual_addr % 10);
                    4'd4: ascii_code = "]";
                    4'd5: ascii_code = "0";
                    4'd6: ascii_code = "x";
                    4'd7:  ascii_code = to_hex(imem_vga[imem_display_idx][31:28]);
                    4'd8:  ascii_code = to_hex(imem_vga[imem_display_idx][27:24]);
                    4'd9:  ascii_code = to_hex(imem_vga[imem_display_idx][23:20]);
                    4'd10: ascii_code = to_hex(imem_vga[imem_display_idx][19:16]);
                    4'd11: ascii_code = to_hex(imem_vga[imem_display_idx][15:12]);
                    4'd12: ascii_code = to_hex(imem_vga[imem_display_idx][11:8]);
                    4'd13: ascii_code = to_hex(imem_vga[imem_display_idx][7:4]);
                    4'd14: ascii_code = to_hex(imem_vga[imem_display_idx][3:0]);
                    default: ascii_code = 8'd32;
                endcase
            end else begin
                ascii_code = 8'd32;
            end
        end
    end

    // ============================================================
    // Colores
    // ============================================================
    always_comb begin
        if (~videoOn) begin
            {vga_red, vga_green, vga_blue} = 24'h000000;
        end else if (pixel_on) begin
            if (is_ebreak && in_info_window && info_char_col >= 15 && info_char_col <= 22) begin
                {vga_red, vga_green, vga_blue} = 24'hFF0000;
            end else begin
                {vga_red, vga_green, vga_blue} = 24'hFFFFFF; // Todo BLANCO por defecto
            end
        end else begin
            {vga_red, vga_green, vga_blue} = 24'h000000;
        end
    end

endmodule
