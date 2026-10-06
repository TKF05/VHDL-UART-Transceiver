library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rx is
    Port ( 
        clk         : in std_logic;
        rst         : in std_logic;
        Sin         : in std_logic;
        Receive     : out std_logic;
        ReceiveAck  : in std_logic;
        Dout        : out std_logic_vector(7 downto 0);
        parityErr   : out std_logic
    );
end rx;

architecture rtl of rx is

    constant CLK_FREQ : integer := 100000000;
    constant BAUD_RATE : integer := 19200;
    constant CLK_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    constant CLK_PER_HALF : integer := CLK_PER_BIT / 2;
    
    type state_type is (IDLE, START_BIT, STOP_BIT, REC_BITS, WAITACK, PARITY_BIT);
    signal state    : state_type := IDLE;
    signal count : integer range 0 to CLK_PER_BIT - 1;
    signal bit_index : integer range 0 to 7 := 0;
    signal input_register : std_logic_vector(7 downto 0);
    signal p_bit   : std_logic := '0';

begin

process(clk)
begin 
        
    if rising_edge(clk) then
        if rst = '1' then
            state <= IDLE;
            count <= 0;
            bit_index <= 0;
            Dout <= (others => '0');
            Receive   <= '0';
            parityErr <= '0';
        else 
        
        Receive <= '0';
        
        case state is 
            when IDLE => 
                count <= 0;
                Receive <= '0';
                if Sin = '0' then
                    parityErr <= '0';
                    state <= START_BIT;
                    count <= 0;
                end if;
                
             when START_BIT =>
             -- make sure that it is the start bit
                if count = CLK_PER_HALF - 1 then
                    if Sin = '0' then
                        state <= REC_BITS;
                        count <= 0;
                        bit_index <= 0;
                    else 
                        state <= IDLE;
                    end if;
                else    
                    count <= count + 1;
                end if;
                
            when REC_BITS =>
                if count = CLK_PER_BIT - 1 then
                    count <= 0;
                    input_register(bit_index) <= Sin; 
                    
                    if bit_index = 7 then
                        state <= PARITY_BIT;
                    else 
                        bit_index <= bit_index + 1;
                    end if;
                else 
                    count <= count + 1;
                end if;
           
            when STOP_BIT =>
                if count = CLK_PER_BIT -1 then
                    count <= 0; 
                         
                    if Sin = '1' then
                        Dout <= input_register;
                        state <= IDLE;
                        Receive <= '1';
                    else 
                        state <= IDLE;
                    end if;
                else
                    count <= count + 1;
                end if;
                
            when PARITY_BIT =>    
                if count = CLK_PER_BIT - 1 then
                    count <= 0;
                    
                    if Sin = (input_register(0) xor
                                input_register(1) xor
                                input_register(2) xor
                                input_register(3) xor
                                input_register(4) xor
                                input_register(5) xor
                                input_register(6) xor
                                input_register(7) )then 
                                
                        parityErr <= '0';
                        state <= STOP_BIT;
                    else
                        parityErr <= '1';
                        state <= IDLE;
                    end if;    
                   
                else
                    count <= count + 1;
                
                end if; 
                
            when WAITACK => 
                count <= 0;
                Receive <= '1';
                
                if ReceiveAck = '1' then
                    state <= IDLE;
                end if;
        end case;
        end if;
    end if;
end process;

end rtl;