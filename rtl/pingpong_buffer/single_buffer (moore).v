`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////
// This file implements a moore-type FSM to control a master-slave communication through one BRAM
// Each moore-type FSM is implemented following the three-part FSM paradigm.
//////////////////////////////////////////////////////////////////////////
module single_buffer(
    input clk
    );
    
    wire [5:0] bram_write_addr;
    wire [7:0] bram_write_data;

    reg       write_start, addr_sel;
    wire      write_done, read_done;
    
    /////////////////////////////////////////////////// write buffer 
    write_buffer wrtie(
    .clk(clk),
    .start(write_start),
    .done(write_done),
    .data(bram_write_data),
    .addr(bram_write_addr)
    );
    
    //////////////////////////////////////////////////// control FSM
    reg    state;
    reg    next_state;
    localparam WRITE_BRAM1      = 1'b0;
    localparam WAIT_BRAM1_READ  = 1'b1;
    
    reg    bram49_wea1;
    reg    start_up;
    
    initial begin
        start_up    = 1;
        bram49_wea1 = 1;
        addr_sel    = 0;
        
        state       = WRITE_BRAM1;
        next_state  = WRITE_BRAM1;
    end
    
    always@(posedge clk)
    begin
        start_up   <= 0;
    end
    
    always @(*)
    begin
        write_start = (start_up)? start_up:read_done;
    end
    
    always@(posedge clk)
    begin
        state <= next_state;
    end
    
    always@(posedge clk)
    begin
        case(next_state)
            WRITE_BRAM1: begin
                addr_sel    <= 1'b0;
                bram49_wea1 <= 1'b1;          
            end
            
            WAIT_BRAM1_READ:
            begin
                addr_sel    <= 1'b1;
                bram49_wea1 <= 1'b0;
            end
        endcase
    end
    
    always@(*)
    begin
        case(state)
            WRITE_BRAM1: 
            begin
                next_state = (write_done)?WAIT_BRAM1_READ:WRITE_BRAM1;
            end
            
            WAIT_BRAM1_READ: 
            begin    
                next_state  = (read_done)?WRITE_BRAM1:WAIT_BRAM1_READ;
            end
        endcase
    end
    
    ////// BRAM 1 Instantiation
    wire   [5:0] bram49_addra1;
    wire   [5:0] addr_read;
    wire   [7:0] bram49_dina1;
    wire   [7:0] bram49_douta1;
    
    assign bram49_addra1 = (addr_sel)? addr_read:bram_write_addr;
    assign bram49_dina1  = bram_write_data; 
    
    BRAM bram1 (
        .BRAM_PORTA_0_clk(clk),    // input wire clka
        .BRAM_PORTA_0_we(bram49_wea1),      // input wire [0 : 0] wea
        .BRAM_PORTA_0_addr(bram49_addra1),  // input wire [5 : 0] addra
        .BRAM_PORTA_0_din(bram49_dina1),    // input wire [7 : 0] dina
        .BRAM_PORTA_0_dout(bram49_douta1)
    );
    
    ////// BRAM READ Instantiation   
    read_buffer read(
    .clk(clk),
    .start(write_done),
    .done(read_done),
    .addr(addr_read),
    .data(bram49_douta1)
    );
endmodule

///////////////////  write buffer
module write_buffer(
input clk,
input start,
output done,
output [5:0] addr,
output [7:0] data
);

    ///////////////////////////// write part
    reg  done_inner;
    reg  [5:0] addr_inner;
    reg  [7:0] data_inner;
    // use gray code to encode the state to reduce the bit change.
    reg  [3:0] state;
    reg  [3:0] next_state;
    localparam WAIT_START       = 4'b0000;
    localparam WRITE_ADDR0      = 4'b0001;
    localparam WRITE_ADDR1      = 4'b0011;
    localparam WRITE_ADDR2      = 4'b0010;
    localparam WRITE_ADDR3      = 4'b0110;
    localparam WRITE_ADDR4      = 4'b0111;
    localparam WRITE_ADDR5      = 4'b0101;
    localparam WRITE_ADDR6      = 4'b0100;
    localparam WRITE_ADDR7      = 4'b1100;
    localparam WRITE_ADDR8      = 4'b1101;
//    localparam WRITE_ADDR9      = 4'b1111;
//    localparam WRITE_ADDR10     = 4'b1110;
//    localparam WRITE_ADDR11     = 4'b1010;
//    localparam WRITE_ADDR12     = 4'b1011;
//    localparam WRITE_ADDR13     = 4'b1001;
//    localparam WRITE_ADDR14     = 4'b1000;

    initial begin
        state = WAIT_START;
        next_state = WAIT_START;
        done_inner = 0;
    end
    
    always@(posedge clk)
    begin
        case(next_state)
            WAIT_START: begin
                addr_inner <= 0;
                data_inner <= 0;
                done_inner <= 0;
            end
            WRITE_ADDR0: begin
                addr_inner <= 0;
                data_inner <= 0;
            end
            WRITE_ADDR1: begin
                addr_inner <= 1;
                data_inner <= 1;
            end
            WRITE_ADDR2: begin
                addr_inner <= 2;
                data_inner <= 2;
            end
            WRITE_ADDR3: begin
                addr_inner <= 3;
                data_inner <= 3;
            end
            WRITE_ADDR4: begin
                addr_inner <= 4;
                data_inner <= 4;
            end
            WRITE_ADDR5: begin
                addr_inner <= 5;
                data_inner <= 5;
            end
            WRITE_ADDR6: begin
                addr_inner <= 6;
                data_inner <= 6;
            end
            WRITE_ADDR7: begin
                addr_inner <= 7;
                data_inner <= 7;
                done_inner <= 1;   // one cycle before finishing the write process to eliminate one-cycle delay in the process sequence.
            end
            default: begin
                addr_inner <= 0;
                data_inner <= 0;
            end
        endcase
    end
    
    always@(*)
    begin
        case(state)
            WAIT_START:  next_state = (start)?WRITE_ADDR0:WAIT_START;
            WRITE_ADDR0: next_state = WRITE_ADDR1;
            WRITE_ADDR1: next_state = WRITE_ADDR2;
            WRITE_ADDR2: next_state = WRITE_ADDR3;
            WRITE_ADDR3: next_state = WRITE_ADDR4;
            WRITE_ADDR4: next_state = WRITE_ADDR5;
            WRITE_ADDR5: next_state = WRITE_ADDR6;
            WRITE_ADDR6: next_state = WRITE_ADDR7;
            WRITE_ADDR7: next_state = WAIT_START;
            default :    next_state = WAIT_START;
        endcase
    end
    
    always@(posedge clk)
    begin
        state <= next_state;
    end
    
    assign data = data_inner;
    assign addr = addr_inner;
    assign done = done_inner;
    
endmodule

////////////////////////////////////////////// READ double buffer
module read_buffer(
input clk,
input start,
output done,
output [5:0] addr,
input  [7:0] data
);

reg read_done;
reg [2:0] state;
reg [2:0] next_state;
reg [5:0] addr_inner;
reg [5:0] addr_data;

localparam STANDBY   = 3'b000;
localparam PREPARE1  = 3'b001;
localparam PREPARE2  = 3'b011;
localparam READ      = 3'b010;
localparam READ_LAST = 3'b110;
reg  [7:0] data_inner[0:7];
reg  cnt;

initial
begin
    cnt = 0;
    state = STANDBY;
    next_state = STANDBY;
    read_done = 0;
end

always@(posedge clk)
begin
    state <= next_state;
end

// output 
always @(posedge clk)
begin
   case(next_state)
        STANDBY:
        begin
            addr_inner <= 0;
            addr_data  <= 0;
            read_done  <= 0;
        end
        
        PREPARE1:
        begin
            addr_inner <= 0;   
            addr_data  <= 0;
        end
        
        PREPARE2:
        begin
            addr_inner <= 1;   
            addr_data  <= 0;
        end
            
        READ:
        begin
            addr_inner <= addr_inner + 1;
            addr_data  <= addr_data + 1;
            data_inner[addr_data] <= data;
        end       
        
        READ_LAST:
        begin
            addr_inner <= 0;
            addr_data  <=  3'b111;
            data_inner[addr_data] <= data;
            read_done  <= 1;
        end 
        default:  state <= STANDBY;
   endcase
end

// state trasient 
always@(*)
begin
    case(state)
        STANDBY:
        begin
            next_state = (start)?PREPARE1:STANDBY;
        end
        
        PREPARE1:
        begin
            next_state = PREPARE2;
        end
        
        PREPARE2:
        begin
            next_state = READ;
        end
        
        READ:
        begin
            next_state = (addr_inner == 3'b111)?READ_LAST:READ;
        end 
        READ_LAST:
        begin
            next_state = (addr_data == 3'b111)?STANDBY:READ_LAST;
        end
        default:  state <= STANDBY;
    endcase
end

assign addr = addr_inner;
assign done = read_done;

endmodule