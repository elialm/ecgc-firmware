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

## Lattice Diamond

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

## ecgc-util

[ecgc-util](https://github.com/elialm/ecgc-util) is a series of tools written in Python to aid in development.
These include tools for peeking/poking in memory and flashing the boot image.

To use these tools, I recommend installing them in a virtual environment.
Run the following:


```bash
# Run once to create the virtual environment
$ python3 -m venv .venv

# Activate the virtual environment when opening a new terminal
$ source ./.venv/bin/activate

# Install ecgc-util in virtual environment
(.venv) $ python -m pip install external/ecgc-util
```

Then, the tools are available in the virtual environment.
