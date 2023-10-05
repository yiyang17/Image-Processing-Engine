
module core (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [ 7:0] o_out_data
);
parameter LOAD_IMAGE = 5'd0;
parameter RIGHT_SHIFT = 5'd1;
parameter LEFT_SHIFT = 5'd2;
parameter UP_SHIFT = 5'd3;
parameter DOWN_SHIFT = 5'd4;
parameter KERNEL_UP = 5'd5;
parameter KERNEL_DOWN = 5'd6;
parameter MAX = 5'd7;
parameter MIN = 5'd8;
parameter MEDIAN = 5'd9;
parameter BLUR = 5'd10;
parameter REC_POS1 = 5'd11;
parameter REC_POS2 = 5'd12;
parameter REC_POS3 = 5'd13;
parameter DISPLAY_TRI = 5'd14;
parameter RESET = 5'd15;
parameter FINISH = 5'd16;
parameter READY = 5'd17;
parameter LOAD_FINISH = 5'd18;
parameter OP_FINISH = 5'd19;
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //

reg [4:0] state, nxt_state;
reg [3:0] op_mode, nxt_op_mode;
reg 	  op_valid, nxt_op_valid;
reg [7:0] image_register [0:256-1];
reg [7:0] nxt_image_register [0:256-1];
reg [3:0] shift_x, nxt_shift_x;
reg [3:0] shift_y, nxt_shift_y; 
reg [7:0] counter, nxt_counter;

reg [4:0] kernel_pos_x [0:8];
reg [4:0] nxt_kernel_pos_x [0:8];
reg [4:0] kernel_pos_y [0:8];
reg [4:0] nxt_kernel_pos_y [0:8];
reg [7:0] group1_max;
reg [7:0] group2_max;
reg [7:0] group3_max;
reg [7:0] group4_max;
reg [7:0] group5_max;
reg [7:0] group6_max;
reg [7:0] group7_max;
reg [7:0] group_max;
reg [7:0] group1_min;
reg [7:0] group2_min;
reg [7:0] group3_min;
reg [7:0] group4_min;
reg [7:0] group5_min;
reg [7:0] group6_min;
reg [7:0] group7_min;
reg [7:0] group_min;
reg [7:0] pos_index [0:8];
reg       nxt_kernel_adjust, kernel_adjust;
reg 	  nxt_op_ready, op_ready;
reg 	  nxt_in_ready, in_ready;
reg 	  nxt_out_valid, out_valid;
reg [7:0] nxt_out_data, out_data;
reg [11:0] conv_result;
reg	        row1_p0_p1; 
reg	        row1_p0_p2; 
reg	        row1_p1_p2; 
reg	        row1_p3_p4; 
reg	        row1_p3_p5;
reg	        row1_p4_p5; 
reg	        row1_p6_p7; 
reg	        row1_p6_p8;
reg	        row1_p7_p8; 
reg [7:0]   sort_row1_p0;
reg [7:0]	sort_row1_p1;
reg [7:0]   sort_row1_p2;
reg [7:0]	sort_row1_p3;
reg [7:0]   sort_row1_p4;
reg [7:0]	sort_row1_p5;
reg [7:0]   sort_row1_p6;
reg [7:0]	sort_row1_p7;
reg [7:0]	sort_row1_p8;
reg			sort_p0_p3;
reg			sort_p0_p6;
reg			sort_p3_p6;
reg			sort_p1_p4;
reg			sort_p1_p7;
reg			sort_p4_p7;
reg			sort_p2_p5;
reg			sort_p2_p8;
reg			sort_p5_p8;
reg [7:0]	nxt_sort_col_p0, sort_col_p0;
reg [7:0]	nxt_sort_col_p1, sort_col_p1;
reg [7:0]	nxt_sort_col_p2, sort_col_p2;
reg [7:0]	nxt_sort_col_p3, sort_col_p3;
reg [7:0]	nxt_sort_col_p4, sort_col_p4;
reg [7:0]	nxt_sort_col_p5, sort_col_p5;
reg [7:0]	nxt_sort_col_p6, sort_col_p6;
reg [7:0]	nxt_sort_col_p7, sort_col_p7;
reg [7:0]	nxt_sort_col_p8, sort_col_p8;
reg 		nxt_med_counter, med_counter;
reg			diag_p2_p4;
reg			diag_p2_p6;
reg			diag_p4_p6;
//reg [7:0]   diag_p2;
reg [7:0]	diag_p4;
//reg [7:0]	diag_p6;
reg [3:0]	nxt_pos1_x, pos1_x;
reg [3:0]	nxt_pos1_y, pos1_y;
reg [3:0]	nxt_pos2_x, pos2_x;
reg [3:0]	nxt_pos2_y, pos2_y;
reg [3:0]	nxt_pos3_x, pos3_x;
reg [3:0]	nxt_pos3_y, pos3_y;
reg [3:0]	nxt_a, a;
reg [3:0]	nxt_b, b;
reg [7:0]	nxt_c, c;
reg [7:0]	display_index;
reg			display;
reg [4:0]	nxt_pos_x, pos_x;
reg [4:0]	nxt_pos_y, pos_y;
reg [4:0]	nxt_display_counter, display_counter;
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign o_op_ready = op_ready;
assign o_in_ready = in_ready;
assign o_out_valid = out_valid;
assign o_out_data = out_data;
// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
// Finite state machine
always@(*) begin
	nxt_op_ready = 1'b0;
	nxt_in_ready = 1'b0;
	nxt_out_valid = 1'b0;
	case (state) //synopsys parallel_case
		RESET: begin //strange why the nxt_state doesn't change when i_rst_n = 1 ?
			if (i_rst_n) begin 
				nxt_op_ready = 1'b1;
				nxt_state = FINISH;
			end
			else nxt_op_ready = 1'b0;
				nxt_state = FINISH;
			end
		FINISH: begin
			nxt_state = READY;
		end
		READY: begin
			if (i_op_valid) begin
				nxt_in_ready = 1'b0;
				case (i_op_mode)
					4'd0: begin
						nxt_state = LOAD_IMAGE;
						nxt_in_ready = 1'b1;
					end
					4'd1: nxt_state = RIGHT_SHIFT;
					4'd2: nxt_state = LEFT_SHIFT;
					4'd3: nxt_state = UP_SHIFT;
					4'd4: nxt_state = DOWN_SHIFT;
					4'd5: nxt_state = KERNEL_UP;
					4'd6: nxt_state = KERNEL_DOWN;
					4'd7: nxt_state = MAX;
					4'd8: nxt_state = MIN;
					4'd9: nxt_state = MEDIAN;
					4'd10: nxt_state = BLUR;
					4'd11: nxt_state = REC_POS1;
					4'd12: nxt_state = REC_POS2;
					4'd13: nxt_state = REC_POS3;
					4'd14: nxt_state = DISPLAY_TRI;
					default: nxt_state = READY;
				endcase
			end
			else begin
				nxt_state = READY;
			end
			
		end
		LOAD_IMAGE: begin
			nxt_in_ready = 1'b1;
			if (counter == 8'd255) nxt_state = LOAD_FINISH;
			else nxt_state = LOAD_IMAGE;
		end
		LOAD_FINISH: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		RIGHT_SHIFT: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		LEFT_SHIFT: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		UP_SHIFT: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		DOWN_SHIFT: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		KERNEL_UP: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		KERNEL_DOWN: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		MAX: begin
			nxt_op_ready = 1'b0;
			nxt_state = OP_FINISH;
			nxt_out_valid = 1'b1;
		end
		MIN: begin
			nxt_op_ready = 1'b0;
			nxt_state = OP_FINISH;
			nxt_out_valid = 1'b1;
		end
		MEDIAN: begin
			if (med_counter) begin
				nxt_op_ready = 1'b0;
				nxt_state = OP_FINISH;
				nxt_out_valid = 1'b1;
			end
			else begin
				nxt_op_ready = 1'b0;
				nxt_state = MEDIAN;
				nxt_out_valid = 1'b0;
			end
		end
		BLUR: begin
			nxt_op_ready = 1'b0;
			nxt_state = OP_FINISH;
			nxt_out_valid = 1'b1;
		end
		OP_FINISH: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		REC_POS1: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		REC_POS2: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		REC_POS3: begin
			nxt_op_ready = 1'b1;
			nxt_state = FINISH;
		end
		DISPLAY_TRI: begin
			if (display_counter > (pos3_y-pos1_y)) begin
				nxt_state = FINISH;
				nxt_op_ready = 1'b1;
			end
			else begin
				if (display) begin
					nxt_state = DISPLAY_TRI;
					nxt_out_valid = 1'b1;
				end
				else begin
					nxt_state = DISPLAY_TRI;
					nxt_out_valid = 1'b0;
				end
			end
		end
		default: begin
			nxt_op_ready = 1'b0;
			nxt_state = FINISH;
			nxt_in_ready = 1'b0;
			nxt_out_valid = 1'b0;
		end
	endcase
end
//always@(*) begin
//	nxt_op_valid = i_op_valid;
//	nxt_op_mode = i_op_mode;
//end
// Counter 
always@(*) begin
	case (state)
		LOAD_IMAGE: begin
			if (i_in_valid) nxt_counter = counter + 1;
			else 			nxt_counter = counter;
		end
		default: nxt_counter = counter;
	endcase
end
always@(*) begin
	case (state)
		MEDIAN: begin
			nxt_med_counter = med_counter + 1;
		end
		default: nxt_med_counter = med_counter;
	endcase
end
// Load image inside
integer k;
always@(*) begin
	case (state) 
		LOAD_IMAGE: begin
			if (i_in_valid) begin
				for (k=0;k<256;k=k+1) begin
					if (k == counter) nxt_image_register[k] = i_in_data;
					else nxt_image_register[k] = image_register[k]; 
				end
			end
			else begin
				for (k=0;k<256;k=k+1) begin
					nxt_image_register[k] = image_register[k]; 
				end
			end
		end
		default: begin
			for (k=0;k<256;k=k+1) begin
					nxt_image_register[k] = image_register[k]; 
			end
		end
	endcase
end
// SHIFT
always@(*) begin
	nxt_shift_x = shift_x;
	nxt_shift_y = shift_y;
	case (state)
		RIGHT_SHIFT: begin
			if (shift_x == 4'b1111) nxt_shift_x = shift_x;
			else nxt_shift_x = shift_x + 1;
		end
		LEFT_SHIFT: begin
			if (shift_x == 4'b0000) nxt_shift_x = shift_x;
			else nxt_shift_x = shift_x - 1;
		end
		UP_SHIFT: begin
			if (shift_y == 4'b0000) nxt_shift_y = shift_y;
			else nxt_shift_y = shift_y - 1;
		end
		DOWN_SHIFT: begin
			if (shift_y == 4'b1111) nxt_shift_y = shift_y;
			else nxt_shift_y = shift_y + 1;
		end
		default: begin
			nxt_shift_x = shift_x;
			nxt_shift_y = shift_y;
		end
	endcase
end
// 

always@(*) begin
	 //nxt_kernel_pos_x 不知道k可不可以用在case，要試試看才知道
	for (k=0;k<9;k=k+1) begin
		case (k)
			0: begin
				if (kernel_adjust) begin
					nxt_kernel_pos_x[k] = shift_x;
					nxt_kernel_pos_y[k] = shift_y;
				end
				else begin
					nxt_kernel_pos_x[k] = shift_x + 4'd1;
					nxt_kernel_pos_y[k] = shift_y + 4'd1;
				end
			end
			1: begin
				if (kernel_adjust) begin
					nxt_kernel_pos_x[k] = shift_x + 4'd2;
					nxt_kernel_pos_y[k] = shift_y;
				end
				else begin
					nxt_kernel_pos_x[k] = shift_x + 4'd2;
					nxt_kernel_pos_y[k] = shift_y + 4'd1;
				end
			end
			2: begin
				if (kernel_adjust) begin
					nxt_kernel_pos_x[k] = shift_x + 4'd4;
					nxt_kernel_pos_y[k] = shift_y;
				end
				else begin
					nxt_kernel_pos_x[k] = shift_x + 4'd3;
					nxt_kernel_pos_y[k] = shift_y + 4'd1;
				end
			end
			3: begin
				if (kernel_adjust) begin
					nxt_kernel_pos_x[k] = shift_x;
					nxt_kernel_pos_y[k] = shift_y + 4'd2;
				end
				else begin
					nxt_kernel_pos_x[k] = shift_x + 4'd1;
					nxt_kernel_pos_y[k] = shift_y + 4'd2;
				end
			end
			4: begin
				if (kernel_adjust) begin
					nxt_kernel_pos_x[k] = shift_x + 4'd2;
					nxt_kernel_pos_y[k] = shift_y + 4'd2;
				end
				else begin
					nxt_kernel_pos_x[k] = shift_x + 4'd2;
					nxt_kernel_pos_y[k] = shift_y + 4'd2;
				end
			end
			5: begin
				if (kernel_adjust) begin
					nxt_kernel_pos_x[k] = shift_x + 4'd4;
					nxt_kernel_pos_y[k] = shift_y + 4'd2;
				end
				else begin
					nxt_kernel_pos_x[k] = shift_x + 4'd3;
					nxt_kernel_pos_y[k] = shift_y + 4'd2;
				end
			end
			6: begin
				if (kernel_adjust) begin
					nxt_kernel_pos_x[k] = shift_x;
					nxt_kernel_pos_y[k] = shift_y + 4'd4;
				end
				else begin
					nxt_kernel_pos_x[k] = shift_x + 4'd1;
					nxt_kernel_pos_y[k] = shift_y + 4'd3;
				end
			end
			7: begin
				if (kernel_adjust) begin
					nxt_kernel_pos_x[k] = shift_x + 4'd2;
					nxt_kernel_pos_y[k] = shift_y + 4'd4;
				end
				else begin
					nxt_kernel_pos_x[k] = shift_x + 4'd2;
					nxt_kernel_pos_y[k] = shift_y + 4'd3;
				end
			end
			8: begin
				if (kernel_adjust) begin
					nxt_kernel_pos_x[k] = shift_x + 4'd4;
					nxt_kernel_pos_y[k] = shift_y + 4'd4;
				end
				else begin
					nxt_kernel_pos_x[k] = shift_x + 4'd3;
					nxt_kernel_pos_y[k] = shift_y + 4'd3;
				end
			end
		endcase
	end
end

// 我知道真的好難、你也已經很累了！那我們就一起把這個測試一下吧
// 我有好多問題要透過嘗試才知道答案，但時間卻不夠！
// strange when x = 1, y = 1
always@(*) begin
	for (k=0;k<9;k=k+1) begin
		if ((kernel_pos_x[k] < 5'd2) && (kernel_pos_y[k] < 5'd2)) 
			pos_index[k] = 8'd0;
		else if ((kernel_pos_x[k] < 5'd2) && ((kernel_pos_y[k] > 5'd1) && (kernel_pos_y[k] < 5'd18))) 
			pos_index[k] = (kernel_pos_y[k] - 5'd2)* 5'd16;
		else if (((kernel_pos_x[k] < 5'd18) && (kernel_pos_x[k] > 5'd1)) && (kernel_pos_y[k] < 5'd2))
			pos_index[k] = kernel_pos_x[k] - 5'd2 ;
		else if ((kernel_pos_x[k] > 5'd17) && (kernel_pos_y[k] < 5'd2))
			pos_index[k] = 8'd15;
		else if ((kernel_pos_x[k] > 5'd17) && ((kernel_pos_y[k] > 5'd1) && (kernel_pos_y[k] < 5'd18)))
			pos_index[k] = (kernel_pos_y[k] - 5'd1)* 5'd16 - 8'd1;
		else if ((kernel_pos_x[k] > 5'd17) && (kernel_pos_y[k] > 5'd17))
			pos_index[k] = 8'd255;
		else if (((kernel_pos_x[k] > 5'd1) && (kernel_pos_x[k] < 5'd18)) && (kernel_pos_y[k] > 5'd17))
			pos_index[k] = 8'd240 + kernel_pos_x[k] - 5'd2;
		else if ((kernel_pos_x[k] < 5'd2) && (kernel_pos_y[k] > 5'd17))
			pos_index[k] = 8'd240;
		else if (((kernel_pos_x[k] < 5'd18) && (kernel_pos_x[k] > 5'd1)) && ((kernel_pos_y[k] < 5'd18) && (kernel_pos_y[k] > 5'd1)))
			pos_index[k] = (kernel_pos_y[k] - 5'd2) * 5'd16 + kernel_pos_x[k] - 5'd2;
		else pos_index[k] = 8'd0;
	end
end
// Kernel size adjust 42+20*x+y
always@(*) begin
	case (state)
		KERNEL_UP: 		nxt_kernel_adjust = 1'b1;
		KERNEL_DOWN: 	nxt_kernel_adjust = 1'b0;
		default: 		nxt_kernel_adjust = kernel_adjust;
	endcase
end
// record position
always@(*) begin
	case (state)
		REC_POS1: begin 
			nxt_pos1_x = shift_x;
			nxt_pos1_y = shift_y;
			nxt_pos2_x = pos2_x;
			nxt_pos2_y = pos2_y;
			nxt_pos3_x = pos3_x;
			nxt_pos3_y = pos3_y;
		end
		REC_POS2: begin 
			nxt_pos1_x = pos1_x;
			nxt_pos1_y = pos1_y;
			nxt_pos2_x = shift_x;
			nxt_pos2_y = shift_y;
			nxt_pos3_x = pos3_x;
			nxt_pos3_y = pos3_y;
		end
		REC_POS3: begin 
			nxt_pos1_x = pos1_x;
			nxt_pos1_y = pos1_y;
			nxt_pos2_x = pos2_x;
			nxt_pos2_y = pos2_y;
			nxt_pos3_x = shift_x;
			nxt_pos3_y = shift_y;
		end
		default: begin
			nxt_pos1_x = pos1_x;
			nxt_pos1_y = pos1_y;
			nxt_pos2_x = pos2_x;
			nxt_pos2_y = pos2_y;
			nxt_pos3_x = pos3_x;
			nxt_pos3_y = pos3_y;
		end
	endcase
end
// display triangle
always@(*) begin
	display_index = (5'd16 * pos_y) + pos_x;
	case(state)
		DISPLAY_TRI: begin
			nxt_a = a;
			nxt_b = b;
			nxt_c = c;
			if ((a * pos_x) + (b * pos_y) > c) begin
				nxt_display_counter = display_counter + 1;
				nxt_pos_x = pos1_x;
				nxt_pos_y = pos1_y + display_counter + 1;
				display = 1'b0;
			end
			else begin
				nxt_display_counter = display_counter;
				nxt_pos_x = pos_x + 1;
				nxt_pos_y = pos1_y + display_counter;
				display = 1'b1;
			end
		end
		default: begin
			nxt_pos_x = pos1_x;
			nxt_pos_y = pos1_y;
			nxt_a = pos3_y - pos2_y;
			nxt_b = pos2_x - pos3_x;
			nxt_c = (pos2_x * pos3_y) - (pos3_x * pos2_y);
			nxt_display_counter = 5'd0;
			display = 1'b0;
		end
	endcase
end
//max/min/median/blur operation
always@(*) begin
	// default group...
	group1_max = 8'd0;
	group2_max = 8'd0;
	group3_max = 8'd0;
	group4_max = 8'd0;
	group5_max = 8'd0;
	group6_max = 8'd0;
	group7_max = 8'd0;
	group_max = 8'd0;
	group1_min = 8'd0;
	group2_min = 8'd0;
	group3_min = 8'd0;
	group4_min = 8'd0;
	group5_min = 8'd0;
	group6_min = 8'd0;
	group7_min = 8'd0;
	group_min = 8'd0;
	row1_p0_p1 = 1'd0;
	row1_p0_p2 = 1'd0;
	row1_p1_p2 = 1'd0;
	row1_p3_p4 = 1'd0;
	row1_p3_p5 = 1'd0;
	row1_p4_p5 = 1'd0;
	row1_p6_p7 = 1'd0;
	row1_p6_p8 = 1'd0;
	row1_p7_p8 = 1'd0;
	sort_row1_p0 = 8'd0;
	sort_row1_p1 = 8'd0;
	sort_row1_p2 = 8'd0;
	sort_row1_p3 = 8'd0;
	sort_row1_p4 = 8'd0;
	sort_row1_p5 = 8'd0;
	sort_row1_p6 = 8'd0;
	sort_row1_p7 = 8'd0;
	sort_row1_p8 = 8'd0;
	sort_p0_p3 = 1'd0;
	sort_p0_p6 = 1'd0;
	sort_p3_p6 = 1'd0;
	sort_p1_p4 = 1'd0;
	sort_p1_p7 = 1'd0;
	sort_p4_p7 = 1'd0;
	sort_p2_p5 = 1'd0;
	sort_p2_p8 = 1'd0;
	sort_p5_p8 = 1'd0;
	nxt_sort_col_p0 = 8'd0;
	nxt_sort_col_p3 = 8'd0;
	nxt_sort_col_p6 = 8'd0;
	nxt_sort_col_p1 = 8'd0;
	nxt_sort_col_p4 = 8'd0;
	nxt_sort_col_p7 = 8'd0;
	nxt_sort_col_p2 = 8'd0;
	nxt_sort_col_p5 = 8'd0;
	nxt_sort_col_p8 = 8'd0;
	diag_p2_p4 = 1'd0;
	diag_p2_p6 = 1'd0;
	diag_p4_p6 = 1'd0;
	//diag_p2 = 8'd0;
	diag_p4 = 8'd0;
	//diag_p6 = 8'd0;
	conv_result = 12'd0;
	case (state) 
		// module 
		MAX: begin
			group1_max = (image_register[pos_index[0]]>image_register[pos_index[1]]) ? image_register[pos_index[0]] : image_register[pos_index[1]];
			group2_max = (image_register[pos_index[2]]>image_register[pos_index[3]]) ? image_register[pos_index[2]] : image_register[pos_index[3]];
			group3_max = (image_register[pos_index[4]]>image_register[pos_index[5]]) ? image_register[pos_index[4]] : image_register[pos_index[5]];
			group4_max = (image_register[pos_index[6]]>image_register[pos_index[7]]) ? image_register[pos_index[6]] : image_register[pos_index[7]];
			group5_max = (group1_max > group2_max) ? group1_max : group2_max;
			group6_max = (group3_max > group4_max) ? group3_max : group4_max;
			group7_max = (group5_max > group6_max) ? group5_max : group6_max;
			group_max = (group7_max > image_register[pos_index[8]]) ? group7_max : image_register[pos_index[8]];
		end
		MIN: begin
			group1_min = (image_register[pos_index[0]]>image_register[pos_index[1]]) ? image_register[pos_index[1]] : image_register[pos_index[0]];
			group2_min = (image_register[pos_index[2]]>image_register[pos_index[3]]) ? image_register[pos_index[3]] : image_register[pos_index[2]];
			group3_min = (image_register[pos_index[4]]>image_register[pos_index[5]]) ? image_register[pos_index[5]] : image_register[pos_index[4]];
			group4_min = (image_register[pos_index[6]]>image_register[pos_index[7]]) ? image_register[pos_index[7]] : image_register[pos_index[6]];
			group5_min = (group1_min > group2_min) ? group2_min : group1_min;
			group6_min = (group3_min > group4_min) ? group4_min : group3_min;
			group7_min = (group5_min > group6_min) ? group6_min : group5_min;
			group_min = (group7_min > image_register[pos_index[8]]) ? image_register[pos_index[8]] : group7_min ;
		end
		MEDIAN: begin
			row1_p0_p1 = image_register[pos_index[0]] > image_register[pos_index[1]];
			row1_p0_p2 = image_register[pos_index[0]] > image_register[pos_index[2]];
			row1_p1_p2 = image_register[pos_index[1]] > image_register[pos_index[2]];
			row1_p3_p4 = image_register[pos_index[3]] > image_register[pos_index[4]];
			row1_p3_p5 = image_register[pos_index[3]] > image_register[pos_index[5]];
			row1_p4_p5 = image_register[pos_index[4]] > image_register[pos_index[5]];
			row1_p6_p7 = image_register[pos_index[6]] > image_register[pos_index[7]];
			row1_p6_p8 = image_register[pos_index[6]] > image_register[pos_index[8]];
			row1_p7_p8 = image_register[pos_index[7]] > image_register[pos_index[8]];
			case ({row1_p0_p1,row1_p0_p2,row1_p1_p2}) 
				3'b000:	begin
					sort_row1_p0 = image_register[pos_index[0]];
					sort_row1_p1 = image_register[pos_index[1]];
					sort_row1_p2 = image_register[pos_index[2]];
				end
				3'b001:begin
					sort_row1_p0 = image_register[pos_index[0]];
					sort_row1_p1 = image_register[pos_index[2]];
					sort_row1_p2 = image_register[pos_index[1]];
				end
				3'b011: begin
					sort_row1_p0 = image_register[pos_index[2]];
					sort_row1_p1 = image_register[pos_index[0]];
					sort_row1_p2 = image_register[pos_index[1]];
				end
				3'b100: begin
					sort_row1_p0 = image_register[pos_index[1]];
					sort_row1_p1 = image_register[pos_index[0]];
					sort_row1_p2 = image_register[pos_index[2]];
				end
				3'b110: begin
					sort_row1_p0 = image_register[pos_index[1]];
					sort_row1_p1 = image_register[pos_index[2]];
					sort_row1_p2 = image_register[pos_index[0]];
				end
				3'b111: begin
					sort_row1_p0 = image_register[pos_index[2]];
					sort_row1_p1 = image_register[pos_index[1]];
					sort_row1_p2 = image_register[pos_index[0]];
				end
				default: begin
					sort_row1_p0 = 8'd0;
					sort_row1_p1 = 8'd0;
					sort_row1_p2 = 8'd0;
				end
			endcase
			case ({row1_p3_p4,row1_p3_p5,row1_p4_p5})
				3'b000:	begin
					sort_row1_p3 = image_register[pos_index[3]];
					sort_row1_p4 = image_register[pos_index[4]];
					sort_row1_p5 = image_register[pos_index[5]];
				end
				3'b001:begin
					sort_row1_p3 = image_register[pos_index[3]];
					sort_row1_p4 = image_register[pos_index[5]];
					sort_row1_p5 = image_register[pos_index[4]];
				end
				3'b011: begin
					sort_row1_p3 = image_register[pos_index[5]];
					sort_row1_p4 = image_register[pos_index[3]];
					sort_row1_p5 = image_register[pos_index[4]];
				end
				3'b100: begin
					sort_row1_p3 = image_register[pos_index[4]];
					sort_row1_p4 = image_register[pos_index[3]];
					sort_row1_p5 = image_register[pos_index[5]];
				end
				3'b110: begin
					sort_row1_p3 = image_register[pos_index[4]];
					sort_row1_p4 = image_register[pos_index[5]];
					sort_row1_p5 = image_register[pos_index[3]];
				end
				3'b111: begin
					sort_row1_p3 = image_register[pos_index[5]];
					sort_row1_p4 = image_register[pos_index[4]];
					sort_row1_p5 = image_register[pos_index[3]];
				end
				default: begin
					sort_row1_p3 = 8'd0;
					sort_row1_p4 = 8'd0;
					sort_row1_p5 = 8'd0;
				end
			endcase
			case ({row1_p6_p7,row1_p6_p8,row1_p7_p8})
				3'b000:	begin
					sort_row1_p6 = image_register[pos_index[6]];
					sort_row1_p7 = image_register[pos_index[7]];
					sort_row1_p8 = image_register[pos_index[8]];
				end
				3'b001:begin
					sort_row1_p6 = image_register[pos_index[6]];
					sort_row1_p7 = image_register[pos_index[8]];
					sort_row1_p8 = image_register[pos_index[7]];
				end
				3'b011: begin
					sort_row1_p6 = image_register[pos_index[8]];
					sort_row1_p7 = image_register[pos_index[6]];
					sort_row1_p8 = image_register[pos_index[7]];
				end
				3'b100: begin
					sort_row1_p6 = image_register[pos_index[7]];
					sort_row1_p7 = image_register[pos_index[6]];
					sort_row1_p8 = image_register[pos_index[8]];
				end
				3'b110: begin
					sort_row1_p6 = image_register[pos_index[7]];
					sort_row1_p7 = image_register[pos_index[8]];
					sort_row1_p8 = image_register[pos_index[6]];
				end
				3'b111: begin
					sort_row1_p6 = image_register[pos_index[8]];
					sort_row1_p7 = image_register[pos_index[7]];
					sort_row1_p8 = image_register[pos_index[6]];
				end
				default: begin
					sort_row1_p6 = 8'd0;
					sort_row1_p7 = 8'd0;
					sort_row1_p8 = 8'd0;
				end
			endcase
			sort_p0_p3 = sort_row1_p0 > sort_row1_p3;
			sort_p0_p6 = sort_row1_p0 > sort_row1_p6;
			sort_p3_p6 = sort_row1_p3 > sort_row1_p6;
			sort_p1_p4 = sort_row1_p1 > sort_row1_p4;
			sort_p1_p7 = sort_row1_p1 > sort_row1_p7;
			sort_p4_p7 = sort_row1_p4 > sort_row1_p7;
			sort_p2_p5 = sort_row1_p2 > sort_row1_p5;
			sort_p2_p8 = sort_row1_p2 > sort_row1_p8;
			sort_p5_p8 = sort_row1_p5 > sort_row1_p8;
			case ({sort_p0_p3,sort_p0_p6,sort_p3_p6})
				3'b000:	begin
					nxt_sort_col_p0 = sort_row1_p0;
					nxt_sort_col_p3 = sort_row1_p3;
					nxt_sort_col_p6 = sort_row1_p6;
				end
				3'b001:begin
					nxt_sort_col_p0 = sort_row1_p0;
					nxt_sort_col_p3 = sort_row1_p6;
					nxt_sort_col_p6 = sort_row1_p3;
				end
				3'b011: begin
					nxt_sort_col_p0 = sort_row1_p6;
					nxt_sort_col_p3 = sort_row1_p0;
					nxt_sort_col_p6 = sort_row1_p3;
				end
				3'b100: begin
					nxt_sort_col_p0 = sort_row1_p3;
					nxt_sort_col_p3 = sort_row1_p0;
					nxt_sort_col_p6 = sort_row1_p6;
				end
				3'b110: begin
					nxt_sort_col_p0 = sort_row1_p3;
					nxt_sort_col_p3 = sort_row1_p6;
					nxt_sort_col_p6 = sort_row1_p0;
				end
				3'b111: begin
					nxt_sort_col_p0 = sort_row1_p6;
					nxt_sort_col_p3 = sort_row1_p3;
					nxt_sort_col_p6 = sort_row1_p0;
				end
				default: begin
					nxt_sort_col_p0 = 8'd0;
					nxt_sort_col_p3 = 8'd0;
					nxt_sort_col_p6 = 8'd0;
				end
			endcase
			case ({sort_p1_p4,sort_p1_p7,sort_p4_p7})
				3'b000:	begin
					nxt_sort_col_p1 = sort_row1_p1;
					nxt_sort_col_p4 = sort_row1_p4;
					nxt_sort_col_p7 = sort_row1_p7;
				end
				3'b001:begin
					nxt_sort_col_p1 = sort_row1_p1;
					nxt_sort_col_p4 = sort_row1_p7;
					nxt_sort_col_p7 = sort_row1_p4;
				end
				3'b011: begin
					nxt_sort_col_p1 = sort_row1_p7;
					nxt_sort_col_p4 = sort_row1_p1;
					nxt_sort_col_p7 = sort_row1_p4;
				end
				3'b100: begin
					nxt_sort_col_p1 = sort_row1_p4;
					nxt_sort_col_p4 = sort_row1_p1;
					nxt_sort_col_p7 = sort_row1_p7;
				end
				3'b110: begin
					nxt_sort_col_p1 = sort_row1_p4;
					nxt_sort_col_p4 = sort_row1_p7;
					nxt_sort_col_p7 = sort_row1_p1;
				end
				3'b111: begin
					nxt_sort_col_p1 = sort_row1_p7;
					nxt_sort_col_p4 = sort_row1_p4;
					nxt_sort_col_p7 = sort_row1_p1;
				end
				default: begin
					nxt_sort_col_p1 = 8'd0;
					nxt_sort_col_p4 = 8'd0;
					nxt_sort_col_p7 = 8'd0;
				end
			endcase 
			case ({sort_p2_p5,sort_p2_p8,sort_p5_p8})
				3'b000:	begin
					nxt_sort_col_p2 = sort_row1_p2;
					nxt_sort_col_p5 = sort_row1_p5;
					nxt_sort_col_p8 = sort_row1_p8;
				end
				3'b001:begin
					nxt_sort_col_p2 = sort_row1_p2;
					nxt_sort_col_p5 = sort_row1_p8;
					nxt_sort_col_p8 = sort_row1_p5;
				end
				3'b011: begin
					nxt_sort_col_p2 = sort_row1_p8;
					nxt_sort_col_p5 = sort_row1_p2;
					nxt_sort_col_p8 = sort_row1_p5;
				end
				3'b100: begin
					nxt_sort_col_p2 = sort_row1_p5;
					nxt_sort_col_p5 = sort_row1_p2;
					nxt_sort_col_p8 = sort_row1_p8;
				end
				3'b110: begin
					nxt_sort_col_p2 = sort_row1_p5;
					nxt_sort_col_p5 = sort_row1_p8;
					nxt_sort_col_p8 = sort_row1_p2;
				end
				3'b111: begin
					nxt_sort_col_p2 = sort_row1_p8;
					nxt_sort_col_p5 = sort_row1_p5;
					nxt_sort_col_p8 = sort_row1_p2;
				end
				default: begin
					nxt_sort_col_p2 = 8'd0;
					nxt_sort_col_p5 = 8'd0;
					nxt_sort_col_p8 = 8'd0;
				end
			endcase
			diag_p2_p4 = sort_col_p2 > sort_col_p4;
			diag_p2_p6 = sort_col_p2 > sort_col_p6;
			diag_p4_p6 = sort_col_p4 > sort_col_p6;
			case({diag_p2_p4,diag_p2_p6,diag_p4_p6})
				3'b000:	begin
					//diag_p2 = sort_col_p2;
					diag_p4 = sort_col_p4;
					//diag_p6 = sort_col_p6;
				end
				3'b001:begin
					//diag_p2 = sort_col_p2;
					diag_p4 = sort_col_p6;
					//diag_p6 = sort_col_p4;
				end
				3'b011: begin
					//diag_p2 = sort_col_p6;
					diag_p4 = sort_col_p2;
					//diag_p6 = sort_col_p4;
				end
				3'b100: begin
					//diag_p2 = sort_col_p4;
					diag_p4 = sort_col_p2;
					//diag_p6 = sort_col_p6;
				end
				3'b110: begin
					//diag_p2 = sort_col_p4;
					diag_p4 = sort_col_p6;
					//diag_p6 = sort_col_p2;
				end
				3'b111: begin
					//diag_p2 = sort_col_p6;
					diag_p4 = sort_col_p4;
					//diag_p6 = sort_col_p2;
				end
				default: begin
					//diag_p2 = 8'd0;
					diag_p4 = 8'd0;
					//diag_p6 = 8'd0;
				end
			endcase
		end
		BLUR: begin
			conv_result = {4'd0,image_register[pos_index[0]]} + {4'd0,image_register[pos_index[2]]} + {4'd0,image_register[pos_index[6]]} + {4'd0,image_register[pos_index[8]]} + {3'd0,image_register[pos_index[1]],1'd0} + {3'd0,image_register[pos_index[3]],1'd0} + {3'd0,image_register[pos_index[5]],1'd0} + {3'd0,image_register[pos_index[7]],1'd0} + {2'd0,image_register[pos_index[4]],2'd0};
		end

	endcase
end
always@(*) begin
	case (state) 
		MAX: nxt_out_data = group_max;
		MIN: nxt_out_data = group_min;
		MEDIAN: nxt_out_data = diag_p4;
		BLUR: begin
			if (conv_result[3]) nxt_out_data = conv_result[11:4] + 1'd1;
			else   				nxt_out_data = conv_result[11:4];
		end
		DISPLAY_TRI: nxt_out_data = image_register[display_index];
		default: nxt_out_data = 8'd0;
	endcase
end
// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin // difference between !i_rst_n and ~i_rst_n
		op_ready <= 1'b0;
		state <= RESET;
		for (k=0;k<256;k=k+1) begin
			image_register[k] <= 8'd0;
		end
		shift_x <= 4'd0;
		shift_y <= 4'd0;
		kernel_adjust <= 1'b0;
		counter <= 8'd0;
		in_ready <= 1'b0;
		for (k=0;k<9;k=k+1) begin
			kernel_pos_x[k] <= 5'd0;
			kernel_pos_y[k] <= 5'd0;
		end
		out_valid <= 1'b0;
		out_data <= 8'd0;
		sort_col_p0 <= 8'd0;
		sort_col_p1 <= 8'd0;
		sort_col_p2 <= 8'd0;
		sort_col_p3 <= 8'd0;
		sort_col_p4 <= 8'd0;
		sort_col_p5 <= 8'd0;
		sort_col_p6 <= 8'd0;
		sort_col_p7 <= 8'd0;
		sort_col_p8 <= 8'd0;
		med_counter <= 1'd0;
		pos1_x <= 5'd0;
		pos1_y <= 5'd0;
		pos2_x <= 5'd0;
		pos2_y <= 5'd0;
		pos3_x <= 5'd0;
		pos3_y <= 5'd0;
		pos_x <= 5'd0;
		pos_y <= 5'd0;
		display_counter <= 5'd0;
		a <= 4'd0;
		b <= 4'd0;
		c <= 8'd0;
	end
	else begin
		op_ready <= nxt_op_ready;
		state <= nxt_state;
		for (k=0;k<256;k=k+1) begin
			image_register[k] <= nxt_image_register[k];
		end
		shift_x <= nxt_shift_x;
		shift_y <= nxt_shift_y;
		kernel_adjust <= nxt_kernel_adjust;
		counter <= nxt_counter;
		in_ready <= nxt_in_ready;
		for (k=0;k<9;k=k+1) begin
			kernel_pos_x[k] <= nxt_kernel_pos_x[k];
			kernel_pos_y[k] <= nxt_kernel_pos_y[k];
		end
		out_valid <= nxt_out_valid;
		out_data <= nxt_out_data;
		sort_col_p0 <= nxt_sort_col_p0;
		sort_col_p1 <= nxt_sort_col_p1;
		sort_col_p2 <= nxt_sort_col_p2;
		sort_col_p3 <= nxt_sort_col_p3;
		sort_col_p4 <= nxt_sort_col_p4;
		sort_col_p5 <= nxt_sort_col_p5;
		sort_col_p6 <= nxt_sort_col_p6;
		sort_col_p7 <= nxt_sort_col_p7;
		sort_col_p8 <= nxt_sort_col_p8;
		med_counter <= nxt_med_counter;
		pos1_x <= nxt_pos1_x;
		pos1_y <= nxt_pos1_y;
		pos2_x <= nxt_pos2_x;
		pos2_y <= nxt_pos2_y;
		pos3_x <= nxt_pos3_x;
		pos3_y <= nxt_pos3_y;
		pos_x <= nxt_pos_x;
		pos_y <= nxt_pos_y;
		display_counter <= nxt_display_counter;
		a <= nxt_a;
		b <= nxt_b;
		c <= nxt_c;
	end
end
endmodule
