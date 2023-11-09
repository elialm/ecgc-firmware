# Cart register documentation

This document describes the cart registers implemented by the Memory
Bank Controller Hypervisor (MBCH).
The VHDL implementation of these registers can be found in
[/src/mbch.vhd](/src/mbch.vhd).

# Overview

| Name | Address | Access | Short description |
| ---- | ---- | ---- | ---- |
| MBCH_EFB_* | `0xA000` - `0xA0FF` | R/W | Registers mapped to MachXO3D EFB |
| MBCH_CTRL | `0xA100` | R/W | MBCH control register |
| MBCH_MEMSEL0 | `0xA200` | R/W | DRAM bank selection register 0 |
| MBCH_MEMSEL1 | `0xA300` | R/W | DRAM bank selection register 1 |

# Registers

## MBCH_EFB_*

This area of memory is mapped to the EFB block in the MachXO3D FPGA family.
The EFB block provides an interface to some hardend functions (e.g. SPI and flash).

The range `0xA000` - `0xA0FF` (256 addresses) is mapped to the 8-bit address bus
of the EFB block.
In other words, the lower 8 bits in the address are directly connected to the
EFB address bus.
For example, address `0xA054` is mapped to address `0x54` in the EFB block.

For a description of the EFB registers, refer to Lattice's
[Using Hardend Control Functions MachXO3D Reference](/doc\FPGA-TN-02119-1-3-Using-Hardened-Control-Functions-MachXO3D-Reference.pdf).

Note that not all EFB functions are enabled.
Reading from or writing to these registers is undefined behaviour.
Reading from or writing to addresses not mentioned in the EFB reference is
also undefined behaviour.

## MBCH_CTRL

<table class="table-register-description">
    <tr>
        <td>Bit</td>
        <td>7</td>
        <td>6</td>
        <td>5</td>
        <td>4</td>
        <td>3</td>
        <td>2</td>
        <td>1</td>
        <td>0</td>
    </tr>
    <tr>
        <td>Name</td>
        <td>RST</td>
        <td>BRASET</td>
        <td>BRAGET</td>
        <td>DRAMR</td>
        <td>(Reserved)</td>
        <td class="center" colspan="3">MBCSEL[2..0]</td>
    </tr>
    <tr>
        <td>Default</td>
        <td>0</td>
        <td>1</td>
        <td>1</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr>
        <td>Access</td>
        <td>R/W</td>
        <td>R/W</td>
        <td>R</td>
        <td>R</td>
        <td>-</td>
        <td>R/W</td>
        <td>R/W</td>
        <td>R/W</td>
    </tr>
</table>

### Reset (RST)

Pulse the reset line in the FPGA fabric by writing a `1` to this bit.
This will also pulse the Gameboy reset, resetting the Gameboy.

### Boot ROM accessible set (BRASET)

**NOTE: subject to change**

Set whether the boot ROM is accessible or not.
Setting this bit to `0` will render the boot ROM inaccessible after the next reset.

### Boot ROM accessible get (BRAGET)

**NOTE: subject to change**

Indicates whether the boot ROM is currently inaccessible or not.

|||
| ---- | ---- |
| 0 : | boot ROM is inaccessible and reads and writes to it instead go to lower 4kB of DRAM bank 0. |
| 1 : | boot ROM is accessible |

The boot ROM is mapped to the lower 4kB range of the cartridge at boot.
It contains the first bootloader of the cartridge and is the first code to run on 
the Gameboy.

### DRAMR

Indicates whether the DRAM initialisation has been done successfully.

|||
| ---- | ---- |
| 0 : | DRAM is not initialised |
| 1 : | DRAM is initialised |

This bit should be checked before doing anything with the DRAM.
Performing any action with the DRAM while this bit indicates that DRAM is 
uninitialised is undefined behaviour.

### MBCSEL[2..0]

Value used to select the acting MBC.
The acting MBC will be set to the one selected in this register after a reset.
MBCH is selected by default, so after another MBC is active the cartridge
can switch back by resetting the cartridge.

For example in the following situation:  
1. Gameboy is turned on
    - This will use MBCH by default.
2. MBCSEL is set to `100`
    - This will turn off any MBC involvement, routing memory transactions
    directly to DRAM bank 0 and 1.
    - This change will only occur **after** a reset.
3. Cartridge is reset
    - The cartridge now switches to no MBC.
4. Cartridge is reset again
    - The cartridge now switches back to MBCH.

Valid selection values are:

|||
| ---- | ---- |
| 000 | MBCH |
| 001 | MBC1 **(NYI)** |
| 010 | MBC3 **(NYI)** |
| 011 | MBC5 **(NYI)** |
| 100 | No MBC **(NYI)** |

Using other values shall result in undefined behaviour.

## MBCH_MEMSEL0

**TODO: document**

## MBCH_MEMSEL1

**TODO: document**

<style>
.table-register-description tr td {
    min-width: 3rem;
    border-left: 1px solid grey;
    border-right: 1px solid grey;
}

.center {
    text-align: center;
}
</style>