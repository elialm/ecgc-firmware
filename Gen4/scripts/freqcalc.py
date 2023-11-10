#!/usr/bin/python3

CLKI = 33333333
CLKI_DIV = 1
CLKFB_DIV = 3
CLKOK_DIV = 100

clk_op = (CLKI / CLKI_DIV) * CLKFB_DIV
clk_ok = clk_op / CLKOK_DIV
clk_ok_t = 1 / clk_ok
ms_counter = clk_ok / 1000
ms_diff = ms_counter - round(ms_counter)
clk_drift = ms_diff * clk_ok_t  # drift per ms

print('CLKI = {} MHz ({} Hz)'.format(CLKI / 1000000, CLKI))
print('CLKOP = {} MHz ({} Hz)'.format(clk_op / 1000000, clk_op))
print('CLKOK = {} kHz ({} Hz)'.format(clk_ok / 1000, clk_ok))
print('Ms counter = {} (actual = {})'.format(round(ms_counter), ms_counter))
print('Ms diff = {} cycles'.format(ms_diff))
print('Ns drift per ms = {} ns'.format(clk_drift * 1000000000))
print('Clock drifts by 1 ms {} after {} s'.format('behind' if ms_diff > 0 else 'forward', abs((1 / clk_drift) / 1000000)))