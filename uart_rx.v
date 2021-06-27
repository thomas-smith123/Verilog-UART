module uart_rx
#(
    parameter           CLK_FRE    =   50  ,//时钟频率(Mhz)
    parameter           BAUD_RATE   =   115200 //波特率(bps)
)
(
    input               clk         ,
    input               rst_n       ,
    input               rx_rxd      ,//接收端口
	 input               rx_data_valid,
    output   reg [7:0]  rx_data     ,//接收1字节数据
	 output reg rx_data_ready
);

localparam  CYCLE = CLK_FRE * 1000000 / BAUD_RATE;
reg         rx_rxd_r        ;
reg         rx_rxd_rr       ;
wire        falling         ;
reg [20:0]  cycle_cnt        ;

//state, 状态机
localparam S_IDLE      =       0;
localparam S_START     =       1;
localparam S_Receive = 2;
localparam S_STOP      =      3;
reg [2:0] state;
reg [3:0] bit_cnt;
//rx_rxd_r, rx_rxd_rr, 打节拍
always @(posedge clk) begin
    rx_rxd_r <= rx_rxd;
    rx_rxd_rr <= rx_rxd_r;
end
//falling, 检测rx_rxd下降沿
assign falling = ~rx_rxd_r & rx_rxd_rr;

always@(posedge clk or negedge rst_n) 
begin
   if(!rst_n) 
	begin
       state <= S_IDLE;
       rx_data_ready <= 1'b0;
    end
    else 
	 begin
        case(state)
            S_IDLE:
	begin
	if(rx_data_valid==0)
		rx_data_ready<=0; 		
                if(falling)
		begin
                    state <= S_START;
			
			rx_data<=7'd0;
		end
	end
            S_START:
                if(cycle_cnt == CYCLE-1)
                    state <= S_Receive;
            S_Receive:
		if(cycle_cnt ==0)
						rx_data[bit_cnt]<=rx_rxd;
					else
						if(cycle_cnt == CYCLE-1 && bit_cnt == 3'd7)
							state<=S_STOP;
            S_STOP:
                if(cycle_cnt == CYCLE-1) 
					 begin
                    state <= S_IDLE;
						rx_data_ready<=1;
						end
            default:
				begin
	if(rx_data_valid==0)
		rx_data_ready<=0;
                state <= S_IDLE;
					 rx_data_ready<=0;
				end					 
        endcase
    end
end
/*******cycle_cnt, 波特率计数器*******/
always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n)
        cycle_cnt <= 'd0;
	else
		if(state==S_IDLE)
			cycle_cnt<=0;
		else
			if(state>=S_START && cycle_cnt <CYCLE-1)
				cycle_cnt<=cycle_cnt+1;
			else
				cycle_cnt<=0;  
end
/*******bit_cnt, 波特率计数器*******/
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
		bit_cnt<=0;
	else
		if(state!=S_Receive)
			bit_cnt<=0;
		else
			if(bit_cnt==7 && cycle_cnt==CYCLE-1)
				bit_cnt<=0;
			else
			if(cycle_cnt==CYCLE-1)
				bit_cnt<=bit_cnt+1;
end
/**************è¯»æ°***************/
		
	
endmodule
