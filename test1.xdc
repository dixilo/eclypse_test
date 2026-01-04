# Eclypse
set_property PACKAGE_PIN C17 [get_ports reset_rtl_0]
set_property IOSTANDARD LVCMOS33 [get_ports reset_rtl_0]

set_property PACKAGE_PIN D18 [get_ports clk_in1]
set_property IOSTANDARD LVCMOS33 [get_ports clk_in1]

# Zmod scope definition
## Zmod scope ADC
set_property PACKAGE_PIN T16 [get_ports sZmodCh1CouplingH]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh1CouplingH]

set_property PACKAGE_PIN T17 [get_ports sZmodCh1CouplingL]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh1CouplingL]

set_property PACKAGE_PIN R19 [get_ports sZmodCh2CouplingH]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh2CouplingH]

set_property PACKAGE_PIN T19 [get_ports sZmodCh2CouplingL]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh2CouplingL]

set_property PACKAGE_PIN N15 [get_ports sZmodCh1GainH]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh1GainH]

set_property PACKAGE_PIN P15 [get_ports sZmodCh1GainL]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh1GainL]

set_property PACKAGE_PIN P17 [get_ports sZmodCh2GainH]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh2GainH]

set_property PACKAGE_PIN P18 [get_ports sZmodCh2GainL]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodCh2GainL]

set_property PACKAGE_PIN J20 [get_ports sZmodRelayComH]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodRelayComH]

set_property PACKAGE_PIN K21 [get_ports sZmodRelayComL]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodRelayComL]

## ADC
set_property PACKAGE_PIN R18 [get_ports sZmodADC_SDIO]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodADC_SDIO]
set_property DRIVE 4 [get_ports sZmodADC_SDIO]

set_property PACKAGE_PIN M21 [get_ports sZmodADC_CS]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodADC_CS]
set_property DRIVE 4 [get_ports sZmodADC_CS]

set_property PACKAGE_PIN T18 [get_ports sZmodADC_Sclk]
set_property IOSTANDARD LVCMOS18 [get_ports sZmodADC_Sclk]
set_property DRIVE 4 [get_ports sZmodADC_Sclk]

set_property PACKAGE_PIN M22 [get_ports iZmodSync]
set_property IOSTANDARD LVCMOS18 [get_ports iZmodSync]
set_property DRIVE 4 [get_ports iZmodSync]
set_property SLEW SLOW [get_ports iZmodSync]

set_property PACKAGE_PIN M19 [get_ports ZmodDcoClk]
set_property IOSTANDARD LVCMOS18 [get_ports ZmodDcoClk]

set_property IOSTANDARD DIFF_SSTL18_I [get_ports -filter { name =~ ZmodAdcClkIn* }]
set_property PACKAGE_PIN N19 [get_ports ZmodAdcClkIn_p]
set_property PACKAGE_PIN N20 [get_ports ZmodAdcClkIn_n]
set_property SLEW SLOW [get_ports -filter { name =~ ZmodAdcClkIn* }]

set_property PACKAGE_PIN N22 [get_ports {dZmodADC_Data[0]}]
set_property PACKAGE_PIN L21 [get_ports {dZmodADC_Data[1]}]
set_property PACKAGE_PIN R16 [get_ports {dZmodADC_Data[2]}]
set_property PACKAGE_PIN J18 [get_ports {dZmodADC_Data[3]}]
set_property PACKAGE_PIN K18 [get_ports {dZmodADC_Data[4]}]
set_property PACKAGE_PIN L19 [get_ports {dZmodADC_Data[5]}]
set_property PACKAGE_PIN L18 [get_ports {dZmodADC_Data[6]}]
set_property PACKAGE_PIN L22 [get_ports {dZmodADC_Data[7]}]
set_property PACKAGE_PIN K20 [get_ports {dZmodADC_Data[8]}]
set_property PACKAGE_PIN P16 [get_ports {dZmodADC_Data[9]}]
set_property PACKAGE_PIN K19 [get_ports {dZmodADC_Data[10]}]
set_property PACKAGE_PIN J22 [get_ports {dZmodADC_Data[11]}]
set_property PACKAGE_PIN J21 [get_ports {dZmodADC_Data[12]}]
set_property PACKAGE_PIN P22 [get_ports {dZmodADC_Data[13]}]
set_property IOSTANDARD LVCMOS18 [get_ports -filter { name =~ dZmodADC_Data*}]
