# UART debug core documentation

This document describes the UART packages used to communicate with the debug
core.

## Command-based protocol

Every transaction starts with a command code.
These codes are listed in the [Command overview](#command-overview).
A command is issued by sending the appropriate command byte.
Depending on the type of command,
additional data may be sent
(e.g. `SET_ADDR`, which requires the value the address will be set to).
Additionally, some commands may instruct the core to send additional data
(e.g. `READ`, which sends the requested number of bytes).

The command byte consists of 2 parts.
The most significant 7 bits are the command bits and
the least significant bit is the acknowledgement bit.
The controller uses the command bits to decode the issued command.
Sending the command byte, the ack bit must always be `'0'`.
To acknowledge the successful decoding of the command byte,
the controller shall set this bit to a `'1'` upon resending.

To confirm the data received by the debug controller,
it shall always resend received bytes for the command issuer to verify.
Bytes shall never be modified by the controller,
the exception being the aforementioned ack bit.

## Control register

The controller has an 8-bit control register.
This register controls the controller and provides status information for the command issuer.
The register bits are explained in the table below.

**TODO: insert table**

The contents of the control register can be read and set using the `CTRL_READ` and `CTRL_WRITE` commands respectively.

## Debug address

The debug core is used primarily for operating on addresses.
The core has a configured 16-bit address which is used for these operations
(e.g. the `READ` command).
The address can be configured using the `SET_ADDR` command.

The core also includes a way for the address to be automatically incremented.
This allows for performant reads and writes of large sections of memory.
When enabled, the address will incremented after each byte operation during a
read or write.
The control for enabling and disabling the auto increment feature is in the control register.

For example, if the address is set to `0x4000` and a `READ` command for 1 byte is performed,
the next `READ` command will read from address `0x4001`.
Burst operations also increment the address with each data byte,
so if started on address `0x4000` with a burst size of 16,
a `WRITE` operation will write to addresses `0x4000` to `0x400F`
and the next operation will operate on address `0x4010`.

## Command overview

| Name       | Value  | Description                    |
| ---------- | ------ | ------------------------------ |
| CTRL_READ  | `0x02` | Read from the control register |
| CTRL_WRITE | `0x04` | Write to the control register  |
| SET_ADDR   | `0x10` | Set the of the debug address   |
| READ       | `0x20` | Read from the set address      |
| WRITE      | `0x30` | Write to the set address       |

## Command documentation

A quick note on the command documentation.
The **Response** section for every command only refers to extra data sent by the command.
This does not include the resending of received bytes,
as this always happens.

### CTRL_READ - 0x02

**Description:**  
Read the control register.

**Arguments:**  
None.

**Response:**  
The actual contents of the control register.
Note that due to the core's fast operation,
some of the status bits might have changed.

### CTRL_WRITE - 0x04

**Description:**  
Write to the control register.

**Arguments:**  
The value to which the control register is set.
Read-only bits will be ignored.
For future compatibility and consistency sake,
these bits should always be set to `'0'`.

**Response:**  
None.

### SET_ADDR - 0x10

**Description:**  
Set the 16-bit debug address.

**Arguments:**  
The 16-bit address sent as 2 bytes in little endian format.

**Response:**  
None.

### READ - 0x20

**TODO: write**

### WRITE - 0x30

**TODO: write**
