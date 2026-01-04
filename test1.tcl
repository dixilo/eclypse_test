# Test firmware for Eclypse Z7

source ./util.tcl
set home_dir $::env(HOME)
set_param board.repoPaths $home_dir/.Xilinx/Vivado/2023.2/xhub/board_store/xilinx_board_store

## Device setting
set p_device "xc7z020clg484-1"
set p_board "digilentinc.com:eclypse-z7:part0:1.1"
set project_name "eclypse_test"

create_project -force $project_name ./${project_name} -part $p_device
set_property board_part $p_board [current_project]

# IP repository
set_property  ip_repo_paths  {\
    ../digilent-library \
} [current_project]

add_files -fileset constrs_1 -norecurse {\
    "./test1.xdc" \
}

add_files -norecurse -fileset sources_1 {\
    "./hdl/packet_axi.v" \
}

# create board design
create_bd_design "system"

# Port definition
create_bd_port -dir I reset_rtl_0
create_bd_port -dir I -type clk clk_in1

## For Zmod scope
create_bd_port -dir O sZmodCh1CouplingH
create_bd_port -dir O sZmodCh1CouplingL
create_bd_port -dir O sZmodCh2CouplingH
create_bd_port -dir O sZmodCh2CouplingL
create_bd_port -dir O sZmodCh1GainH
create_bd_port -dir O sZmodCh1GainL
create_bd_port -dir O sZmodCh2GainH
create_bd_port -dir O sZmodCh2GainL
create_bd_port -dir O sZmodRelayComH
create_bd_port -dir O sZmodRelayComL

## For Zmod scope SPI/Control (FPGA -> ADC)
create_bd_port -dir IO sZmodADC_SDIO
create_bd_port -dir O  sZmodADC_CS
create_bd_port -dir O  sZmodADC_Sclk

## For Zmod scope Sync（FPGA -> Zmod）
create_bd_port -dir O iZmodSync

## DCO clock from AD
create_bd_port -dir I ZmodDcoClk

## Differential clock input to ADC
create_bd_port -dir O ZmodAdcClkIn_p
create_bd_port -dir O ZmodAdcClkIn_n

## ADC Data
create_bd_port -dir I -from 13 -to 0 dZmodADC_Data


# IP
## Zmod Scope
set scope [ create_bd_cell -type ip -vlnv [latest_ip ZmodScopeController] ZmodScopeController ]
set_property -dict [list \
  CONFIG.kCh1CouplingStatic {"1"} \
  CONFIG.kCh2CouplingStatic {"1"} \
  CONFIG.kExtCalibEn {false} \
  CONFIG.kExtRelayConfigEn {false} \
] $scope

## Processing system
set processing_system7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7 ]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  $processing_system7
set_property -dict [list \
  CONFIG.PCW_EN_CLK1_PORT {1} \
  CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {150} \
] $processing_system7
set_property CONFIG.PCW_USE_S_AXI_HP0 {1} $processing_system7

## AXIS data FIFO
set axis_data_fifo [ create_bd_cell -type ip -vlnv [latest_ip axis_data_fifo] axis_data_fifo ]
set_property CONFIG.IS_ACLK_ASYNC {1} $axis_data_fifo

## Reset for 100 MHz clock
set proc_sys_reset_sys [ create_bd_cell -type ip -vlnv [latest_ip proc_sys_reset] proc_sys_reset_sys ]

## Reset for 200 MHz clock
set proc_sys_reset_mem [ create_bd_cell -type ip -vlnv [latest_ip proc_sys_reset] proc_sys_reset_mem ]

## DMA
set axi_dma [ create_bd_cell -type ip -vlnv [latest_ip axi_dma] axi_dma ]
set_property -dict [list \
  CONFIG.c_include_mm2s {0} \
  CONFIG.c_include_sg {0} \
] $axi_dma

## Mem interconnect
set axi_interconnect_mem [ create_bd_cell -type ip -vlnv [latest_ip axi_interconnect] axi_interconnect_mem ]
set_property CONFIG.NUM_MI {1} [get_bd_cells axi_interconnect_mem]

## Sys & ADC interconnect
create_bd_cell -type ip -vlnv [latest_ip axi_interconnect] axi_interconnect_sys
set_property CONFIG.NUM_MI {2} [get_bd_cells axi_interconnect_sys]

## Packet
set packet [ create_bd_cell -type module -reference packet_axi_32 packet_axi_32 ]
#set_property CONFIG.FREQ_HZ 100000000 [get_bd_intf_pins /packet_axi_32/s_axis]
#set_property CONFIG.FREQ_HZ 100000000 [get_bd_intf_pins /packet_axi_32/m_axis]

## Constant
create_bd_cell -type ip -vlnv [latest_ip xlconstant] xlconstant_0

create_bd_cell -type ip -vlnv [latest_ip xlconstant] xlconstant_1
set_property CONFIG.CONST_VAL {0} [get_bd_cells xlconstant_1]

# Connection
## 100 MHz clock from PS
create_bd_net sys_clk
## resetn associated with 100 MHz PS clock
create_bd_net sys_resetn

## 200 MHz clock from PS
create_bd_net mem_clk
## resetn associated with 200 MHz memory clock
create_bd_net mem_resetn

## Processing system
connect_bd_net -net sys_clk [get_bd_pins processing_system7/FCLK_CLK0] 
connect_bd_net -net sys_clk [get_bd_pins processing_system7/M_AXI_GP0_ACLK]

connect_bd_net -net mem_clk [get_bd_pins processing_system7/FCLK_CLK1]
connect_bd_net -net mem_clk [get_bd_pins processing_system7/S_AXI_HP0_ACLK]

## sys reset
connect_bd_net -net sys_clk [get_bd_pins proc_sys_reset_sys/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_sys/ext_reset_in]
connect_bd_net -net sys_resetn [get_bd_pins proc_sys_reset_sys/peripheral_aresetn]

## 200 MHz reset
connect_bd_net -net mem_clk [get_bd_pins proc_sys_reset_mem/slowest_sync_clk]
connect_bd_net [get_bd_pins proc_sys_reset_mem/ext_reset_in] [get_bd_pins processing_system7/FCLK_RESET0_N]
connect_bd_net -net mem_resetn [get_bd_pins proc_sys_reset_mem/peripheral_aresetn]

## Zmod scope
connect_bd_net -net sys_clk [get_bd_pins ZmodScopeController/SysClk100]
connect_bd_net -net sys_clk [get_bd_pins ZmodScopeController/ADC_SamplingClk]
connect_bd_net -net sys_clk [get_bd_pins ZmodScopeController/ADC_InClk]
connect_bd_net -net sys_resetn [get_bd_pins ZmodScopeController/aRst_n]
connect_bd_intf_net [get_bd_intf_pins ZmodScopeController/DataStream] [get_bd_intf_pins packet_axi_32/s_axis]


## AXIS Data FIFO
connect_bd_net -net sys_clk [get_bd_pins axis_data_fifo/s_axis_aclk]
connect_bd_net -net sys_resetn [get_bd_pins axis_data_fifo/s_axis_aresetn]
connect_bd_net -net mem_clk [get_bd_pins axis_data_fifo/m_axis_aclk]
connect_bd_intf_net [get_bd_intf_pins axis_data_fifo/M_AXIS] [get_bd_intf_pins axi_dma/S_AXIS_S2MM]

## AXI DMA
connect_bd_net -net mem_clk [get_bd_pins axi_dma/m_axi_s2mm_aclk]
connect_bd_net -net sys_clk [get_bd_pins axi_dma/s_axi_lite_aclk]
connect_bd_net -net sys_resetn [get_bd_pins axi_dma/axi_resetn]

## AXI interconnect for memory
connect_bd_net -net mem_clk [get_bd_pins axi_interconnect_mem/ACLK]
connect_bd_net -net mem_clk [get_bd_pins axi_interconnect_mem/S00_ACLK]
connect_bd_net -net mem_clk [get_bd_pins axi_interconnect_mem/M00_ACLK]
connect_bd_net -net mem_resetn [get_bd_pins axi_interconnect_mem/ARESETN]
connect_bd_net -net mem_resetn [get_bd_pins axi_interconnect_mem/S00_ARESETN]
connect_bd_net -net mem_resetn [get_bd_pins axi_interconnect_mem/M00_ARESETN]

connect_bd_intf_net [get_bd_intf_pins axi_dma/M_AXI_S2MM] [get_bd_intf_pins axi_interconnect_mem/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins processing_system7/S_AXI_HP0] [get_bd_intf_pins axi_interconnect_mem/M00_AXI]


## AXI interconnect for system and ADC
connect_bd_intf_net [get_bd_intf_pins processing_system7/M_AXI_GP0] [get_bd_intf_pins axi_interconnect_sys/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_sys/M00_AXI] [get_bd_intf_pins axi_dma/S_AXI_LITE]
connect_bd_net -net sys_clk [get_bd_pins axi_interconnect_sys/ACLK]
connect_bd_net -net sys_clk [get_bd_pins axi_interconnect_sys/S00_ACLK]
connect_bd_net -net sys_clk [get_bd_pins axi_interconnect_sys/M00_ACLK]
connect_bd_net -net sys_clk [get_bd_pins axi_interconnect_sys/M01_ACLK]
connect_bd_net -net sys_resetn [get_bd_pins axi_interconnect_sys/ARESETN]
connect_bd_net -net sys_resetn [get_bd_pins axi_interconnect_sys/S00_ARESETN]
connect_bd_net -net sys_resetn [get_bd_pins axi_interconnect_sys/M00_ARESETN]
connect_bd_net -net sys_resetn [get_bd_pins axi_interconnect_sys/M01_ARESETN]

## Packet
connect_bd_intf_net [get_bd_intf_pins packet_axi_32/m_axis] [get_bd_intf_pins axis_data_fifo/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_sys/M01_AXI] [get_bd_intf_pins packet_axi_32/s_axi]
connect_bd_net -net sys_clk [get_bd_pins packet_axi_32/s_axi_aclk]
connect_bd_net -net sys_clk [get_bd_pins packet_axi_32/axis_aclk]
connect_bd_net -net sys_resetn [get_bd_pins packet_axi_32/s_axi_aresetn]
connect_bd_net -net sys_resetn [get_bd_pins packet_axi_32/axis_aresetn]

## Constant
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins ZmodScopeController/sEnableAcquisition]
connect_bd_net [get_bd_pins xlconstant_1/dout] [get_bd_pins ZmodScopeController/sTestMode]

## ADC Relays
# Channel 1 Coupling
connect_bd_net \
  [get_bd_ports sZmodCh1CouplingH] \
  [get_bd_pins  ZmodScopeController/sZmodCh1CouplingH]

connect_bd_net \
  [get_bd_ports sZmodCh1CouplingL] \
  [get_bd_pins  ZmodScopeController/sZmodCh1CouplingL]

# Channel 2 Coupling
connect_bd_net \
  [get_bd_ports sZmodCh2CouplingH] \
  [get_bd_pins  ZmodScopeController/sZmodCh2CouplingH]

connect_bd_net \
  [get_bd_ports sZmodCh2CouplingL] \
  [get_bd_pins  ZmodScopeController/sZmodCh2CouplingL]

# Channel 1 Gain
connect_bd_net \
  [get_bd_ports sZmodCh1GainH] \
  [get_bd_pins  ZmodScopeController/sZmodCh1GainH]

connect_bd_net \
  [get_bd_ports sZmodCh1GainL] \
  [get_bd_pins  ZmodScopeController/sZmodCh1GainL]

# Channel 2 Gain
connect_bd_net \
  [get_bd_ports sZmodCh2GainH] \
  [get_bd_pins  ZmodScopeController/sZmodCh2GainH]

connect_bd_net \
  [get_bd_ports sZmodCh2GainL] \
  [get_bd_pins  ZmodScopeController/sZmodCh2GainL]

# Relay Common
connect_bd_net \
  [get_bd_ports sZmodRelayComH] \
  [get_bd_pins  ZmodScopeController/sZmodRelayComH]

connect_bd_net \
  [get_bd_ports sZmodRelayComL] \
  [get_bd_pins  ZmodScopeController/sZmodRelayComL]

## ADC
# ADC SPI/Control
connect_bd_net \
  [get_bd_ports sZmodADC_SDIO] \
  [get_bd_pins  ZmodScopeController/sZmodADC_SDIO]

connect_bd_net \
  [get_bd_ports sZmodADC_CS] \
  [get_bd_pins  ZmodScopeController/sZmodADC_CS]

connect_bd_net \
  [get_bd_ports sZmodADC_Sclk] \
  [get_bd_pins  ZmodScopeController/sZmodADC_Sclk]

# Sync
connect_bd_net \
  [get_bd_ports iZmodSync] \
  [get_bd_pins  ZmodScopeController/iZmodSync]

# ADC DCO clock
connect_bd_net \
  [get_bd_ports ZmodDcoClk] \
  [get_bd_pins  ZmodScopeController/ZmodDcoClk]

# Differential clock input
connect_bd_net \
  [get_bd_ports ZmodAdcClkIn_p] \
  [get_bd_pins  ZmodScopeController/ZmodAdcClkIn_p]

connect_bd_net \
  [get_bd_ports ZmodAdcClkIn_n] \
  [get_bd_pins  ZmodScopeController/ZmodAdcClkIn_n]

# ADC Data
connect_bd_net \
  [get_bd_ports dZmodADC_Data] \
  [get_bd_pins  ZmodScopeController/dZmodADC_Data]

assign_bd_address

### Project
save_bd_design
validate_bd_design

set project_system_dir "./${project_name}/${project_name}.srcs/sources_1/bd/system"

set_property synth_checkpoint_mode None [get_files  $project_system_dir/system.bd]
generate_target {synthesis implementation} [get_files  $project_system_dir/system.bd]
make_wrapper -files [get_files $project_system_dir/system.bd] -top

import_files -force -norecurse -fileset sources_1 $project_system_dir/hdl/system_wrapper.v
set_property top system_wrapper [current_fileset]
