module vga_hello_world(
    input wire CLOCK_50,        // 50 MHz clock input
    input wire reset,           // Reset signal
    output wire VGA_HS,         // Horizontal sync signal
    output wire VGA_VS,         // Vertical sync signal
    output wire [5:0] VGA_R,    // 6-bit red channel
    output wire [5:0] VGA_G,    // 6-bit green channel
    output wire [5:0] VGA_B     // 6-bit blue channel
);

    // VGA 640x480 @ 60Hz parameters
    localparam H_ACTIVE = 640, H_FRONT = 16, H_SYNC = 96, H_BACK = 48, H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
    localparam V_ACTIVE = 480, V_FRONT = 10, V_SYNC = 2, V_BACK = 33, V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

    wire clk_vga, locked;

    // Generate a 25 MHz VGA clock from 50 MHz input
    pll pll_inst(
        .areset(reset),
        .inclk0(CLOCK_50),
        .c0(clk_vga),
        .locked(locked)
    );

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    // Character bitmaps for "H", "E", "L", and "O" (8x8 each)
    reg [7:0] char_H [7:0];
    reg [7:0] char_E [7:0];
    reg [7:0] char_L [7:0];
    reg [7:0] char_O [7:0];

    initial begin
        // Define bitmaps for characters "H", "E", "L", and "O"
        char_H[0] = 8'b10000001; // H
        char_H[1] = 8'b10000001;
        char_H[2] = 8'b10000001;
        char_H[3] = 8'b11111111;
        char_H[4] = 8'b10000001;
        char_H[5] = 8'b10000001;
        char_H[6] = 8'b10000001;
        char_H[7] = 8'b10000001;

        char_E[0] = 8'b11111111; // E 
        char_E[1] = 8'b10000000;
        char_E[2] = 8'b10000000;
        char_E[3] = 8'b11111111;
        char_E[4] = 8'b10000000;
        char_E[5] = 8'b10000000;
        char_E[6] = 8'b11111111;
        char_E[7] = 8'b00000000;

        char_L[0] = 8'b10000000; // L 
        char_L[1] = 8'b10000000;
        char_L[2] = 8'b10000000;
        char_L[3] = 8'b10000000;
        char_L[4] = 8'b10000000;
        char_L[5] = 8'b10000000;
        char_L[6] = 8'b10000000; 
        char_L[7] = 8'b11111111; 

        char_O[0] = 8'b01111110; // O
        char_O[1] = 8'b10000001;
        char_O[2] = 8'b10000001;
        char_O[3] = 8'b10000001;
        char_O[4] = 8'b10000001;
        char_O[5] = 8'b10000001;
        char_O[6] = 8'b01111110;
        char_O[7] = 8'b00000000;
    end

    // Sync signals
    assign VGA_HS = (h_count >= H_ACTIVE + H_FRONT) && (h_count < H_ACTIVE + H_FRONT + H_SYNC);
    assign VGA_VS = (v_count >= V_ACTIVE + V_FRONT) && (v_count < V_ACTIVE + V_FRONT + V_SYNC);

    // Update counters
    always @(posedge clk_vga or posedge reset) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // Center positions for the character area
    wire [9:0] h_center = (H_ACTIVE / 2) - 40; // Adjust for the new width
    wire [9:0] v_center = (V_ACTIVE / 2) - 4;

    // Determine if we are within the "H", "E", "L", "L", or "O" display area
    wire is_H_area = (h_count >= h_center) && (h_count < h_center + 8) &&
                     (v_count >= v_center) && (v_count < v_center + 8);

    wire is_E_area = (h_count >= h_center + 10) && (h_count < h_center + 18) &&
                     (v_count >= v_center) && (v_count < v_center + 8);

    wire is_L_area_1 = (h_count >= h_center + 20) && (h_count < h_center + 28) &&
                       (v_count >= v_center) && (v_count < v_center + 8);

    wire is_L_area_2 = (h_count >= h_center + 30) && (h_count < h_center + 38) &&
                       (v_count >= v_center) && (v_count < v_center + 8);

    wire is_O_area = (h_count >= h_center + 40) && (h_count < h_center + 48) &&
                     (v_count >= v_center) && (v_count < v_center + 8);

    // Calculate row and column within the character grid
wire [2:0] row_index = v_count - v_center;
wire [2:0] col_index_H = h_count - h_center;
wire [2:0] col_index_E = h_count - (h_center + 10);
wire [2:0] col_index_L_1 = h_count - (h_center + 20);
wire [2:0] col_index_L_2 = h_count - (h_center + 30);
wire [2:0] col_index_O = h_count - (h_center + 40);

// Pixel on/off for "H", "E", "L", "L", and "O" based on bitmap data
reg pixel_on;
always @(*) begin
    pixel_on = 1'b0; // Default to off
    if (is_H_area) begin
        pixel_on = char_H[row_index][7 - col_index_H]; // "H"
    end else if (is_E_area) begin
        pixel_on = char_E[row_index][col_index_E]; // "E"
    end else if (is_L_area_1) begin
        pixel_on = char_L[row_index][col_index_L_1 + 8]; // "L"
    end else if (is_L_area_2) begin
        pixel_on = char_L[row_index][col_index_L_2 + 8]; // "L"
    end else if (is_O_area) begin
        pixel_on = char_O[row_index][7 - col_index_O]; // "O"
    end
end

    // Set VGA output color (6-bit RGB)
    assign VGA_R = pixel_on ? 6'b111111 : 6'b000000;
    assign VGA_G = pixel_on ? 6'b111111 : 6'b000000;
    assign VGA_B = pixel_on ? 6'b111111 : 6'b000000;

endmodule
