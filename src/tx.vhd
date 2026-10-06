library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tx is
    Port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        Din         : in  std_logic_vector(7 downto 0);
        Transmit    : in  std_logic;
        Tx          : out std_logic;
        TransmitAck : out std_logic
    );
end tx;

architecture rtl of tx is

    constant CLK_FREQ    : integer := 100000000;
    constant BAUD_RATE   : integer := 19200;
    constant CLK_PER_BIT : integer := CLK_FREQ / BAUD_RATE;

    type state_type is (IDLE, START_BIT, SEND_BITS, P_BIT, STOP_BIT);
    signal state : state_type := IDLE;

    signal count     : integer range 0 to CLK_PER_BIT - 1 := 0;
    signal bit_index : integer range 0 to 7 := 0;

    signal output_register : std_logic_vector(7 downto 0) := (others => '0');

    signal parity_bit : std_logic := '0';

begin

    process(clk)
    begin

        if rising_edge(clk) then
            if rst = '1' then

                state          <= IDLE;
                count          <= 0;
                bit_index      <= 0;
                output_register <= (others => '0');
                parity_bit     <= '0';

                Tx             <= '1';
                TransmitAck    <= '0';
            else
                TransmitAck <= '0';

                case state is
                    when IDLE =>
                        Tx    <= '1';
                        count <= 0;
                        if Transmit = '1' then
                            output_register <= Din;
                            -- define the parity bit 
                            parity_bit <= Din(0) xor
                                          Din(1) xor
                                          Din(2) xor
                                          Din(3) xor
                                          Din(4) xor
                                          Din(5) xor
                                          Din(6) xor
                                          Din(7);
                            bit_index <= 0;
                            count     <= 0;
                            state <= START_BIT;
                        end if;

                    when START_BIT =>
                        -- transmit start bit for one symbol length
                        Tx <= '0';
                        if count = CLK_PER_BIT - 1 then
                            count <= 0;
                            bit_index <= 0;
                            state <= SEND_BITS;
                        else
                            count <= count + 1;
                        end if;


                    when SEND_BITS =>
                        Tx <= output_register(bit_index);
                        if count = CLK_PER_BIT - 1 then
                            count <= 0;
                            if bit_index = 7 then
                                state <= P_BIT;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            count <= count + 1;
                        end if;


                    when P_BIT =>
                        Tx <= parity_bit;
                        if count = CLK_PER_BIT - 1 then
                            count <= 0;
                            state <= STOP_BIT;
                        else
                            count <= count + 1;
                        end if;


                    when STOP_BIT =>
                        -- back to 1 after sending byte
                        Tx <= '1';
                        if count = CLK_PER_BIT - 1 then
                            count <= 0;
                            --optional acknowledge (not using)
                            TransmitAck <= '1';
                            state <= IDLE;
                        else
                            count <= count + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
end rtl;
