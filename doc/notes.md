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

# 256 8-bit samples of sin
[128, 131, 134, 137, 140, 143, 146, 149, 152, 155, 158, 162, 165, 167, 170, 173, 176, 179, 182, 185, 188, 190, 193, 196, 198, 201, 203, 206, 208, 211, 213, 215, 218, 220, 222, 224, 226, 228, 230, 232, 234, 235, 237, 238, 240, 241, 243, 244, 245, 246, 248, 249, 250, 250, 251, 252, 253, 253, 254, 254, 254, 255, 255, 255, 255, 255, 255, 255, 254, 254, 254, 253, 253, 252, 251, 250, 250, 249, 248, 246, 245, 244, 243, 241, 240, 238, 237, 235, 234, 232, 230, 228, 226, 224, 222, 220, 218, 215, 213, 211, 208, 206, 203, 201, 198, 196, 193, 190, 188, 185, 182, 179, 176, 173, 170, 167, 165, 162, 158, 155, 152, 149, 146, 143, 140, 137, 134, 131, 128, 124, 121, 118, 115, 112, 109, 106, 103, 100, 97, 93, 90, 88, 85, 82, 79, 76, 73, 70, 67, 65, 62, 59, 57, 54, 52, 49, 47, 44, 42, 40, 37, 35, 33, 31, 29, 27, 25, 23, 21, 20, 18, 17, 15, 14, 12, 11, 10, 9, 7, 6, 5, 5, 4, 3, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 3, 4, 5, 5, 6, 7, 9, 10, 11, 12, 14, 15, 17, 18, 20, 21, 23, 25, 27, 29, 31, 33, 35, 37, 40, 42, 44, 47, 49, 52, 54, 57, 59, 62, 65, 67, 70, 73, 76, 79, 82, 85, 88, 90, 93, 97, 100, 103, 106, 109, 112, 115, 118, 121, 124]