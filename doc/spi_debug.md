# SPI debug core documentation

This document describes the SPI packages used to communicate with the debug
core.

## Command-based protocol

Every transaction starts with a command code.
These codes are listed in the [Command overview](#command-overview).
The command must always be sent by first sending the command byte,
followed by a `NOP` command.

The SPI response to this `NOP` command indicates whether the command was
received successfully.
A successfully received command is answered by the value `0x-1`,
where the most significant nibble is the least significant nibble of the
command byte.
Unsuccessfully received commands are answered by the value `0x-0`,
where the most significant nibble is the least significant nibble of the
command byte.

## Debug address

The debug core is used primarily for operating on addresses.
The core has a configured 16-bit address which is used for these operations
(e.g. the `READ_BURST` command).
The address can be configured using commands such as `SET_ADDR_L` or 
`AUTO_INC_EN`.

## Command overview

| Name | Value | Description |
| ---- | ---- | ---- |
| NOP | `0x0F` | No operation (mostly used for reading). |
| SET_ADDR_L | `0x02` | Set the low byte of the address |
| SET_ADDR_H | `0x03` | Set the high byte of the address |
| AUTO_INC_EN | `0x04` | Enable auto increment on the address |
| AUTO_INC_DIS | `0x05` | Disable auto increment on the address |
| READ | `0x08` | Read from the set address |
| WRITE | `0x09` | Write to the set address |
| READ_BURST | `0x0A` | Read 16 bytes from the set address |
| WRITE_BURST | `0x0B` | Write 16 bytes to the set address |

## Command documentation

### NOP - 0x0F

**Protocol:**  
<table>
    <tr>
        <th>MOSI</th>
        <td><code>0x0F</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x--</code></td>
    </tr>
    <tr>
        <th>MISO</th>
        <td><code>0x--</code></td>
        <td><code>0xF1</code></td>
        <td><code>0xF1</code></td>
        <td><code>0xF1</code></td>
    </tr>
</table>

**Description:**  
No operation command.
Will do absolutely nothing.
It is mostly used as a read symbol, since when reading from SPI might mean that
the core interprets the received byte as a command.
Therefore when reading, **ALWAYS** use this command value.

### SET_ADDR_L - 0x02

**Protocol:**  
<table>
    <tr>
        <th>MOSI</th>
        <td><code>0x02</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x[ll]</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x--</code></td>
    </tr>
    <tr>
        <th>MISO</th>
        <td><code>0x--</code></td>
        <td><code>0x21</code></td>
        <td><code>0xF1</code></td>
        <td><code>0x[ll]</code></td>
        <td><code>0xF1</code></td>
    </tr>
</table>

`0x[ll]` = low address byte value to be set

**Description:**  
Set the low byte of the 16-bit debug address.

### SET_ADDR_H - 0x03

**Protocol:**  
<table>
    <tr>
        <th>MOSI</th>
        <td><code>0x03</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x[hh]</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x--</code></td>
    </tr>
    <tr>
        <th>MISO</th>
        <td><code>0x--</code></td>
        <td><code>0x31</code></td>
        <td><code>0xF1</code></td>
        <td><code>0x[hh]</code></td>
        <td><code>0xF1</code></td>
    </tr>
</table>

`0x[hh]` = high address byte value to be set

**Description:**  
Set the high byte of the 16-bit debug address.

### AUTO_INC_EN - 0x04

**Protocol:**  
<table>
    <tr>
        <th>MOSI</th>
        <td><code>0x04</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x--</code></td>
    </tr>
    <tr>
        <th>MISO</th>
        <td><code>0x--</code></td>
        <td><code>0x41</code></td>
        <td><code>0xF1</code></td>
    </tr>
</table>

**Description:**  
Enable the auto increment feature on the debug core.
When enabled, the address will incremented after each byte operation during a
read or write.

For example, if the address is set to `0x4000` and a `READ` command is performed,
the next `READ` command will read from address `0x4001`. Burst operations take 16 bytes, so if started on address `0x4000`, a `WRITE_BURST` operation will
write to addresses `0x4000` to `0x400F` and the next operation will operate
on address `0x4010`.

### AUTO_INC_DIS - 0x05

**Protocol:**  
<table>
    <tr>
        <th>MOSI</th>
        <td><code>0x05</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x--</code></td>
    </tr>
    <tr>
        <th>MISO</th>
        <td><code>0x--</code></td>
        <td><code>0x51</code></td>
        <td><code>0xF1</code></td>
    </tr>
</table>

**Description:**  
Disables the auto increment feature on the debug core.
This feature is explained in detail under [AUTO_INC_EN - 0x04](#auto_inc_en---0x04).

### READ - 0x08

**Protocol:**  
<table>
    <tr>
        <th>MOSI</th>
        <td><code>0x08</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x--</code></td>
    </tr>
    <tr>
        <th>MISO</th>
        <td><code>0x--</code></td>
        <td><code>0x81</code></td>
        <td><code>0x[rr]</code></td>
        <td><code>0x00</code></td>
        <td><code>0xF1</code></td>
    </tr>
</table>

`0x[rr]` = read byte

**Description:**  
Read the byte pointed to by the debug address.

### WRITE - 0x09

**Protocol:**  
<table>
    <tr>
        <th>MOSI</th>
        <td><code>0x09</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x[ww]</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x--</code></td>
    </tr>
    <tr>
        <th>MISO</th>
        <td><code>0x--</code></td>
        <td><code>0x91</code></td>
        <td><code>0x00</code></td>
        <td><code>0x[ww]</code></td>
        <td><code>0xF1</code></td>
    </tr>
</table>

`0x[ww]` = write byte

**Description:**  
Write a byte at the debug address.

### READ_BURST - 0x0A

**Protocol:**  
<table>
    <tr>
        <th>MOSI</th>
        <td><code>0x0A</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x0F</code></td>
        <td>...</td>
        <td><code>0x0F</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x--</code></td>
    </tr>
    <tr>
        <th>MISO</th>
        <td><code>0x--</code></td>
        <td><code>0xA1</code></td>
        <td><code>0x[r0]</code></td>
        <td><code>0x[r1]</code></td>
        <td>...</td>
        <td><code>0x[r14]</code></td>
        <td><code>0x[r15]</code></td>
        <td><code>0x00</code></td>
        <td><code>0xF1</code></td>
    </tr>
</table>

`0x[r0]` to `0x[r15]` = read bytes

**Description:**  
Read 16 bytes at the debug address.
Command is most useful when the auto increment feature is enabled
to efficiently read blocks of data.

### WRITE_BURST - 0x0B

**Protocol:**  
<table>
    <tr>
        <th>MOSI</th>
        <td><code>0x0B</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x[w0]</code></td>
        <td><code>0x[w1]</code></td>
        <td>...</td>
        <td><code>0x[w14]</code></td>
        <td><code>0x[w15]</code></td>
        <td><code>0x0F</code></td>
        <td><code>0x--</code></td>
    </tr>
    <tr>
        <th>MISO</th>
        <td><code>0x--</code></td>
        <td><code>0xB1</code></td>
        <td><code>0x00</code></td>
        <td><code>0x[w0]</code></td>
        <td>...</td>
        <td><code>0x[w13]</code></td>
        <td><code>0x[w14]</code></td>
        <td><code>0x[w15]</code></td>
        <td><code>0xF1</code></td>
    </tr>
</table>

`0x[w0]` to `0x[w15]` = write bytes

**Description:**  
Write 16 bytes at the debug address.
Command is most useful when the auto increment feature is enabled
to efficiently write blocks of data.