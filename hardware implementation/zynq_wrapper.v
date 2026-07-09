`timescale 1ns / 1ps

module zynq_wrapper (
    input  wire         clk,
    input  wire         rst_n,
    // AXI4-Lite slave interface
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    input  wire [5:0]   s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output wire         s_axi_awready,
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output wire         s_axi_wready,
    output wire [1:0]   s_axi_bresp,
    output wire         s_axi_bvalid,
    input  wire         s_axi_bready,
    input  wire [5:0]   s_axi_araddr,
    input  wire         s_axi_arvalid,
    output wire         s_axi_arready,
    output wire [31:0]  s_axi_rdata,
    output wire [1:0]   s_axi_rresp,
    output wire         s_axi_rvalid,
    input  wire         s_axi_rready,
    output wire         interrupt
);

    localparam ADDR_CTRL    = 6'h00;
    localparam ADDR_PT0     = 6'h04;
    localparam ADDR_PT1     = 6'h08;
    localparam ADDR_PT2     = 6'h0C;
    localparam ADDR_PT3     = 6'h10;
    localparam ADDR_KEY0    = 6'h14;
    localparam ADDR_KEY1    = 6'h18;
    localparam ADDR_KEY2    = 6'h1C;
    localparam ADDR_KEY3    = 6'h20;
    localparam ADDR_KEY4    = 6'h24;
    localparam ADDR_KEY5    = 6'h28;
    localparam ADDR_KEY6    = 6'h2C;
    localparam ADDR_KEY7    = 6'h30;
    localparam ADDR_CT0     = 6'h40;
    localparam ADDR_CT1     = 6'h44;
    localparam ADDR_CT2     = 6'h48;
    localparam ADDR_CT3     = 6'h4C;

    reg [255:0] key;
    reg [127:0] plain_text;
    reg         start_reg;
    wire [127:0] cipher_text;
    wire         done;

    aes_256_top aes_core (
        .clk(clk),
        .rst(~rst_n),
        .start(start_reg),
        .plain_text(plain_text),
        .key(key),
        .cipher_text(cipher_text),
        .done(done)
    );

    reg [31:0] key_reg0;
    reg [31:0] key_reg1;
    reg [31:0] key_reg2;
    reg [31:0] key_reg3;
    reg [31:0] key_reg4;
    reg [31:0] key_reg5;
    reg [31:0] key_reg6;
    reg [31:0] key_reg7;
    reg [31:0] pt_reg0;
    reg [31:0] pt_reg1;
    reg [31:0] pt_reg2;
    reg [31:0] pt_reg3;
    reg [31:0] ct_reg0;
    reg [31:0] ct_reg1;
    reg [31:0] ct_reg2;
    reg [31:0] ct_reg3;
    reg        start_written;

    reg [1:0] wstate;
    localparam W_IDLE = 0, W_ADDR = 1, W_RESP = 2;

    assign s_axi_awready = (wstate == W_IDLE);
    assign s_axi_wready  = (wstate == W_ADDR);
    assign s_axi_bresp   = 0;
    assign s_axi_bvalid  = (wstate == W_RESP);

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            wstate <= W_IDLE;
            key_reg0 <= 0; key_reg1 <= 0; key_reg2 <= 0; key_reg3 <= 0;
            key_reg4 <= 0; key_reg5 <= 0; key_reg6 <= 0; key_reg7 <= 0;
            pt_reg0 <= 0; pt_reg1 <= 0; pt_reg2 <= 0; pt_reg3 <= 0;
            start_written <= 0;
        end else begin
            case (wstate)
                W_IDLE: begin
                    if (s_axi_awvalid) wstate <= W_ADDR;
                end
                W_ADDR: begin
                    if (s_axi_wvalid) begin
                        case (s_axi_awaddr)
                            ADDR_KEY0: key_reg0 <= s_axi_wdata;
                            ADDR_KEY1: key_reg1 <= s_axi_wdata;
                            ADDR_KEY2: key_reg2 <= s_axi_wdata;
                            ADDR_KEY3: key_reg3 <= s_axi_wdata;
                            ADDR_KEY4: key_reg4 <= s_axi_wdata;
                            ADDR_KEY5: key_reg5 <= s_axi_wdata;
                            ADDR_KEY6: key_reg6 <= s_axi_wdata;
                            ADDR_KEY7: key_reg7 <= s_axi_wdata;
                            ADDR_PT0:  pt_reg0 <= s_axi_wdata;
                            ADDR_PT1:  pt_reg1 <= s_axi_wdata;
                            ADDR_PT2:  pt_reg2 <= s_axi_wdata;
                            ADDR_PT3:  pt_reg3 <= s_axi_wdata;
                            ADDR_CTRL: start_written <= s_axi_wdata[0];
                        endcase
                        wstate <= W_RESP;
                    end
                end
                W_RESP: begin
                    if (s_axi_bready) wstate <= W_IDLE;
                end
            endcase
        end
    end

    reg [1:0] rstate;
    localparam R_IDLE = 0, R_DATA = 1;

    assign s_axi_arready = (rstate == R_IDLE);
    assign s_axi_rresp   = 0;
    assign s_axi_rvalid  = (rstate == R_DATA);

    reg [31:0] rdata;
    assign s_axi_rdata = rdata;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            rstate <= R_IDLE;
            rdata <= 0;
        end else begin
            case (rstate)
                R_IDLE: begin
                    if (s_axi_arvalid) begin
                        case (s_axi_araddr)
                            ADDR_CT0:  rdata <= ct_reg0;
                            ADDR_CT1:  rdata <= ct_reg1;
                            ADDR_CT2:  rdata <= ct_reg2;
                            ADDR_CT3:  rdata <= ct_reg3;
                            ADDR_CTRL: rdata <= {31'b0, done};
                            default:   rdata <= 0;
                        endcase
                        rstate <= R_DATA;
                    end
                end
                R_DATA: begin
                    if (s_axi_rready) rstate <= R_IDLE;
                end
            endcase
        end
    end

    reg start_meta;
    reg start_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_meta <= 0;
            start_sync <= 0;
            start_reg <= 0;
        end else begin
            start_meta <= start_written;
            start_sync <= start_meta;
            start_reg <= start_sync;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key <= 0;
            plain_text <= 0;
        end else if (start_reg) begin
            key <= {key_reg7, key_reg6, key_reg5, key_reg4,
                    key_reg3, key_reg2, key_reg1, key_reg0};
            plain_text <= {pt_reg3, pt_reg2, pt_reg1, pt_reg0};
        end
    end

    always @(posedge clk) begin
        ct_reg0 <= cipher_text[31:0];
        ct_reg1 <= cipher_text[63:32];
        ct_reg2 <= cipher_text[95:64];
        ct_reg3 <= cipher_text[127:96];
    end

    assign interrupt = done;

endmodule