-- VHDL module instantiation generated by SCUBA Diamond (64-bit) 3.12.1.454
-- Module  Version: 5.7
-- Fri Nov 10 10:55:38 2023

-- parameterized module component declaration
component pll
    port (CLK: in std_logic; CLKOP: out std_logic; CLKOK: out std_logic; 
        LOCK: out std_logic);
end component;

-- parameterized module component instance
__ : pll
    port map (CLK=>__, CLKOP=>__, CLKOK=>__, LOCK=>__);
