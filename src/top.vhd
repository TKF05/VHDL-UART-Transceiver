----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/25/2026 06:49:28 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    Port ( 
        clk     : in std_logic;
        rst     : in std_logic;
        led     : out std_logic_vector(7 downto 0);
        RsRx    : in std_logic;
        RsTx    : out std_logic;
        sw      : in std_logic_vector(7 downto 0);
        mode    : in std_logic;
        send    : in std_logic
    );
end top;

architecture Behavioral of top is

    signal Dout : std_logic_vector(7 downto 0);
    signal Dprep : std_logic_vector(7 downto 0);
    signal Dsend : std_logic;
    signal Ack : std_logic;
    signal TAck : std_logic;
    signal receive : std_logic;
    signal transmit : std_logic;
    signal parityErr : std_logic;
    signal send_prev : std_logic := '0';
    signal tx_busy   : std_logic := '0';

    
    type state_type is (RX, TX);
    signal state : state_type := RX;

begin

    rx_inst : entity work.rx
        port map(
            clk => clk, 
            rst => rst,
            Sin => RsRx,
            ReceiveAck => Ack,
            Receive => receive,
            Dout => Dout,
            parityErr => parityErr
        );

    tx_inst : entity work.tx
        port map(
            clk => clk,
            rst => rst,
            Din => Dprep,
            Transmit => transmit,
            Tx => Dsend,
            TransmitAck => TAck
        );
        
    RsTx <= Dsend;
        
    process(clk)
    begin
        if rst = '1' then
            led <= (others => '0');
        elsif rising_edge(clk) then
            transmit <= '0';
            send_prev <= send;
            
            case state is
                when RX => 
                    if mode = '1' then
                        state <= TX;
                    elsif receive = '1' then
                        led <= Dout;
                    end if;

                when TX =>
                    led <= sw;

                    -- TX finished
                    if TAck = '1' then
                        tx_busy <= '0';
                    end if;

                    -- Detect button press
                    if send = '1' and send_prev = '0' then
                        -- Only accept button if TX isn't busy
                        if tx_busy = '0' then
                            Dprep <= sw;
                            transmit <= '1';
                            tx_busy <= '1';
                        end if;
                    end if;

                    if mode = '0' then
                        state <= RX;
                    end if;
            end case;
       end if;
    end process;

end Behavioral;
