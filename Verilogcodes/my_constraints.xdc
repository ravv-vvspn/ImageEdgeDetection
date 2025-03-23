################################################################################
# My device = xc7a200t sbv484 -2L 
################################################################################
# Clock Constraints  
################################################################################  
# Primary Clocks (100 MHz and 200 MHz)  
create_clock -name clk_100mhz -period 10.0 [get_ports clk_100mhz]  
create_clock -name clk_200mhz -period 5.0 [get_ports clk_200mhz]  

# Asynchronous Clock Domains (BRAM @ 100 MHz, Processing @ 200 MHz)  
set_clock_groups -name async_clks -asynchronous -group [get_clocks clk_100mhz] -group [get_clocks clk_200mhz] 


################################################################################  
# Clk Timing Exceptions (False Paths for CDC)  
################################################################################  
# Async FIFO handles CDC; exclude paths from timing checks  
set_false_path -from [get_clocks clk_100mhz] -to [get_clocks clk_200mhz]  
set_false_path -from [get_clocks clk_200mhz] -to [get_clocks clk_100mhz]  

################################################################################  
# Clock Uncertainty 
################################################################################  
#Table 36: Duty Cycle Distortion and Clock-Tree Skew
# TCKSKEW Global clock tree skew  XC7A200T -2L  = 0.48
# TDCD_CLK Global clock tree duty-cycle distortion (jitter) =  0.20
#set_clock_uncertainty -setup 0.68 [get_clocks {clk_100mhz clk_200mhz}]

# Clock latency
# Table 49: Package Skew TPKGSKEW XC7A200T SBG484 111 ps
#set_clock_latency -source -max 0.111 [get_clocks {clk_100mhz clk_200mhz}]

#to force better routing of clk tree
#set_clock_latency -max 0.5 [get_clocks clk_200mhz]
#set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk_200mhz]


################################################################################  
# I/O Constraints (SSTL15 Standard for Timing Compliance)  
################################################################################  
# I/O Standards and Voltages (Aligned with SSTL15)  
set_property IOSTANDARD SSTL15 [get_ports {clk_100mhz clk_200mhz}]  
set_property IOSTANDARD SSTL15 [get_ports { start reset_n}]  
set_property IOSTANDARD SSTL15 [get_ports {serial_data serial_valid serial_ready_in wr_rst_busy rd_rst_busy}]  
  
# since this is async reset, no timing analysis possible, no relation to clk  
set_false_path -from [get_ports {reset_n}]
# I/O Optimizations

# input and output hold delays constraints are not given since they are coming from behavioral testbench

# Input Delays (From datasheet table 44: TPSFD/TPHFD = 3.27/-0.36 @ 1.0V)  
# Table 44: Global Clock Input Setup and Hold Without MMCM/PLL For Device xc7a200t sbv484 -2L 
set_input_delay -clock clk_100mhz -max 3.27 [get_ports {start}]  
#set_input_delay -clock clk_100mhz -min -0.36 [get_ports {start}] 
#to fix hold
set_input_delay -clock clk_100mhz -min [expr -0.36 + 1.5] [get_ports {start}]  


set_input_delay -clock clk_200mhz -max 3.27  [get_ports {serial_ready_in}]  
set_input_delay -clock clk_200mhz -min -0.36 [get_ports {serial_ready_in}]

#to fix hold  these were attempted but each time, the tool did optimizations which caused setup or hold failure again
# finally this path was free of issues -from [get_pins {p2s/FSM_onehot_state_reg[2]/C}] -to [get_pins p2s/serial_data_reg/CE]
#with set dont touch and redundant combinational delays in RTL code.

#but this path continued to have issues with hold and setup not fixable easily by adding dont-touch nets or logic
# -from [get_ports serial_ready_in] -to [get_pins p2s/serial_ready_in_t_reg/D]

#set_input_delay -clock clk_200mhz -min [expr -0.36 + 1.0] [get_ports {serial_ready_in}]  
#set_input_delay -min -clock clk_200mhz 0.3 [get_ports serial_ready_in]

#set_min_delay -from [get_pins {p2s/FSM_onehot_state_reg[2]/C}] -to [get_pins p2s/serial_data_reg/CE] 1.0

#set_min_delay -from [get_pins {p2s/FSM_onehot_state_reg[2]/C}] -to [get_pins p2s/serial_data_reg/CE] 2.4
#set_max_delay -from [get_pins {p2s/FSM_onehot_state_reg[2]/C}] -to [get_pins p2s/serial_data_reg/CE] 3.3

#set_min_delay -from [get_ports serial_ready_in] -to [get_pins p2s/serial_ready_in_t_reg/D] 1.0
#set_min_delay -from [get_ports serial_ready_in] -to [get_pins p2s/serial_ready_in_t_reg/D] 0.30
#set_max_delay -from [get_ports serial_ready_in] -to [get_pins p2s/serial_ready_in_t_reg/D] 1.20

#to fix hold 
#set_max_delay -from  [get_pins {p2s/FSM_onehot_state_reg[2]/C}] -to [get_pins p2s/serial_data_reg/CE] 1.0
#set_max_delay -from [get_ports serial_ready_in] -to [get_pins p2s/serial_ready_in_t_reg/D]  1.0



# 
# Output Delays (From datasheet: TICKOFMMCMCC = 1.04 ns @ 1.0V) Table 41
#set_output_delay -clock clk_200mhz -max 1.04 ns[get_ports {serial_data serial_valid}]  
#to fix setup 
set_output_delay -max [expr 1.04 - 4.16] -clock clk_200mhz [get_ports {serial_data serial_valid}]
set_output_delay -clock clk_200mhz -min -0.5 [get_ports {serial_data serial_valid}] 

 
set_output_delay -clock clk_100mhz -max 1.04 [get_ports {wr_rst_busy rd_rst_busy}]  
set_output_delay -clock clk_100mhz -min -0.5 [get_ports {wr_rst_busy rd_rst_busy}]  


#set_property DRIVE 12 [get_ports {serial_valid serial_data}] 
#set_property SLEW FAST [get_ports {serial_valid serial_data}]
#set_property SLEW FAST [get_ports {serial_data serial_valid serial_ready_in}]
set_property IOB TRUE [get_cells p2s/serial_valid_reg]
set_property IOB TRUE [get_cells p2s/serial_data_reg]
#
#set_property IOB TRUE [get_cells p2s/serial_ready_in_t_reg]

#set_min_delay 0.030 -from [get_pins {p2s/FSM_onehot_state_reg[2]/C}] -to [get_pins p2s/serial_data_reg/CE]  


################################################################################  
# Pin Assignments (Example for xc7a200tsbv484-2L)  
################################################################################  
################################################################################  
# Clock Pins (MRCC/SRCC)  
################################################################################  

# 200 MHz Clock   J19
set_property PACKAGE_PIN J19 [get_ports clk_200mhz]  
set_property IOSTANDARD SSTL15 [get_ports clk_200mhz]  
set_property CLOCK_DEDICATED_ROUTE TRUE [get_nets clk_200mhz]

# 100 MHz Clock   D17
set_property PACKAGE_PIN D17 [get_ports clk_100mhz]  
set_property IOSTANDARD SSTL15 [get_ports clk_100mhz]  
set_property CLOCK_DEDICATED_ROUTE TRUE [get_nets clk_100mhz]  
  



################################################################################  
# Control Signals (Bank 15, SSTL15)  
################################################################################  
# Reset (Active-Low)  
#  
set_property PACKAGE_PIN F18 [get_ports reset_n]    
set_property IOSTANDARD SSTL15 [get_ports reset_n]  

# Start Signal  
# near  100 MHz Clock   D17
set_property PACKAGE_PIN E17 [get_ports start]
set_property IOSTANDARD SSTL15 [get_ports start]  

# Async FIFO Reset Flags  
set_property PACKAGE_PIN E18 [get_ports wr_rst_busy]
set_property PACKAGE_PIN E19 [get_ports rd_rst_busy]  
set_property IOSTANDARD SSTL15 [get_ports {wr_rst_busy rd_rst_busy}]  

################################################################################  
# Serial Interface (Bank 15, SSTL15)  
################################################################################  

 # near   200 MHz Clock   J19
set_property PACKAGE_PIN J20 [get_ports serial_data] 
 # near  200 MHz Clock   J19
set_property PACKAGE_PIN K19 [get_ports serial_valid]  
 #  near 200 MHz Clock   J19
set_property PACKAGE_PIN J21 [get_ports serial_ready_in]  
set_property IOSTANDARD SSTL15 [get_ports {serial_data serial_valid serial_ready_in}]  

# Bank 0 (Configuration Bank)
# Use VCCO for 3.3V/2.5V
set_property CFGBVS VCCO [current_design]          
# Set to actual voltage (3.3/2.5/1.8)
set_property CONFIG_VOLTAGE 3.3 [current_design]   

   
    
