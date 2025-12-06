import cocotb
import logging


@cocotb.test()
async def test_sending_byte(dut):
    cocotb.log.info('hello from spi_core tests')
