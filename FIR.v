`timescale 1ns / 1ps

module fir (
    input  wire clk,
    input  wire rst,
    input  wire signed [19:0] data_in,
    output reg  signed [19:0] data_out,
    output reg              valid_out
);

    // 253-stage shift register (Indices 0 to 252)
    reg signed [19:0] delay_line [0:252];
    integer i, j;

    // R=4 Decimation Counter
    reg [1:0] dec_count;

    // Accumulator (48 bits to handle 253 taps without overflow)
    reg signed [47:0] acc; 
    
    // ROM to hold the 253 coefficients (Indices 0 to 252)
    reg signed [15:0] taps [0:252];
    
    initial begin
        taps[0]   = 4;    taps[1]   = 5;    taps[2]   = -2;   taps[3]   = -22;  taps[4]   = -63;  taps[5]   = -118; taps[6]   = -177; taps[7]   = -218; taps[8]   = -220; taps[9]   = -174;
        taps[10]  = -90;  taps[11]  = 6;    taps[12]  = 79;   taps[13]  = 104;  taps[14]  = 74;   taps[15]  = 10;   taps[16]  = -51;  taps[17]  = -78;  taps[18]  = -58;  taps[19]  = -6;
        taps[20]  = 46;   taps[21]  = 67;   taps[22]  = 45;   taps[23]  = -4;   taps[24]  = -49;  taps[25]  = -61;  taps[26]  = -33;  taps[27]  = 17;   taps[28]  = 55;   taps[29]  = 57;
        taps[30]  = 20;   taps[31]  = -30;  taps[32]  = -61;  taps[33]  = -50;  taps[34]  = -5;   taps[35]  = 45;   taps[36]  = 65;   taps[37]  = 41;   taps[38]  = -12;  taps[39]  = -59;
        taps[40]  = -66;  taps[41]  = -28;  taps[42]  = 32;   taps[43]  = 71;   taps[44]  = 63;   taps[45]  = 10;   taps[46]  = -52;  taps[47]  = -80;  taps[48]  = -54;  taps[49]  = 11;
        taps[50]  = 72;   taps[51]  = 85;   taps[52]  = 39;   taps[53]  = -37;  taps[54]  = -90;  taps[55]  = -83;  taps[56]  = -17;  taps[57]  = 64;   taps[58]  = 104;  taps[59]  = 73;
        taps[60]  = -11;  taps[61]  = -92;  taps[62]  = -113; taps[63]  = -55;  taps[64]  = 45;   taps[65]  = 118;  taps[66]  = 112;  taps[67]  = 27;   taps[68]  = -82;  taps[69]  = -139;
        taps[70]  = -101; taps[71]  = 11;   taps[72]  = 121;  taps[73]  = 152;  taps[74]  = 77;   taps[75]  = -56;  taps[76]  = -158; taps[77]  = -154; taps[78]  = -41;  taps[79]  = 108;
        taps[80]  = 189;  taps[81]  = 141;  taps[82]  = -10;  taps[83]  = -163; taps[84]  = -210; taps[85]  = -111; taps[86]  = 73;   taps[87]  = 218;  taps[88]  = 217;  taps[89]  = 62;
        taps[90]  = -148; taps[91]  = -267; taps[92]  = -204; taps[93]  = 9;    taps[94]  = 232;  taps[95]  = 306;  taps[96]  = 167;  taps[97]  = -103; taps[98]  = -321; taps[99]  = -327;
        taps[100] = -98;  taps[101] = 221;  taps[102] = 411;  taps[103] = 322;  taps[104] = -8;   taps[105] = -367; taps[106] = -498; taps[107] = -281; taps[108] = 167;  taps[109] = 548;
        taps[110] = 577;  taps[111] = 184;  taps[112] = -403; taps[113] = -784; taps[114] = -644; taps[115] = 8;    taps[116] = 787;  taps[117] = 1138; taps[118] = 694;  taps[119] = -426;
        taps[120] = -1580;taps[121] = -1890;taps[122] = -726; taps[123] = 1885; taps[124] = 5161; taps[125] = 7877; taps[126] = 8929; taps[127] = 7877; taps[128] = 5161; taps[129] = 1885;
        taps[130] = -726; taps[131] = -1890;taps[132] = -1580;taps[133] = -426;taps[134] = 694;  taps[135] = 1138; taps[136] = 787;  taps[137] = 8;    taps[138] = -644; taps[139] = -784;
        taps[140] = -403; taps[141] = 184;  taps[142] = 577;  taps[143] = 548;  taps[144] = 167;  taps[145] = -281; taps[146] = -498; taps[147] = -367; taps[148] = -8;   taps[149] = 322;
        taps[150] = 411;  taps[151] = 221;  taps[152] = -98;  taps[153] = -327; taps[154] = -321; taps[155] = -103; taps[156] = 167;  taps[157] = 306;  taps[158] = 232;  taps[159] = 9;
        taps[160] = -204; taps[161] = -267; taps[162] = -148; taps[163] = 62;   taps[164] = 217;  taps[165] = 218;  taps[166] = 73;   taps[167] = -111; taps[168] = -210; taps[169] = -163;
        taps[170] = -10;  taps[171] = 141;  taps[172] = 189;  taps[173] = 108;  taps[174] = -41;  taps[175] = -154; taps[176] = -158; taps[177] = -56;  taps[178] = 77;   taps[179] = 152;
        taps[180] = 121;  taps[181] = 11;   taps[182] = -101; taps[183] = -139; taps[184] = -82;  taps[185] = 27;   taps[186] = 112;  taps[187] = 118;  taps[188] = 45;   taps[189] = -55;
        taps[190] = -113; taps[191] = -92;  taps[192] = -11;  taps[193] = 73;   taps[194] = 104;  taps[195] = 64;   taps[196] = -17;  taps[197] = -83;  taps[198] = -90;  taps[199] = -37;
        taps[200] = 39;   taps[201] = 85;   taps[202] = 72;   taps[203] = 11;   taps[204] = -54;  taps[205] = -80;  taps[206] = -52;  taps[207] = 10;   taps[208] = 63;   taps[209] = 71;
        taps[210] = 32;   taps[211] = -28;  taps[212] = -66;  taps[213] = -59;  taps[214] = -12;  taps[215] = 41;   taps[216] = 65;   taps[217] = 45;   taps[218] = -5;   taps[219] = -50;
        taps[220] = -61;  taps[221] = -30;  taps[222] = 20;   taps[223] = 57;   taps[224] = 55;   taps[225] = 17;   taps[226] = -33;  taps[227] = -61;  taps[228] = -49;  taps[229] = -4;
        taps[230] = 45;   taps[231] = 67;   taps[232] = 46;   taps[233] = -6;   taps[234] = -58;  taps[235] = -78;  taps[236] = -51;  taps[237] = 10;   taps[238] = 74;   taps[239] = 104;
        taps[240] = 79;   taps[241] = 6;    taps[242] = -90;  taps[243] = -174; taps[244] = -220; taps[245] = -218; taps[246] = -177; taps[247] = -118; taps[248] = -63;  taps[249] = -22;
        taps[250] = -2;   taps[251] = 5;    taps[252] = 4;
    end

    // Combinational Multiply-Accumulate (MAC)
    always @(*) begin
        acc = 0; 
        for (j = 0; j < 253; j = j + 1) begin
            acc = acc + ($signed(delay_line[j]) * $signed(taps[j]));
        end
    end

    // Sequential Shift Register & Decimation Engine (R=4)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dec_count <= 2'd0;
            data_out  <= 20'sd0;
            valid_out <= 1'b0;
            for (i = 0; i < 253; i = i + 1) begin
                delay_line[i] <= 20'sd0;
            end
        end else begin
            // Shift incoming sample through delay line
            delay_line[0] <= data_in;
            for (i = 1; i < 253; i = i + 1) begin
                delay_line[i] <= delay_line[i-1];
            end
            
            // Decimation Counter
            dec_count <= dec_count + 1'b1;
            
            // Strobe output every 4th clock cycle
            if (dec_count == 2'd3) begin
                data_out  <= acc[34:15]; // Shift right by 15 bits to reverse Q15 scaling
                valid_out <= 1'b1;       // High for 1 clock cycle on valid decimated sample
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule