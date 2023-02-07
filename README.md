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

# Development tools

The FPGA used is the [LCMXO3D-9400HC-5BG256C](https://nl.mouser.com/ProductDetail/Lattice/LCMXO3D-9400HC-5BG256C?qs=P1JMDcb91o6QDVkyLV%2FaZw%3D%3D).
This FPGA is developed by Lattice.

Lattice has their own [Lattice Diamond Software](https://www.latticesemi.com/latticediamond)
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