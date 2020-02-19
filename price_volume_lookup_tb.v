`timescale 1ns / 1ps


module price_volume_lookup_tb;

    localparam MAX_NUMBER_QUERIES = 100;
    localparam NUMBER_OF_LEVELS   = 3;      // TODO: replace with 3 when building price_volume_lookup_new
    localparam MAX_NUMBER_LEVELS  = 3;
    reg clk;
    reg reset_n;
    reg in_valid;
    reg [7:0] in_symbol_index;
    reg [31:0] in_price;

    //CONFIG bus
    reg in_config_valid;
    reg [7:0] in_config_symbol_index;
    reg [NUMBER_OF_LEVELS*32 -1:0] in_config_price;
    reg [NUMBER_OF_LEVELS*32 -1:0] in_config_volume;

    wire out_volume_valid;
    wire [31:0] out_volume;

    //Model in the TB of the contents of the rams
    reg [NUMBER_OF_LEVELS*32 -1:0] price_ram [0:255];
    reg [NUMBER_OF_LEVELS*32 -1:0] volume_ram [0:255];

    //Expected results and captured results
    reg [31:0] expected_volumes_received[0:MAX_NUMBER_QUERIES-1];
    reg [31:0] actual_volumes_received[0:MAX_NUMBER_QUERIES-1];
    integer actual_number_received;
    integer expected_number_received;
    
    //Creats the expected and captures the data.
    //This is done at posedge because that is what the DUT will see/use.
    wire [NUMBER_OF_LEVELS-1:0] price_matched;
    wire any_price_matched;

    price_volume_lookup_new dut_I (        // TODO: Change to "price_volume_lookup_new"
        .clk(clk),
        .reset_n(reset_n),
        .in_valid(in_valid),
        .in_symbol_index(in_symbol_index),
        .in_price(in_price),

        .in_config_valid(in_config_valid),
        .in_config_symbol_index(in_config_symbol_index),
        .in_config_price(in_config_price),
        .in_config_volume(in_config_volume),

        .out_volume_valid(out_volume_valid),
        .out_volume(out_volume)
    );

    //CLOCK DEFINITION
    localparam CLK_PERIOD = 10;
    initial
    begin
        clk = 0;
    end

    always
    begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    //Helper task to pause for N/2 clock cycles.
    task wait_half_clks;
    input a;
    integer a;
    integer b;
        begin
            b=0;
            while (a != b)
            begin
                @(posedge clk or negedge clk);
                b = b + 1;
            end
        end
    endtask

    //WRITES A CONFIG. Note it doesn't take the valid to 0
    task program_config;
    input  [7:0]  index;
    input  [MAX_NUMBER_LEVELS*32-1:0] price;
    input  [MAX_NUMBER_LEVELS*32-1:0] volume;

        begin
            //Add to model
            price_ram[index] = price[NUMBER_OF_LEVELS*32 -1 : 0];
            volume_ram[index] = volume[NUMBER_OF_LEVELS*32 -1 : 0];
            $display ("%g writing TB and DUT RAM at index %g with price %g and volume %g", $time, index, price, volume);
            
            //Drive the Dut
            @ (negedge clk);
            in_config_valid = 1'b1;
            in_config_symbol_index = index;
            in_config_price = price[NUMBER_OF_LEVELS*32 -1 : 0];
            in_config_volume = volume[NUMBER_OF_LEVELS*32 -1 : 0];
        end
    endtask
    
    //WRITES 3 LEVELS
    task program_config3;
        input  [7:0]  index;
        
        input  [31:0] price0;
        input  [31:0] volume0;
        
        input  [31:0] price1;
        input  [31:0] volume1;
        
        input  [31:0] price2;
        input  [31:0] volume2;
    
        reg [3*32 - 1 : 0] all_price;
        reg [3*32 - 1 : 0] all_volume;
        
            begin
              all_price = {price2, price1, price0};
              all_volume = {volume2, volume1, volume0};
                
                //Add to model
                price_ram[index] = all_price;
                volume_ram[index] = all_volume;
                $display ("%g writing TB and DUT RAM at index %g with prices/volume pairs (%g, %g), (%g, %g), (%g, %g), all price %h all volume %h", $time, index, price0, volume0, price1, volume1, price2, volume2, all_price, all_volume);
                
                //Drive the Dut
                @ (negedge clk);
                in_config_valid = 1'b1;
                in_config_symbol_index = index;
                in_config_price = all_price;
                in_config_volume = all_volume;
            end
        endtask

    //Clears the config valid
    task set_to_no_config;
        begin
            $display ("%g driving in_config_valid=0", $time);
            @ (negedge clk);
            in_config_valid = 0;
        end
    endtask

    //Clears the signals to query if a index/price is there. Note it doesn't take the valid to 0
    task query_if_valid;
        input  [7:0] index;
      input  [31:0] price;
        begin
            
          $display ("%g Query Active: querying if index: %g has this price level: %g", $time, index, price);
            @ (negedge clk);
            in_valid = 1;
            in_symbol_index = index;
            in_price = price;
        end
    endtask

    //Clears the in_valid
    task no_query;
        begin
            $display ("%g Query Idle", $time);
            @ (negedge clk);
            in_valid = 0;
        end
    endtask
    
    //Not usually needed but will make the sim cleaner
    task initialize_rams;
    integer i;
    integer index;
    begin
        expected_number_received = 0;
        actual_number_received = 0;
        for (i = 0; i< MAX_NUMBER_QUERIES; i= i+1)
        begin
            expected_volumes_received[i] = 0;
            actual_volumes_received[i] = 0;
        end
        
        for (index = 0; index< 256; index = index+1)
        begin
            price_ram[index] = 0;
            volume_ram[index] = 0;
        end
    end
    endtask;
  
    wire [2:0] level_matched;
    wire [31:0] expected_volume;
    generate
        if (NUMBER_OF_LEVELS == 1)
        begin
            assign level_matched[0] = price_ram[in_symbol_index][31:0] == in_price;
            assign level_matched[1] = 0;
            assign level_matched[2] = 0;
            assign expected_volume = volume_ram[in_symbol_index]; 
        end
        else if (NUMBER_OF_LEVELS == 3)
        begin
            assign level_matched[0] = price_ram[in_symbol_index][31:0] == in_price;
            assign level_matched[1] = price_ram[in_symbol_index][63:32] == in_price;
            assign level_matched[2] = price_ram[in_symbol_index][95:64] == in_price;
            assign expected_volume = level_matched[0] ? volume_ram[in_symbol_index][31:0] :
                                     level_matched[1] ? volume_ram[in_symbol_index][63:32] :
                                     level_matched[2] ? volume_ram[in_symbol_index][95:64] : 0;
        end
    endgenerate
    
    always @(posedge clk)
    begin
        if (reset_n)
        begin
          if (in_valid && (|level_matched))
            begin
                expected_volumes_received[expected_number_received] = expected_volume;              
                expected_number_received = expected_number_received + 1;
            end
            if (out_volume_valid)
            begin
                actual_volumes_received[actual_number_received] = out_volume;
                actual_number_received = actual_number_received + 1;
            end
        end
    end

    initial
    begin
        initialize_rams;
        // Initialize Inputs
        reset_n = 0;
        in_valid = 0;
        in_symbol_index = 0;
        in_price = 0;

        //CONFIG bus
        in_config_valid = 0;
        in_config_symbol_index = 0;
        in_config_price = 0;
        in_config_volume = 0;
        set_to_no_config;

        // Wait 10 clocks ns for global reset to finish
        wait_half_clks(20);
        reset_n = 1;

        wait_half_clks(2);
        program_config(0, 100, 50);  //idx 0, price 100, volume 50
       
        program_config(1, 1000, 51);
        program_config3(0, 100, 50, 110, 10, 120, 30);  // TODO: Uncomment to test 3 price levels
        set_to_no_config;

        wait_half_clks(10);
        query_if_valid(0,100);  //should be found with 50
//        no_query;               // TODO: Remove to test 3 price levels when building with price_volume_lookup_new to remove gaps in in_valid
//        no_query;               // TODO: Remove to test 3 price levels when building with price_volume_lookup_new to remove gaps in in_valid
        query_if_valid(1,1000); //should be found with 51
        query_if_valid(0,110);     // TODO: Uncomment to test 3 price levels
        query_if_valid(0,121); // TODO: Uncomment to test 3 price levels, this query should NOT yield a result.
//       no_query;               // TODO: Remove to test 3 price levels when building with price_volume_lookup_new to remove gaps in in_valid
//        no_query;               // TODO: Remove to test 3 price levels when building with price_volume_lookup_new to remove gaps in in_valid
        //...
        
        wait_half_clks(25);
        compare_results;
        wait_half_clks(5);
        $stop;
   end

    //Checks the results.
    task compare_results;
    integer i;
    reg error;
    begin
        error = 0;
        if (actual_number_received != expected_number_received)
        begin
            error = 1;
            $display ("Number of results should match");
        end
        for (i=0 ; i<actual_number_received; i = i+ 1)
        begin
          $display("Checking result %g: expected: %g, actual: %g", i, expected_volumes_received[i], actual_volumes_received[i]);
          if (expected_volumes_received[i] !== actual_volumes_received[i])
            begin
                error = 1;
                $display("Value of result %g doesn't match.  Expected: %g, Actual: %g", i, expected_volumes_received[i], actual_volumes_received[i]);
            end
        end
        
        if (error)  
        begin 
            $display("Sim failed");
        end
        else
        begin 
            $display("Sim passed");
        end
        
    end
    endtask
endmodule //top

