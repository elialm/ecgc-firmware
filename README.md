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

# Developer guide

## Running tests

> [!IMPORTANT]
> It is assumed that the instructions at [cocotb](#cocotb) were followed and the virtual environment is activated.

Tests are ran using cocotb.
Available tests can be ran with the cocotb test runner:

```bash
(.venv) $ python tests/test_runner.py
```

## Adding tests

The tests are structured per entity in the sources.
The test runner will look for Python scripts inside [tests/testbenches](tests/testbenches)
(with the exception of special files like `__ini__.py`)
and assume each to contain tests for a toplevel of the same name.
For example, a file `tests/testbenches/example.py` will look for a toplevel entity named `example` in the RTL sources.

When tests for an entity exist,
one can locate the existing test file for that entity and add tests there as how
it is described in the [cocotb docs](https://docs.cocotb.org/en/stable/writing_testbenches.html#).

When adding an entity,
one has to create a file with the same name of that new entity
and put it in the [tests/testbenches](tests/testbenches) directory.
Tests can then be added to that file and will be automatically be picked up by the test runner.

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
(.venv) $ pip install external/ecgc-util
```

Then, the tools are available in the virtual environment.

## cocotb

[cocotb](https://www.cocotb.org/) is used to write and run testbenches
cocotb is a Python framework that can start a simulator and exposes the DUT
as a Python object which can then be used to provide triggers and assertions to designs.

For running tests, an appropriate simulator is necessary.
In theory all supported simulators should work, but I've used [GHDL](http://ghdl.free.fr/).
There might be some configurations that assume this, so it's best to use GHDL.
This needs to be installed first on the system.
If on Ubuntu/Debian, GHDL can be installed via `apt`:

```bash
sudo apt install ghdl
```

cocotb and its dependencies need to be installed in the virtual environment as well.
If the environment has not been created before, create it.
Then the dependencies can be installed:

```bash
# Run once to create the virtual environment (if not done yet)
$ python3 -m venv .venv

# Activate the virtual environment when opening a new terminal
$ source ./.venv/bin/activate

# Install cocotb and dependencies
(.venv) $ pip install -r requirements.txt
```
