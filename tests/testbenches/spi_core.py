import logging

import cocotb
from cocotbext.spi import SpiBus, SpiConfig, SpiSlaveBase
from cocotbext.wishbone.driver import WishboneMaster, WBOp
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock

__WB_SIGNALS_DICT = {
    "cyc":  "cyc",
    "stb":  "stb",
    "we":   "we",
    "adr":  "adr",
    "datwr": "di",
    "datrd": "do",
    "ack":  "ack"
}

__CART_REG_SPI_BASE = 0xA600
__CART_REG_SPI_CTRL = __CART_REG_SPI_BASE + 0
__CART_REG_SPI_FDIV = __CART_REG_SPI_BASE + 1
__CART_REG_SPI_CS = __CART_REG_SPI_BASE + 2
__CART_REG_SPI_DATA = __CART_REG_SPI_BASE + 3


class SimpleSpiSlave(SpiSlaveBase):
    def __init__(self, bus):
        self._config = SpiConfig(
            word_width=8,
            cpha=False,
            cpol=False,
            msb_first=True
        )
        self.content = 0
        super().__init__(bus)

    async def get_content(self):
        await self.idle.wait()
        return self.content

    async def _transaction(self, frame_start, frame_end):
        await frame_start
        self.idle.clear()

        self.content = int(await self._shift(8, tx_word=(0xAA)))

        await frame_end


async def spi_core_enable(wbm_bus: WishboneMaster):
    await wbm_bus.send(WBOp(__CART_REG_SPI_CTRL, 1))


@cocotb.test()
async def test_sending_byte(dut):
    # Instantiate slave for mocking SPI device
    spi_bus = SpiBus.from_prefix(
        dut, prefix='io_spi', bus_separator="_", sclk_name='clk', cs_name='csn')
    spi_slave = SimpleSpiSlave(spi_bus)

    # Instantiate WishBone master driver
    wbm_bus = WishboneMaster(
        dut, 'm_config', clock=dut.i_clk, timeout=16, width=8, signals_dict=__WB_SIGNALS_DICT)

    # Attach and start clock
    cocotb.start_soon(Clock(dut.i_clk, 10, 'ns').start())

    # Reset design
    dut.i_rst.value = 1
    await ClockCycles(dut.i_clk, 16)
    dut.i_rst.value = 0
    await ClockCycles(dut.i_clk, 16)

    await wbm_bus.send(WBOp(__CART_REG_SPI_CTRL, 0b00000001))
    await wbm_bus.send(WBOp(__CART_REG_SPI_CS, 0b11111110))
    await wbm_bus.send(WBOp(__CART_REG_SPI_DATA, 0x55))

    content = await spi_slave.get_content()

    logging.info(f'Read from SPI slave: 0x{content:02X}')

    assert content == 0xAA, 'Expected to read 0xAA, got 0x{content:02X}'
