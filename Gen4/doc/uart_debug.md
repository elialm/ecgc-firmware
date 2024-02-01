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
The register bits are explained in the table and text below.
The contents of the control register can be read and set using the `CTRL_READ` and `CTRL_WRITE` commands respectively.

<table class="bitfield-description">
    <thead>
        <tr>
            <th class="center-text" colspan="32">Control register</th>
        </tr>
    </thead>
    <tbody>
        <tr class="bitfield-bits">
            <th>Bit index</th>
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
            <th>Name</th>
            <td class="center-text" colspan="2">Reserved</td>
            <td class="center-text">AUTO_INC</td>
            <td class="center-text">DBG_EN</td>
            <td class="center-text" colspan="4">Reserved</td>
        </tr>
        <tr>
            <th>Access</th>
            <td class="center-text" colspan="2">R</td>
            <td class="center-text">R/W</td>
            <td class="center-text">R/W</td>
            <td class="center-text" colspan="4">R</td>
        </tr>
        <tr>
            <th>Reset value</th>
            <td class="center-text" colspan="2"><code>"00"</code></td>
            <td class="center-text"><code>'0'</code></td>
            <td class="center-text"><code>'0'</code></td>
            <td class="center-text" colspan="4"><code>"0000"</code></td>
        </tr>
    </tbody>
</table>

<style>
    .center-text {
        text-align: center;
    }

    .bitfield-description td {
        border-style: solid;
        text-align: center;
        min-width: 3rem;
    }

    .bitfield-bits td {
        padding: 0.2rem;
    }
</style>

**AUTO_INC**  
Enable auto increment feature described in [Debug address](#debug-address).

**DBG_EN**  
Enable debug core.
This bit needs to be set for any of the commands to work as expected.
The only exception to this are the `CTRL_READ` and `CTRL_WRITE` commands,
which always work.

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
The single byte to which the control register is set.
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

**Description:**  
Read a specified number of bytes from the debug address.
If the auto increment feature is enabled,
the debug address will increment upon each byte read.

**Arguments:**  
Single byte value specifying how many bytes are to be read.
The number of bytes to be read follow the formula `bytes read = val + 1`.
This gives an effective range of 1 to 256 bytes.

**Response:**  
Data read from the debug address.
The number of bytes will be the value specified in the argument.

### WRITE - 0x30

**Description:**  
Write a specified number of bytes to the debug address.
If the auto increment feature is enabled,
the debug address will increment upon each byte written.

**Arguments:**  
Single byte value specifying how many bytes are to be written,
followed by the data to be written.
The number of bytes to be written follow the formula `bytes written = val + 1`.
This gives an effective range of 1 to 256 bytes.

**Response:**  
None.
