module packet_axi_32 #
(
    parameter integer C_S_AXI_ADDR_WIDTH = 4,
    parameter integer C_S_AXI_DATA_WIDTH = 32
)
(
    //========================
    // AXI-Lite (control)
    //========================
    input  wire                          s_axi_aclk,
    input  wire                          s_axi_aresetn,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                          s_axi_awvalid,
    output reg                           s_axi_awready,

    input  wire [C_S_AXI_DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8-1):0] s_axi_wstrb,
    input  wire                          s_axi_wvalid,
    output reg                           s_axi_wready,

    output reg  [1:0]                    s_axi_bresp,
    output reg                           s_axi_bvalid,
    input  wire                          s_axi_bready,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                          s_axi_arvalid,
    output reg                           s_axi_arready,

    output reg  [C_S_AXI_DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]                    s_axi_rresp,
    output reg                           s_axi_rvalid,
    input  wire                          s_axi_rready,

    //========================
    // AXI-Stream domain
    //========================
    input  wire                          axis_aclk,
    input  wire                          axis_aresetn,

    // AXI-Stream slave (in)
    input  wire [31:0]                   s_axis_tdata,
    input  wire                          s_axis_tvalid,
    output reg                           s_axis_tready,
    input  wire                          s_axis_tlast,   // 未使用

    // AXI-Stream master (out)
    output reg  [31:0]                   m_axis_tdata,
    output reg                           m_axis_tvalid,
    input  wire                          m_axis_tready,
    output reg                           m_axis_tlast
);

    //================================================================
    // AXI-Lite regs (s_axi_aclk domain)
    // 0x00 length_reg (R/W)
    // 0x04 start_reg  (bit0 start_level) (R/W)
    //================================================================
    localparam integer ADDR_LSB = 2;
    localparam integer OPT_MEM_ADDR_BITS = C_S_AXI_ADDR_WIDTH - ADDR_LSB;

    reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_reg;
    reg aw_en;

    reg [31:0] length_reg;
    reg [31:0] start_reg;
    wire       start_level = start_reg[0];

    // AWREADY
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            aw_en         <= 1'b1;
        end else begin
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                awaddr_reg    <= s_axi_awaddr;
                aw_en         <= 1'b0;
            end else if (s_axi_bvalid && s_axi_bready) begin
                aw_en         <= 1'b1;
                s_axi_awready <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end

    // WREADY
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
        end else begin
            if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                s_axi_wready <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    // Register write
    integer byte_index;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            length_reg <= 32'd0;
            start_reg  <= 32'd0;
        end else begin
            if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
                case (awaddr_reg[ADDR_LSB + OPT_MEM_ADDR_BITS-1 : ADDR_LSB])
                    0: begin // 0x00 length
                        for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1) begin
                            if (s_axi_wstrb[byte_index])
                                length_reg[8*byte_index +: 8] <= s_axi_wdata[8*byte_index +: 8];
                        end
                    end
                    1: begin // 0x04 start
                        for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1) begin
                            if (s_axi_wstrb[byte_index])
                                start_reg[8*byte_index +: 8] <= s_axi_wdata[8*byte_index +: 8];
                        end
                    end
                    default: begin end
                endcase
            end
        end
    end

    // B channel
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && ~s_axi_bvalid &&
                s_axi_wready  && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ARREADY
    reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_reg;
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            araddr_reg    <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                araddr_reg    <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end

    // RDATA mux
    always @(*) begin
        case (araddr_reg[ADDR_LSB + OPT_MEM_ADDR_BITS-1 : ADDR_LSB])
            0: s_axi_rdata = length_reg;
            1: s_axi_rdata = start_reg;
            default: s_axi_rdata = 32'd0;
        endcase
    end

    // R channel
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
        end else begin
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00; // OKAY
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    //================================================================
    // CDC: s_axi_aclk -> axis_aclk
    //================================================================
    (* ASYNC_REG = "TRUE" *) reg       start_sync1;
    (* ASYNC_REG = "TRUE" *) reg       start_sync2;
    reg                               start_sync2_d;

    (* ASYNC_REG = "TRUE" *) reg [31:0] length_sync1;
    (* ASYNC_REG = "TRUE" *) reg [31:0] length_sync2;

    always @(posedge axis_aclk) begin
        if (!axis_aresetn) begin
            start_sync1   <= 1'b0;
            start_sync2   <= 1'b0;
            start_sync2_d <= 1'b0;
            length_sync1  <= 32'd0;
            length_sync2  <= 32'd0;
        end else begin
            start_sync1   <= start_level;
            start_sync2   <= start_sync1;
            start_sync2_d <= start_sync2;

            length_sync1  <= length_reg;
            length_sync2  <= length_sync1;
        end
    end

    wire start_pulse_axis = start_sync2 & ~start_sync2_d;

    //================================================================
    // AXIS domain datapath (IDLE -> ARM -> RUN)
    //================================================================
    localparam S_IDLE = 2'd0;
    localparam S_ARM  = 2'd1;
    localparam S_RUN  = 2'd2;

    reg [1:0]  state;
    reg [31:0] remain;

    always @(posedge axis_aclk) begin
        if (!axis_aresetn) begin
            state        <= S_IDLE;
            remain       <= 32'd0;

            s_axis_tready <= 1'b0;
            m_axis_tdata  <= 32'd0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;

        end else begin
            // defaults
            s_axis_tready <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start_pulse_axis) begin
                        if (length_sync2 != 0) begin
                            remain <= length_sync2;
                            state  <= S_ARM;   // startから数クロック遅延OK
                        end
                    end
                end

                S_ARM: begin
                    state <= S_RUN;
                end

                S_RUN: begin
                    s_axis_tready <= 1'b1;

                    if (s_axis_tvalid && m_axis_tready) begin
                        m_axis_tdata  <= s_axis_tdata;
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast  <= (remain == 32'd1);

                        remain <= remain - 32'd1;
                        if (remain == 32'd1)
                            state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
