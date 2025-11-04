# Copyright (C) 2018  Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License 
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel FPGA IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Intel and sold by Intel or its authorized distributors.  Please
# refer to the applicable agreement for further details.

# Quartus Prime Version 18.0.0 Build 614 04/24/2018 SJ Standard Edition
# File: E:\ZEYI\FPGA\EP4C\Finalize\2_hdmi_colorbar_top\doc\hdmi_colorbar_top.tcl
# Generated on: Wed Apr 10 17:30:06 2024

package require ::quartus::project

set_location_assignment PIN_M2 -to sys_clk
set_location_assignment PIN_M1 -to sys_rst_n
set_location_assignment PIN_B12 -to tmds_clk_p
set_location_assignment PIN_A12 -to tmds_clk_n
set_location_assignment PIN_B9 -to tmds_data_p[2]
set_location_assignment PIN_A9 -to tmds_data_n[2]
set_location_assignment PIN_B10 -to tmds_data_p[1]
set_location_assignment PIN_A10 -to tmds_data_n[1]
set_location_assignment PIN_B11 -to tmds_data_p[0]
set_location_assignment PIN_A11 -to tmds_data_n[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to sys_clk
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to sys_rst_n
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to tmds_clk_p
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to tmds_clk_n
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to tmds_data_p[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to tmds_data_n[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to tmds_data_p[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to tmds_data_n[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to tmds_data_p[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVCMOS" -to tmds_data_n[0]