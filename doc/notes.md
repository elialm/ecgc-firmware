# DRAM actions

## To read
1. Send Activate Bank
2. Wait for Trcd (21 ns = 2 clocks)
3. Send Read with Auto Precharge
4. Wait for CAS delay (2 clocks)
5. Read data from DQ lines

## To read (133MHz, Tclk ~= 15.0376 ns)
1. Send Activate Bank
2. Wait for Trcd (21 ns = 2 clocks)
3. Send Read with Auto Precharge
4. Wait for CAS delay (2 clocks)
5. Read data from DQ lines

## To write
1. Send Activate Bank
2. Wait for Trcd (21 ns = 2 clocks)
3. Send Write with Auto Precharge (including data on DQ lines)

## To auto charge (must be done once every ~7.8 ms)
1. Send Auto Refresh command
2. Send NOP till finished (min. Trc = 4 clocks)
3. Send NOP till finished (min. Trc = 4 clocks)
4. Send NOP till finished (min. Trc = 4 clocks)
5. (Free for something else)

# Possible timing issues:
- Having to do a refresh while a cart access is being made can royally fuck us over.
- Bank activate could take some time

# Possible replacement
https://nl.mouser.com/ProductDetail/Alliance-Memory/AS1C8M16PL-70BIN?qs=byeeYqUIh0NST7XYuCr8lQ%3D%3D
