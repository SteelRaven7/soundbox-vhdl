
-- decimator_tb.do

restart -f -nowave
view signals wave
add wave clk_tb_signal reset_tb_signal x_tb_signal start_tb_signal
add wave y_tb_signal      
# -radix decimal y_tb_signal
run 550000 ns
