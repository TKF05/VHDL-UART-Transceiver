## VHDL UART Transceiver
VHDL implementation of a UART receiver and transmitter.

## Usage 
Switch 8 on the basys3 is the "mode" switch. '0' is Receive mode, '1' is Transmit mode. BTNU is the reset button.
When in receive mode, the basys3 will display the byte received on the LEDs.
When in Transmit mode, the byte to send is configured with switches 0-7 and sent with BTNL. 

## Hardware
  - Digilent Basys-3 FPGA 

## Tools
  - AMD/Xilinx Vivado
  - VHDL
