module price_volume_lookup_new (
    input wire                              clk,
    input wire                              reset_n,
    input wire                              in_valid,
    input wire [7 : 0]                      in_symbol_index,
    input wire [31 : 0]                     in_price,

    //CONFIG bus
    input wire                              in_config_valid,
    input wire [7 : 0]                      in_config_symbol_index,
    input wire [95 : 0]                     in_config_price,
    input wire [95 : 0]                     in_config_volume,


    output reg                              out_volume_valid,
    output reg [31 : 0]                     out_volume
    );

    /***Insert Code here***/
   wire [191 : 0] price_and_volume;
   wire [191 : 0] price_and_volume_config;
   reg [31 : 0]  delay1,delay2;
   
  assign price_and_volume_config = {in_config_volume, in_config_price};
    always @ (posedge(clk))
    begin 
    delay1 <= in_price;
    end
    always @ (posedge(clk))
    begin 
    delay2 <= delay1;
    end
    
    ram_lookup #(
        .ADDR_WIDTH (8),
        .DATA_WIDTH (192)
    ) register_lookup_I(
        .clk                (clk),
        .reset_n            (reset_n),

        .write_addr         (in_config_symbol_index),
        .read_addr          (in_symbol_index),
        .write_data         (price_and_volume_config),
        .write_enable       (in_config_valid),

        .read_data          (price_and_volume)
        );

     
     
    always @(posedge (clk))
    begin
        if(!reset_n) begin
            out_volume_valid <= 1'b0;
            out_volume       <= 32'b0;
        end
        else
        begin
            if (in_valid&& (delay2 == price_and_volume[31:0]))
            begin
                out_volume <= price_and_volume[127:96];
                out_volume_valid <= 1'b1;
                
            end
            else 
             
            if (in_valid&& (delay2 == price_and_volume[63:32]))
            begin 
             out_volume <= price_and_volume[159:128];
             out_volume_valid <= 1'b1;
            end
            else
            if (in_valid&& (delay2 == price_and_volume[95:64]))
            begin 
             out_volume <= price_and_volume[159:128];
             out_volume_valid <= 1'b1;
            end
            else
            if (in_valid&& (delay2 == price_and_volume[159:128]))
            begin 
             out_volume <= price_and_volume[191:160];
             out_volume_valid <= 1'b1;
            end
            else
            begin
                out_volume_valid <= 1'b0;
            end
        end
    end

    endmodule