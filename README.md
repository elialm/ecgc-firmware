# Flash cartridge FPGA firmware

This project is part of the [ecgc](https://efacdev.nl/pages/project/?name=ecgc)
project.

This project contains the firmware running on the cartridge FPGA.
The FPGA is used to perform several cartridge functions including but not
limited to:
- MBC memory mapping
- Cartridge control registers
- SPI debugging
- Cartridge DMA

# Directory structure

The [Gen3Prototype](/Gen3Prototype) directory contains the firmware for the
3<sup>rd</sup> generation prototype.
It currently has no planned changes,
but I left it here as an archive.

The [Gen4](/Gen4) directory has the firmware for the current cart iteration.

# Development tools

Lattice (manufacturer of used FPGA) has their own [Lattice Diamond Software](https://www.latticesemi.com/latticediamond)
For development on their FPGAs and CLPDs.
This software is needed to open the `.ldf` file, which is the project root.
The software has toolchains for building and uploading the firmware to the
cartridge's FPGA.

One thing I do want to note is that the Diamond code editor is terrible and 
should not be used.
The editor also uses tabs instead of spaces,
which makes the code unreadable on anything other than Diamond.
Please use something like [Visual Studio Code](https://code.visualstudio.com/download)
with an appropriate VHDL extension (e.g. rjyoung's [Modern VHDL](https://github.com/richjyoung/vscode-modern-vhdl)).