module ram_lookup #(
    parameter ADDR_WIDTH = 8, 
    parameter DATA_WIDTH = 32   
)(
    input wire clk,
    input wire reset_n, 

    input wire [7 : 0] write_addr,
    input wire [7 : 0] read_addr, 
    input wire [191 : 0] write_data, 
    input wire                    write_enable, 

    output reg [191 : 0] read_data
);

    localparam MEMORY_DEPTH = 2**ADDR_WIDTH;

    reg [191:0] reg_memory [MEMORY_DEPTH - 1 :0];
    reg [191:0] read_data_int;

    always @(posedge clk)
    begin
        if (write_enable)
        begin
            reg_memory[write_addr] <= write_data;
        end
        else
        begin
            read_data_int <= reg_memory[read_addr];
        end
    end

    always @(posedge clk)
    begin
        read_data <=  read_data_int;
    end

endmodule