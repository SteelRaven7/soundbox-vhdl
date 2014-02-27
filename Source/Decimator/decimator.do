--decimator.do
restart -f -nowave
view signals wave
add wave clk sample_clk1_temp sample_clk2_temp sample_clk3_temp sample_clk4_temp reset start start2 input_signal output1 output2 output3 output4 output_signal start2 start3 start4 start5
force clk 0 0, 1 20 -repeat 40
force reset 0 0, 1 15, 0 25
force start 0 0, 1 25
force input_signal 12'b000000000000  0, 12'b000100010001 20, 12'b001000100010 40, 12'b001100110011 60, 12'b010001000100 80, 12'b010101010101 100, 12'b011001100110 120, 12'b011101110111 140, 12'b100010001000 160, 12'b100110011001 180, 12'b101010101010 220, 12'b101110111011 240, 12'b110011001100 260,12'b110111011101 280, 12'b111011101110 300, 12'b111111111111 320
run 320000

