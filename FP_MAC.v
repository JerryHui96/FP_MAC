`timescale 1ns / 1ps

/*
    Truth Table for Sum and Carry
    A       B       Cin     Sum     Cout
    0       0       0       0       0
    0       0       1       1       0
    0       1       0       1       0
    0       1       1       0       1
    1       0       0       1       0
    1       0       1       0       1
    1       1       0       0       1
    1       1       1       1       1
    
    sum = A XOR B XOR Cin
    Cout = (A & B) | (A & Cin) | (B & Cin)
*/


module FP_MAC(
    input clk, rst,
    input [15:0] A1_x76, A2_x76, A3_x76, A4_x76, A5_x76, A6_x76,
    input [15:0] A7_x76, A8_x76, A9_x76, A10_x76, A11_x76, A12_x76,
    input [15:0] B1_x76, B2_x76, B3_x76, B4_x76, B5_x76, B6_x76,
    input [15:0] B7_x76, B8_x76, B9_x76, B10_x76, B11_x76, B12_x76,
    output [15:0] sum
    );
    
    wire [15:0] P1_x76,P2_x76,P3_x76,P4_x76,P5_x76,P6_x76;
    wire [15:0] P7_x76,P8_x76,P9_x76,P10_x76,P11_x76,P12_x76;
    wire [11:0] f_x76;
    reg PTA_x76; //Proceed to Accumulate
    reg[31:0] i_x76;
    reg [15:0] Acc_input_x76;   //Accumulator Input
    
    
    multiplier m1 (.rst(rst), .clk(clk), .A(A1_x76), .B(B1_x76), .P(P1_x76), .finish(f_x76[0]));
    multiplier m2 (.rst(rst), .clk(clk), .A(A2_x76), .B(B2_x76), .P(P2_x76), .finish(f_x76[1]));
    multiplier m3 (.rst(rst), .clk(clk), .A(A3_x76), .B(B3_x76), .P(P3_x76), .finish(f_x76[2]));
    multiplier m4 (.rst(rst), .clk(clk), .A(A4_x76), .B(B4_x76), .P(P4_x76), .finish(f_x76[3]));
    multiplier m5 (.rst(rst), .clk(clk), .A(A5_x76), .B(B5_x76), .P(P5_x76), .finish(f_x76[4]));
    multiplier m6 (.rst(rst), .clk(clk), .A(A6_x76), .B(B6_x76), .P(P6_x76), .finish(f_x76[5]));
    multiplier m7 (.rst(rst), .clk(clk), .A(A7_x76), .B(B7_x76), .P(P7_x76), .finish(f_x76[6]));
    multiplier m8 (.rst(rst), .clk(clk), .A(A8_x76), .B(B8_x76), .P(P8_x76), .finish(f_x76[7]));
    multiplier m9 (.rst(rst), .clk(clk), .A(A9_x76), .B(B9_x76), .P(P9_x76), .finish(f_x76[8]));
    multiplier m10 (.rst(rst), .clk(clk), .A(A10_x76), .B(B10_x76), .P(P10_x76), .finish(f_x76[9]));
    multiplier m11 (.rst(rst), .clk(clk), .A(A11_x76), .B(B11_x76), .P(P11_x76), .finish(f_x76[10]));
    multiplier m12 (.rst(rst), .clk(clk), .A(A12_x76), .B(B12_x76), .P(P12_x76), .finish(f_x76[11]));
    
    
    
    always @* if(rst) i_x76 <= 0;
    
    always @ (posedge clk) begin
        if(!rst) begin
            PTA_x76 = &f_x76;
            if(PTA_x76) begin
                case (i_x76)
                    0: Acc_input_x76 <= P1_x76;
                    1: Acc_input_x76 <= P2_x76;
                    2: Acc_input_x76 <= P3_x76;
                    3: Acc_input_x76 <= P4_x76;
                    4: Acc_input_x76 <= P5_x76;
                    5: Acc_input_x76 <= P6_x76;
                    6: Acc_input_x76 <= P7_x76;
                    7: Acc_input_x76 <= P8_x76;
                    8: Acc_input_x76 <= P9_x76;
                    9: Acc_input_x76 <= P10_x76;
                    10: Acc_input_x76 <= P11_x76;
                    11: Acc_input_x76 <= P12_x76;
                    12: Acc_input_x76 <= 16'b0;
                    13: Acc_input_x76 <= 16'b1000_0000_0000_0000;
                    default: PTA_x76 = 0;
                endcase
                i_x76 = i_x76 + 1;
            end
        end
    end
        
    accumulate acc( .clk(clk),
                    .rst(rst),
                    .en(PTA_x76),
                    .A(Acc_input_x76),
                    .sum(sum)
                    );
        
endmodule


module accumulate ( input clk, rst, en,
                    input [15:0] A,
                    output [15:0] sum
);

    //Align Stage Regs and Wires
    reg [25:0] aligned_A_x76;       //Stores original input sign and mantissa, and aligned exponent of the sum
    reg [4:0] B_exp_x76;            //Stores aligned exponent of the sum
    reg [5:0] shift_exp_x76;        //Stores info on which mantissa to shift and how many digit to shift.
    wire [25:0] s1_C_x76;
    wire [4:0] s1_S_exp_x76;
    wire [5:0] s1_shift_x76;
    
    //Add Stage Regs and Wires
    reg [25:0] added_sum_x76;
    reg s1_S_sign_reg_x76;
    wire s1_S_sign_x76;
    
    //Normalize Stage Regs and Wires
    wire [25:0] s2_sum_x76;
    
    
    always @* if(rst) begin
        aligned_A_x76 <= 0;
        B_exp_x76 <= 0;
        shift_exp_x76 <= 0;
        s1_S_sign_reg_x76 <= 0;
        added_sum_x76 <= 0;
    end
    
    // Calculates the preliminary exponent for sum and the amount of shifts needed for Add Stage
    align a1(   .en(en),
                .rst(rst),
                .A(A),
                .B_exp(B_exp_x76), 
                .C(s1_C_x76), 
                .S_exp(s1_S_exp_x76), 
                .shift(s1_shift_x76)
                );
    
    
    add a2( .en(en),
            .rst(rst),
            .A(aligned_A_x76),
            .B(added_sum_x76),
            .shift_exp(shift_exp_x76),
            .sum(s2_sum_x76)
            );
    
    normalize a3(   .en(en),
                    .rst(rst),
                    .A(added_sum_x76),
                    .final(sum)
                    );
    
    always @ (posedge clk) begin
        // Align Stage Register Update
        aligned_A_x76 <= s1_C_x76;
        B_exp_x76 <= s1_S_exp_x76;
        shift_exp_x76 <= s1_shift_x76;
        //Add Stage Register Update
        added_sum_x76 <= s2_sum_x76;
    end
    
endmodule


module align( input rst, en,
              input [15:0] A,
              input [4:0] B_exp,
              output reg [25:0] C,
              output reg [4:0] S_exp,
              output reg [5:0] shift
              );
              
    always @(*) begin
        if(rst) begin
            C <= 0;
            shift <= 0;
            S_exp <= 0;
        end
        if(!rst && en) begin
            if(B_exp != 0) begin
                if(A[14:10] - B_exp >= 0) begin
                    shift[5] <= 0;                 // Left shift A mantissa
                    shift[4:0] = A[14:10] - B_exp;
                end else if (A[14:10] - B_exp < 0) begin
                    shift[5] <= 1;                 //Left shift B mantissa
                    shift[4:0] = B_exp - A[14:10];
                end
            end else begin
                shift = 0;
                S_exp = A[14:10];
            end
            C = {A[15], S_exp, 10'b1, A[9:0]};
        end end
endmodule



module add( input en, rst,
            input [25:0] A,
            input [25:0] B,       
            input [5:0] shift_exp,
            output reg [25:0] sum
            );
            
    reg [4:0] A_exp_x76;
    reg [4:0] B_exp_x76; 
    reg [19:0] A_mant_x76;
    reg [19:0] B_mant_x76;
    reg [19:0] S_mant_x76;
    reg S_sign_x76;
    integer i_x76;
    
    reg g_x76, r_x76, s_x76;
    
                
    always @(*) begin
        if(rst) begin
            A_mant_x76 <= 0;
            B_mant_x76 <= 0;
            S_mant_x76 <= 0;
            S_sign_x76 <= 0;
            A_exp_x76 <= 0;
            B_exp_x76 <= 0;
    
            g_x76 <= 0; r_x76 <= 0; s_x76 <= 0;
            sum <= 0;
        end else if(!rst && en) begin
            //Loading and rounding input mantissas
            A_mant_x76 = A[19:0];
            B_mant_x76 = B[19:0];
            A_exp_x76 = A[24:20];
            B_exp_x76 = B[24:20];
            
            // Determine mantissa of the sum, unnormalized.
            case (shift_exp[5])
                0: begin
                    A_mant_x76 = A_mant_x76 << shift_exp[4:0];
                    end
                default: begin
                    A_mant_x76 = A_mant_x76 >> shift_exp[4:0];
                end
            endcase
            
            
            
            if(A[25] != B[25]) begin
                if(A_mant_x76 >= B_mant_x76) begin
                    B_mant_x76 = ~B_mant_x76 + 1;
                    S_sign_x76 = A[25];
                end
                else if(A_mant_x76 < B_mant_x76) begin
                    A_mant_x76 = ~A_mant_x76 + 1;
                    S_sign_x76 = B[25];
                end
            end
            else S_sign_x76 = A[25];
            
            S_mant_x76 = A_mant_x76 + B_mant_x76;
            sum = {S_sign_x76, A_exp_x76, S_mant_x76};
            
        end
    end
endmodule


module normalize (  input en, rst,
                    input [25:0] A,
                    output reg [15:0] final
                    );

reg [4:0] A_exp_x76;
reg [19:0] A_mant_x76;
reg g_x76, r_x76, s_x76;
integer i, j, k;

always @(*) begin
    if(rst) begin
        A_exp_x76 <= 0;
        A_mant_x76 <= 0;
        g_x76 <= 0; r_x76 <= 0; s_x76 <= 0;
        final <= 0;
    end
    else if(!rst && en) begin
        for(j = 19; j >= 0; j = j - 1) begin
            if(A[j] == 1) begin
                if(j >= 10) begin
                    A_exp_x76 = A[24:20] + (j - 10);
                    for(k = j - 1; k >= 0; k = k - 1) begin
                        A_mant_x76[k] = A[k];
                    end
                    if(j > 10) begin
                        g_x76 = A[j - 11];
                        if(j > 11) begin
                            r_x76 = A[j - 12];
                            if(j >= 13) begin
                                for(i = j - 13; i >= 0; i = i - 1) begin
                                    s_x76 = s_x76 | A[i];
                                    if(s_x76 == 1) i = -1;
                                end end end end
                    casex ({g_x76, r_x76, s_x76})
                        3'b0xx: A_mant_x76 = A_mant_x76 >> (j - 10);
                        3'b100: begin
                            if(A_mant_x76[j - 9] == 0) A_mant_x76 = A_mant_x76 >> (j - 10);
                            else if (A_mant_x76[j - 9] == 1) A_mant_x76 = (A_mant_x76 >> (j - 10)) + 1;
                        end
                        default: A_mant_x76 = (A_mant_x76 >> (j - 10 )) + 1;
                    endcase
                    j = -1;
                end 
                
                else if (j < 10) begin
                    A_exp_x76 = A[24:20] - (10 - j);
                        for(k = j - 1; k >= 0; k = k - 1) begin
                            A_mant_x76[k] = A[k];
                        end
                        A_mant_x76 = A_mant_x76 << (10 - j);
                    end
                    j = -1;
                end end 
            end
    final = {A[25], A_exp_x76, A_mant_x76[9:0]};
end
endmodule



module multiplier(  input clk, rst, 
                    input [15:0] A, B,      // 16-bit Input A and B
                    output reg [15:0] P,     // P = product
                    output reg finish
    );
    
reg P_sign, guard, round, sticky;
reg [4:0] P_exp;
reg [2:0] state;
reg [10:0] A_mant, B_mant;
reg [21:0] P_mant, temp;
integer i, j;

always @* begin
    if(rst) state <= 3'b001;
end

always @ (posedge clk) begin
    if(!rst) begin
    case (state)
        1:  begin
            A_mant <= 0;
            B_mant <= 0;
            P_sign <= 0;
            P_exp <= 0;
            P_mant <= 0;
            P <= 0;
            temp <= 0;
            finish <= 0;
            end
        2: begin
            P_exp <= A[14:10] + B[14:10] - 15;
            A_mant <= {1'b1, A[9:0]};   
            B_mant <= {1'b1, B[9:0]};
            P_sign <= (A[15]) ^ (B[15]);         //Sign Bit
            end
        4: begin
            for(i = 0; i < 11; i = i + 1) begin
                if(A_mant[i] == 1) begin
                    temp[10:0] = B_mant;
                    temp = temp << i;
                    P_mant = P_mant + temp;
                    temp = 0;
            end end
            
            for(j = 21; j >= 0; j = j - 1) begin
                if(P_mant[j] == 1) begin
                    if((20 - j) < 0) begin
                       P_mant = P_mant << 1;
                       P_exp = P_exp + 1;
                    end
                    else begin
                        P_mant = P_mant << (20 - j + 2);
                        P_exp = P_exp - (20 - j);
                    end
                    j = -1;
            end end
            
            guard = P_mant[11];
            round = P_mant[10];
            sticky = |P_mant[9:0];
            
            casex ({guard, round, sticky})
                3'b0xx:;
                3'b100: begin
                    P_mant[21:12] = P[12] == 1'b1 ? P_mant[21:12] + 10'b1 : P_mant[21:12];
                    end
                default: P_mant[21:12] = P_mant[21:12] + 10'b1;
            endcase end
            
            default: begin
                P <= {P_sign, P_exp, P_mant[21:12]};
                finish <= 1;
            end
    endcase
    
    state = state << 1;
    end
end
endmodule   
