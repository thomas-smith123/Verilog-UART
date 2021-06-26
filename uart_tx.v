module uart_tx
#(
	parameter CLK_FRE = 50,      //clock frequency(Mhz)
	parameter BAUD_RATE = 115200 //serial baud rate
)
(
	input                        clk,              //clock input
	input                        rst_n,            //asynchronous reset input, low active 
//	input[7:0]                   tx_data,          //data to send
	input                        tx_data_valid,    //data to be sent is valid
	output reg                   tx_data_ready,    //send ready
	output                       tx_pin,            //serial data output
//	output reg[15:0]                        cycle_cnt, //baud counter
output reg[2:0]                         bit_cnt//bit counter
);
//calculates the clock cycle for baud rate 
localparam                       CYCLE = CLK_FRE * 1000000 / BAUD_RATE;
//state machine code
localparam                       S_IDLE       = 1;
localparam                       S_START      = 2;//start bit
localparam                       S_SEND_BYTE  = 3;//data bits
localparam                       S_STOP       = 4;//stop bit
reg [7:0] tx_data;
reg[2:0]                         state;
reg[2:0]                         next_state;
reg[15:0]                        cycle_cnt; //baud counter
//reg[2:0]                         bit_cnt;//bit counter
reg[7:0]                         tx_data_latch; //latch data to send
reg                              tx_reg; //serial data output
assign tx_pin = tx_reg;

initial
begin
	tx_reg<=1;
	tx_data<=8'ha5;
end
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		state <= S_IDLE;
	else
		state <= next_state;
end

always@(posedge clk or negedge rst_n)
begin
	case(state)
		S_IDLE:
			if(tx_data_valid == 1'b1)//触发状态
			begin
				next_state <= S_START;
				 tx_data_ready<=0;
			end
			else
				next_state <= S_IDLE;
		S_START:
			if(cycle_cnt == CYCLE - 1)
				next_state <= S_SEND_BYTE;
			else
				next_state <= S_START;
		S_SEND_BYTE:
			if(cycle_cnt == CYCLE - 1  && bit_cnt == 3'd7)
				next_state <= S_STOP;
			else
				next_state <= S_SEND_BYTE;
		S_STOP:
			if(cycle_cnt == CYCLE - 1)
				begin
				next_state <= S_IDLE;
				tx_data_ready<=1;
				end
			else
				next_state <= S_STOP;
		default:
			next_state <= S_IDLE;
	endcase
end
/****************cnt计数****************/
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		cycle_cnt<=0;
	else
		if(state==S_IDLE)
			cycle_cnt<=0;
		else
			if(state>=S_START && cycle_cnt<CYCLE-1)
				cycle_cnt<=cycle_cnt+1;
			else 
				cycle_cnt<=0;
end
/******************bit计数****************/
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		bit_cnt<=0;
	else
		if(bit_cnt==3'd7 && cycle_cnt==CYCLE-1)
			bit_cnt<=0;
		else
			if(state==S_SEND_BYTE && cycle_cnt==CYCLE-1)
				bit_cnt<=bit_cnt+1;
end
always@(posedge clk or negedge rst_n)
begin
	case(state)
		S_IDLE:
			tx_reg<=1;
		S_START:
			tx_reg<=0;
		S_SEND_BYTE:
			tx_reg<=tx_data[bit_cnt];
		S_STOP:
			tx_reg<=1;
		default:
			tx_reg<=1;
	endcase
end
endmodule
