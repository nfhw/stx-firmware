# NFC Intercom

## Command Message Device → App

### Common Message

NFC Comms are conceived from two protocols:

- FTM *(Fast Transfer Mode)* Protocol is inherited from STMicroelectronics described as Figure 18,19 at <https://www.st.com/resource/en/user_manual/dm00288894.pdf#page=21>.
  - **Note:** *FTM Protocol* implies protocol conceived by ST25 manual for demo purposes, while *FTM* is a mode of operation for transferring data between I2C and NFC buses.
- PB *(Protocol Buffers)* Protocol is inherited from Google described at <https://developers.google.com/protocol-buffers/docs/encoding>.
  - **Note:** MCU parser slightly deviates from canonical parsers, e.g. eager evaluation, no message merging, max message size is 251 Bytes.

### Common Frame

The tags in square braces have following meanings:

- `BL`: Command is understood by bootloader firmware.
- `FW`: Command is understood by main firmware.
- exactly one of:
  - `D2H`: Communication initiated by gadget device, e.g. LoRa button.
  - `H2D`: Communication initiated by external host, e.g. phone device.

<table>
  <tr>
    <th>Byte</th>
    <th>Content</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>0</td>
    <td>Fct</td>
    <td>
      Function<br>
    </td>
  </tr>
  <tr>
    <td>1</td>
    <td>C/R/A</td>
    <td>
      0: Command<br>
      1: Response<br>
      2: Acknowledge<br>
    </td>
  </tr>
  <tr>
    <td>2</td>
    <td>Err</td>
    <td>
      0: No Error<br>
      1: Default Error<br>
      2: Unknown Function<br>
      3: Bad Request<br>
      4: Length Error<br>
      5: Chunk Error<br>
      6: Protocol Error<br>
    </td>
  </tr>
  <tr>
    <td>3</td>
    <td>Chain</td>
    <td>
      0: Simple Frame<br>
      1: Chained Frame<br>
    </td>
  </tr>
</table>

### Simple Frame

<table>
  <tr>
    <th>Extends</th>
    <td>Common Frame</td>
  </tr>
</table>

<table>
  <tr>
    <th>Byte</th>
    <th>Content</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>0</td>
    <td>Fct</td>
    <td>
      <code>0x08: [H2D BL FW]</code> Present Password<br>
      <code>0x10: [H2D    FW]</code> Change Password<br>
      <code>0x20: [H2D    FW]</code> Read Device Configuration<br>
      <code>0x21: [H2D    FW]</code> Configure Device<br>
      <code>0x22: [H2D    FW]</code> Read Device Sensors<br>
      <code>0xFF: [H2D BL FW]</code> Factory Reset<br>
    </td>
  </tr>
  <tr>
    <td>3</td>
    <td>Chain</td>
    <td>
      0: Simple Frame<br>
    </td>
  </tr>
  <tr>
    <td>4</td>
    <td>Len</td>
    <td>
      0 .. 251: Length of data<br>
    </td>
  </tr>
  <tr>
    <td>5 .. 255</td>
    <td>Data</td>
    <td>
      Content determined by <em>Fct</em> and <em>C/R/A.</em><br>
    </td>
  </tr>
</table>

### Chained Frame

**Note:** FTM protocol header employs big endian values, where low offset is most significant byte. e.g. `0x00 0x01` is value 1.

<table>
  <tr>
    <th>Extends</th>
    <td>Common Frame</td>
  </tr>
</table>

<table>
  <tr>
    <th>Byte</th>
    <th>Content</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>0</td>
    <td>Fct</td>
    <td>
      <code>0x04: [H2D BL   ]</code> Upload Main Firmware<br>
    </td>
  </tr>
  <tr>
    <td>3</td>
    <td>Chain</td>
    <td>
      1: Chained Frame<br>
    </td>
  </tr>
  <tr>
    <td>4 .. 7</td>
    <td>Full Len</td>
    <td>
      0 .. 4294967295: Length of all data (all chunks) in chained frame.<br>
    </td>
  </tr>
  <tr>
    <td>8 .. 9</td>
    <td>Chunk Cnt</td>
    <td>
      0 .. 65535: Total number of chunks in chained frame.<br>
    </td>
  </tr>
  <tr>
    <td>10 .. 11</td>
    <td>Chunk Nr</td>
    <td>
      0 .. 65535: Current chunk number in chained frame.<br>
    </td>
  </tr>
  <tr>
    <td>12</td>
    <td>Len</td>
    <td>
      0 .. 243: Current chunk number in chained frame.<br>
    </td>
  </tr>
  <tr>
    <td>13 .. 255</td>
    <td>Data</td>
    <td>
      Content determined by <em>Fct</em> and <em>C/R/A</em>.<br>
      Offset from <em>Chunk Nr</em> * 243.<br>
    </td>
  </tr>
</table>

## Password Messages

Password is sent as discrete message. On valid entry, all consecutive messages
are privileged for 120 seconds. Invalid or empty password clears timeout,
and in case of bootloader, reboots to bootloader.

**Note:** Password stored in *Data* can be any byte value `0x00 .. 0xff`,
and is exactly 4 bytes. Further, consecutive messages prolong timeout to 120
seconds, this accommodates firmware upload that may take 5 minutes.

### Present Password

<table>
  <tr>
    <th>Extends</th>
    <td>Simple Frame</td>
  </tr>
  <tr>
    <th>Privileged</th>
    <td>No</td>
  </tr>
</table>

<table>
  <tr>
    <th rowspan="2">Step</th>
    <th rowspan="2">Sender</th>
    <th colspan="6">Wire format</th>
    <th rowspan="2">Description</th>
  </tr>
  <tr>
    <th>Fct</th>
    <th>C/R/A</th>
    <th>Err</th>
    <th>Chain</th>
    <th>Len</th>
    <th>Data</th>
  </tr>
  <tr>
    <td>A</td>
    <td>Host</td>
    <td><code>0x08</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x04</code></td>
    <td><code>0x12&nbsp;0x34&nbsp;0x56&nbsp;0x78</code></td>
    <td>Present a password 12345678.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x08</code></td>
    <td><code>0x01</code></td>
    <td><code>0x03</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Tell password is invalid. Timeout cleared.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x08</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Tell password is valid. Timeout set 120 seconds.</td>
  </tr>
</table>

### Change Password

<table>
  <tr>
    <th>Extends</th>
    <td>Simple Frame</td>
  </tr>
  <tr>
    <th>Privileged</th>
    <td>Required</td>
  </tr>
</table>

<table>
  <tr>
    <th rowspan="2">Step</th>
    <th rowspan="2">Sender</th>
    <th colspan="6">Wire format</th>
    <th rowspan="2">Description</th>
  </tr>
  <tr>
    <th>Fct</th>
    <th>C/R/A</th>
    <th>Err</th>
    <th>Chain</th>
    <th>Len</th>
    <th>Data</th>
  </tr>
  <tr>
    <td>A</td>
    <td>Host</td>
    <td><code>0x10</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x04</code></td>
    <td><code>0x12&nbsp;0x34&nbsp;0x56&nbsp;0x78</code></td>
    <td>Change password to 12345678.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x10</code></td>
    <td><code>0x01</code></td>
    <td><code>0x03</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Require prior password authentication.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x10</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Password has been changed. You're still privileged.</td>
  </tr>
</table>

## Factory Reset Messages

It clears entire EEPROM, without password. Thus password, LoRa configs and
others are reset to hard coded values. Then the firmware resets.

<table>
  <tr>
    <th>Extends</th>
    <td>Simple Frame</td>
  </tr>
  <tr>
    <th>Privileged</th>
    <td>No</td>
  </tr>
</table>

<table>
  <tr>
    <th rowspan="2">Step</th>
    <th rowspan="2">Sender</th>
    <th colspan="6">Wire format</th>
    <th rowspan="2">Description</th>
  </tr>
  <tr>
    <th>Fct</th>
    <th>C/R/A</th>
    <th>Err</th>
    <th>Chain</th>
    <th>Len</th>
    <th>Data</th>
  </tr>
  <tr>
    <td>A</td>
    <td>Host</td>
    <td><code>0xFF</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Request a firmware reset.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0xFF</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>State cleared. Firmware being reset.</td>
  </tr>
</table>

## Bootloader Messages

Firmware is sent as a series of messages, prepended by password authentication.
The upload commands work from either bootldr or mainfw transparently. During
upload, transaction is unidirectional, every message is guaranteed by st25dv
noticing when phone has read its mailbox, blocking further writes otherwise.
Maximum firmware upload size is 160KiB (163840B). Transfer speed is 178B/s, thus
67 KiB binary may take about 5 minutes. Some modern phone can do 1.5 minutes.

Once last chunk is received, device produces crc32 checksum of firmware in
flash, and replies that to ST25DV app. ST25DV acknowledges the checksum with
final message. If good, boots mainfw, otherwise device sits in bootloader
indefinitely.

In case the mainfw has been borked, there's a 4 second delay before bootldr
boots mainfw during power-up, given valid password, the timeout extends to
120 seconds, with opportunity to re-flash.

**Note:** Firmware is written eagerly, don't cut off the streams.

<table>
  <tr>
    <th>Extends</th>
    <td>Chained Frame</td>
  </tr>
  <tr>
    <th>Privileged</th>
    <td>Required</td>
  </tr>
</table>

<table>
  <tr>
    <th rowspan="2">Step</th>
    <th rowspan="2">Sender</th>
    <th colspan="9">Wire format</th>
    <th rowspan="2">Description</th>
  </tr>
  <tr>
    <th>Fct</th>
    <th>C/R/A</th>
    <th>Err</th>
    <th>Chain</th>
    <th>Full Len</th>
    <th>Chunk Cnt</th>
    <th>Chunk Nr</th>
    <th>Len</th>
    <th>Data</th>
  </tr>
  <tr>
    <td>C</td>
    <td>Host</td>
    <td><code>0x04</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00&nbsp;0x01&nbsp;0x0d&nbsp;0x30</code></td>
    <td><code>0x01&nbsp;0x1c</code></td>
    <td><code>0x00&nbsp;0x01</code></td>
    <td><code>0xf3</code></td>
    <td>
      <code>0x00&nbsp;0x50&nbsp;0x00&nbsp;0x20<br></code>
      <code>0x6d&nbsp;0x3c&nbsp;0x01&nbsp;0x08<br></code>
      <code>0xed&nbsp;0x3c&nbsp;0x01&nbsp;0x08<br></code>
      <code>0xef&nbsp;0x3c&nbsp;0x01&nbsp;0x08<br></code>
      <code>...</code>
    </td>
    <td>Start Uploading new mainfw. 1st chunk.</td>
  </tr>
  <tr>
    <td>D</td>
    <td>Host</td>
    <td><code>0x04</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00&nbsp;0x01&nbsp;0x0d&nbsp;0x30</code></td>
    <td><code>0x01&nbsp;0x1c</code></td>
    <td><code>0x00&nbsp;0x02</code></td>
    <td><code>0xf3</code></td>
    <td>
      <code>...</code>
    </td>
    <td>2nd chunk.</td>
  </tr>
  <tr>
    <td>E..JY</td>
    <td colspan="11">...</td>
  </tr>
  <tr>
    <td>JZ</td>
    <td>Host</td>
    <td><code>0x04</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x01</code></td>
    <td><code>0x78&nbsp;0x01&nbsp;0x0d&nbsp;0x30</code></td>
    <td><code>0x01&nbsp;0x1c</code></td>
    <td><code>0x01&nbsp;0x1c</code></td>
    <td><code>0x8f</code></td>
    <td>
      <code>...</code>
    </td>
    <td>Final chunk.</td>
  </tr>
  <tr>
    <td>KA</td>
    <td>Device</td>
    <td><code>0x04</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00</code></td>
    <td colspan="4"><code>0x00</code></td>
    <td><code>0x04</code></td>
    <td>
      <code>0x78&nbsp;0x56&nbsp;0x34&nbsp;0x12</code>
    </td>
    <td>Respond crc32 of flashed firmware.</td>
  </tr>
  <tr>
    <td>KB</td>
    <td>Host</td>
    <td><code>0x04</code></td>
    <td><code>0x02</code></td>
    <td><code>0x00</code></td>
    <td colspan="4"><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Acknowledge the crc32 is good.</td>
  </tr>
  <tr>
    <td>KB</td>
    <td>Host</td>
    <td><code>0x04</code></td>
    <td><code>0x02</code></td>
    <td><code>0x01</code></td>
    <td colspan="4"><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Acknowledge the crc32 is bad.</td>
  </tr>
</table>

## Configuration Message

Configuration Parameters:

 <table>
  <tr>
    <th>Field Name</th>
    <th>Field Number</th>
    <th>Wire Type</th>
    <th>Key</th>
    <th>Sample Value</th>
  </tr>
  <tr>
    <td>Part Number [read only]</td>
    <td>1</td>
    <td>enum</td>
    <td>0x08</td>
    <td>STA, STX, STE</td>
  </tr>
  <tr>
    <td>FW Version [read only]</td>
    <td>2</td>
    <td>uint32</td>
    <td>0x10</td>
    <td>1.0</td>
  </tr>
  <tr>
    <td>Secure Element empty Slots [read only]</td>
    <td>3</td>
    <td>uint32</td>
    <td>0x18</td>
    <td>3</td>
  </tr>
  <tr>
    <td>Secure Element Use</td>
    <td>4</td>
    <td>bool</td>
    <td>0x18</td>
    <td>false</td>
  </tr>
  <tr>
    <td>LoRa OTAA</td>
    <td>5</td>
    <td>bool</td>
    <td>0x18</td>
    <td>true: OTAA, false: ABP</td>
  </tr>
  <tr>
    <td>LoRa Device EUI</td>
    <td>6</td>
    <td>fixed64</td>
    <td>0x21</td>
    <td>0x64, 0x65, 0x76, 0x69, 0x63, 0x65, 0x30, 0x32</td>
  </tr>
  <tr>
    <td>LoRa Application EUI</td>
    <td>7</td>
    <td>fixed64</td>
    <td>0x29</td>
    <td>0x70, 0xB3, 0xD5, 0x7E, 0xF0, 0x00, 0x51, 0x2F</td>
  </tr>
  <tr>
    <td>LoRa App Key</td>
    <td>8</td>
    <td>bytes</td>
    <td>0x32</td>
    <td>0x81, 0xFF, 0x80, 0xDE, 0x5E, 0x8F, 0x5C, 0x8E, 0x50, 0x84, 0x32, 0x24, 0xFF, 0x29, 0x2C, 0x42</td>
  </tr>
  <tr>
    <td>LoRa Device Address</td>
    <td>9</td>
    <td>fixed32</td>
    <td>0x3d</td>
    <td>0x26012A77</td>
  </tr>
  <tr>
    <td>LoRa NWKSKEY</td>
    <td>10</td>
    <td>bytes</td>
    <td>0x42</td>
    <td>0x9C, 0x1E, 0xDA, 0xE8, 0x57, 0x2C, 0xA0, 0x7F, 0x5F, 0x7E, 0x7B, 0x11, 0x3C, 0xD4, 0xF1, 0x50</td>
  </tr>
  <tr>
    <td>LoRa APPSKEY</td>
    <td>11</td>
    <td>bytes</td>
    <td>0x4a</td>
    <td>0x77, 0x9B, 0x7F, 0xFC, 0xE1, 0x0C, 0xD2, 0xA4, 0x9D, 0x05, 0xB5, 0xF5, 0x8E, 0xEA, 0xA1, 0x7B</td>
  </tr>
  <tr>
    <td>LoRa Join Status</td>
    <td>12</td>
    <td>bool</td>
    <td>0x50</td>
    <td>false</td>
  </tr>
  <tr>
    <td>LoRa Frequency Plan</td>
    <td>13</td>
    <td>enum</td>
    <td>0x58</td>
    <td>EU868, US915</td>
  </tr>
  <tr>
    <td>LoRa Port</td>
    <td>14</td>
    <td>uint32</td>
    <td>0x60</td>
    <td>3</td>
  </tr>
  <tr>
    <td>LoRa Tx Power</td>
    <td>15</td>
    <td>uint32</td>
    <td>0x68</td>
    <td>5</td>
  </tr>
  <tr>
    <td>LoRa Spreading Factor</td>
    <td>16</td>
    <td>uint32</td>
    <td>0x70</td>
    <td>9</td>
  </tr>
  <tr>
    <td>LoRa Bandwidth</td>
    <td>17</td>
    <td>enum</td>
    <td>0x78</td>
    <td>125kHz</td>
  </tr>
  <tr>
    <td>LoRa Confirmed Messages</td>
    <td>18</td>
    <td>bool</td>
    <td>0x80 0x01</td>
    <td>true</td>
  </tr>
  <tr>
    <td>LoRa Adaptive Data Rate</td>
    <td>19</td>
    <td>bool</td>
    <td>0x88 0x01</td>
    <td>true</td>
  </tr>
  <tr>
    <td>LoRa Respect Duty Cycle</td>
    <td>20</td>
    <td>bool</td>
    <td>0x90 0x01</td>
    <td>true</td>
  </tr>
  <tr>
    <td>Time Base</td>
    <td>21</td>
    <td>uint32</td>
    <td>0x98 0x01</td>
    <td>1: second (min), 129600: 36 hours (max) </td>
  </tr>
  <tr>
    <td>Send Trigger</td>
    <td>22</td>
    <td>uint32</td>
    <td>0xa0 0x01</td>
    <td>0: always send, 1: send if changed</td>
  </tr>
  <tr>
    <td>Send Strategy</td>
    <td>23</td>
    <td>uint32</td>
    <td>0xa8 0x01</td>
    <td>0: periodic, 1: instant, 2: both</td>
  </tr>
  <tr>
    <td>Temperature Upper Threshold</td>
    <td>24</td>
    <td>uint32</td>
    <td>0xb0 0x01</td>
    <td>°C</td>
  </tr>
  <tr>
    <td>Temperature Lower Threshold</td>
    <td>25</td>
    <td>uint32</td>
    <td>0xb8 0x01</td>
    <td>°C</td>
  </tr>
  <tr>
    <td>Luminance Upper Threshold</td>
    <td>26</td>
    <td>uint32</td>
    <td>0xc0 0x01</td>
    <td>lx</td>
  </tr>
  <tr>
    <td>Luminance Lower Threshold</td>
    <td>27</td>
    <td>uint32</td>
    <td>0xc8 0x01</td>
    <td>lx</td>
  </tr>
  <tr>
    <td>X-Axis Acceleration Threshold</td>
    <td>28</td>
    <td>uint32</td>
    <td>0xd0 0x01</td>
    <td>m/s²</td>
  </tr>
  <tr>
    <td>Y-Axis Acceleration Threshold</td>
    <td>29</td>
    <td>uint32</td>
    <td>0xd8 0x01</td>
    <td>m/s²</td>
  </tr>
 <tr>
    <td>Z-Axis Acceleration Threshold</td>
    <td>30</td>
    <td>uint32</td>
    <td>0xe0 0x01</td>
    <td>m/s²</td>
  </tr>
</table>

## Sensor Messages

Sensor Parameters:

 <table>
  <tr>
    <th>Field Name</th>
    <th>Field Number</th>
    <th>Wire Type</th>
    <th>Key</th>
    <th>Sample Value</th>
    <th>Unit</th>
  </tr>
  <tr>
    <td>Part Number</td>
    <td>1</td>
    <td>enum</td>
    <td>0x08</td>
    <td>STA</td>
    <td>-</td>
  </tr>
  <tr>
    <td>Battery Voltage</td>
    <td>2</td>
    <td>sint32</td>
    <td>0x10</td>
    <td>2.28</td>
    <td>V</td>
  </tr>
  <tr>
    <td>Temperature</td>
    <td>3</td>
    <td>sint32</td>
    <td>0x18</td>
    <td>22.23</td>
    <td>°C</td>
  </tr>
  <tr>
    <td>Humidity (relative)</td>
    <td>4</td>
    <td>uint32</td>
    <td>0x20</td>
    <td>80</td>
    <td>%</td>
  </tr>
  <tr>
    <td>Pressure</td>
    <td>5</td>
    <td>uint32</td>
    <td>0x28</td>
    <td>500</td>
    <td>Pa</td>
  </tr>
  <tr>
    <td>Air Quality</td>
    <td>6</td>
    <td>uint32</td>
    <td>0x30</td>
    <td>100</td>
    <td>(Quality Index)</td>
  </tr>
  <tr>
    <td>Luminance</td>
    <td>7</td>
    <td>uint32</td>
    <td>0x38</td>
    <td>200</td>
    <td>lx</td>
  </tr>
  <tr>
    <td>X-Axis Acceleration</td>
    <td>8</td>
    <td>sint32</td>
    <td>0x40</td>
    <td>10</td>
    <td>m/s²</td>
  </tr>
  <tr>
    <td>Y-Axis Acceleration</td>
    <td>9</td>
    <td>sint32</td>
    <td>0x48</td>
    <td>10</td>
    <td>m/s²</td>
  </tr>
  <tr>
    <td>Z-Axis Acceleration</td>
    <td>10</td>
    <td>sint32</td>
    <td>0x50</td>
    <td>10</td>
    <td>m/s²</td>
  </tr>
  <tr>
    <td>Gesture Single Count</td>
    <td>11</td>
    <td>uint32</td>
    <td>0x58</td>
    <td>100</td>
    <td>-</td>
  </tr>
  <tr>
    <td>Gesture Double Count</td>
    <td>12</td>
    <td>uint32</td>
    <td>0x60</td>
    <td>100</td>
    <td>-</td>
  </tr>
  <tr>
    <td>Gesture Long Count</td>
    <td>13</td>
    <td>uint32</td>
    <td>0x68</td>
    <td>100</td>
    <td>-</td>
  </tr>
</table>

Protobuf utilizes the following schema ([style guide](https://developers.google.com/protocol-buffers/docs/style)):

```protobuf
// Version: 2022-05-24T00:00Z
syntax = "proto3";
package stxfw;
import "google/protobuf/descriptor.proto";

extend google.protobuf.FieldOptions {
  bool readonly = 50000;
}

extend google.protobuf.FieldOptions {
  // | auth | noauth | Inspired by Unix permissions.
  // |------|--------|
  // | r-   | --     | Not configurable. Need password.
  // | r-   | r-     | Not configurable. Can read without password.
  // | rw   | --     | Need password.
  // | rw   | r-     | Need password to configure.
  // | rw   | rw     | Anyone can read and configure.
  uint32 perm = 50001;
}

enum PartNr {
  PARTNR_UNSPECIFIED = 0;
  PARTNR_STA = 1;
  PARTNR_STX = 2;
  PARTNR_STE = 3;
}

// Bandwidth
enum BW {
  BW_UNSPECIFIED = 0;
  BW_125 = 1; // 125kHz
  BW_250 = 2; // 250kHz
  BW_500 = 3; // 500kHz
}

// Frequency Plan
enum FP {
  FP_UNSPECIFIED = 0;
  FP_EU868 = 1; // EU868
  FP_US915 = 2; // US915
}

message DeviceConfiguration {
  // Device Configuration
  // r-r-  1:  uint8_t  Device n-fuse Part Number
  // r-r-  2:  uint8_t  Firmware n-fuse release build number
  //     Raw range: [0..127]. Value range: [0.0..12.7] ver
  //     Example: 13 is v1.3
  //     Version = Raw / 10
  //     Notes:
  //         Likely will be seen in some form via `git tag`
  PartNr device_part_number = 1 [(readonly) = true, (perm) = 0xA];
  uint32 device_fw_version = 2 [(readonly) = true, (perm) = 0xA];

  oneof has_secure_element_empty_slots {uint32 secure_element_empty_slots = 3 [(readonly) = true];}
  oneof has_secure_element_use {bool secure_element_use = 4;}

  // LoRa settings
  // rwr-  5:     bool  (TTN) Activation Method
  //     Example: false is ABP, true is OTAA
  // rwr-  6:  char[8]  (TTN) Device EUI
  //     Example: 0x3230656369766564 is MSB {0x64, 0x65, 0x76, 0x69, 0x63, 0x65, 0x30, 0x32}
  //     Side-Effect: Change Unjoins OTAA. Device tries 5x Join on each wakeup. Heed LoRaWAN restrictions: 5x, 5x, 2x, 57m35s duty-cycle.
  //     Side-Effect: All 0 is replaced with the device-specific Dev EUI. Phone app should read new Dev EUI.
  // rwr-  7:  char[8]  (TTN) Application EUI
  //     Example: 0x2f5100f07ed5b370 is MSB {0x70, 0xB3, 0xD5, 0x7E, 0xF0, 0x00, 0x51, 0x2F}
  //     Side-Effect: Change Unjoins OTAA. Device tries 5x Join on each wakeup. Heed LoRaWAN restrictions: 5x, 5x, 2x, 57m35s duty-cycle.
  // rw--  8: char[16]  (TTN) App Key
  //     Example: "\x81\xff\x80\xde\x5e\x8f\x5c\x8e\x50\x84\x32\x24\xff\x29\x2c\x42" is MSB {0x81, 0xFF, 0x80, 0xDE, 0x5E, 0x8F, 0x5C, 0x8E, 0x50, 0x84, 0x32, 0x24, 0xFF, 0x29, 0x2C, 0x42}
  //     Special: All 0 disables Join on Wakeup.
  // rwr-  9: uint32_t  (TTN) Device Address
  //     Example: 0x26012a77 is 0x26012a77
  // rw-- 10: char[16]  (TTN) Network Session Key
  //     Example: "\x9C\x1E\xDA\xE8\x57\x2C\xA0\x7F\x5F\x7E\x7B\x11\x3C\xD4\xF1\x50" is MSB {0x9C, 0x1E, 0xDA, 0xE8, 0x57, 0x2C, 0xA0, 0x7F, 0x5F, 0x7E, 0x7B, 0x11, 0x3C, 0xD4, 0xF1, 0x50}
  // rw-- 11: char[16]  (TTN) App Session Key
  //     Example: "\x77\x9B\x7F\xFC\xE1\x0C\xD2\xA4\x9D\x05\xB5\xF5\x8E\xEA\xA1\x7B" is MSB {0x77, 0x9B, 0x7F, 0xFC, 0xE1, 0x0C, 0xD2, 0xA4, 0x9D, 0x05, 0xB5, 0xF5, 0x8E, 0xEA, 0xA1, 0x7B}
  // rwr- 12:     bool  LoRa Join status
  //     Example: false
  // rwr- 13:  uint8_t  LoRa Frequency Plan
  //     Example: FP_EU868
  // rwr- 14:  uint8_t  LoRa Port
  //     Example: 3
  // rwr- 15:  uint8_t  LoRa Transmit Power
  //     Raw range: [0..14]. Odd numbers are accepted but rounded into even numbers.
  //     Example: 5
  // rwr- 16:  uint8_t  LoRa Spreading Factor
  //     Example: 9
  // rwr- 17:  uint8_t  LoRa Bandwidth
  //     Example: BW_125 is 125 kHz
  // rwr- 18:     bool  LoRa Confirmed Messages
  //     Example: true
  // rwr- 19:     bool  LoRa Adaptive Data Rate
  //     Example: true
  // rwr- 20:     bool  LoRa Respect Duty Cycle
  //     Example: true
  oneof has_lora_otaa {bool lora_otaa = 5 [(perm) = 0xE];}
  oneof has_lora_dev_eui {fixed64 lora_dev_eui = 6 [(perm) = 0xE];}
  oneof has_lora_app_eui {fixed64 lora_app_eui = 7 [(perm) = 0xE];}
  oneof has_lora_app_key {bytes lora_app_key = 8 [(perm) = 0xC];}
  oneof has_lora_dev_addr {fixed32 lora_dev_addr = 9 [(perm) = 0xE];}
  oneof has_lora_mac_net_session_key {bytes lora_mac_net_session_key = 10 [(perm) = 0xC];}
  oneof has_lora_mac_app_session_key {bytes lora_mac_app_session_key = 11 [(perm) = 0xC];}
  oneof has_lora_joined {bool lora_joined = 12 [(perm) = 0xE];}
  oneof has_lora_fp {FP lora_fp = 13 [(perm) = 0xE];}
  oneof has_lora_port {uint32 lora_port = 14 [(perm) = 0xE];}
  oneof has_lora_txp {uint32 lora_txp = 15 [(perm) = 0xE];}
  oneof has_lora_sf {uint32 lora_sf = 16 [(perm) = 0xE];}
  oneof has_lora_bw {BW lora_bw = 17 [(perm) = 0xE];}
  oneof has_lora_confirmed_messages {bool lora_confirmed_messages = 18 [(perm) = 0xE];}
  oneof has_lora_adaptive_data_rate {bool lora_adaptive_data_rate = 19 [(perm) = 0xE];}
  oneof has_lora_respect_duty_cycle {bool lora_respect_duty_cycle = 20 [(perm) = 0xE];}

  // Sensor Settings
  // rw-- 21: uint32_t  Send interval of LoRa Messages
  //     Raw range: [1..129600] Value range: [1 second .. 36 hours].
  //     Example: 21600 is 6 hours
  //     Seconds = Raw
  // rw-- 22: uint32_t  Send Trigger
  //     Example: 0 is always send, 1 is send on change
  // rw-- 23: uint32_t  Send Strategy
  //     Example: 0 is periodic, 1 is instant, 2 is both
  // rw-- 24: uint32_t  Send LoRa Message on humidity upper threshold
  // rw-- 25: uint32_t  Send LoRa Message on humidity lower threshold
  //     Raw range: [0..99]. Value range: [0..99] %rH
  //     Example: 44 is 44 %rH
  //     Percent = Raw
  // rw-- 26:  int32_t  Send LoRa Message on temperature upper threshold
  // rw-- 27:  int32_t  Send LoRa Message on temperature lower threshold
  //     Raw range: [-4000..12499]. Value range: [-40.00..124.99] C
  //     Example: -2223 is -22.23 C
  //     Celsius = Raw / 100
  //     Note: Omitting all 4 humidity/temperature fields disables HDC2080 sensor.
  // rw-- 28: uint16_t  Send LoRa Message on luminance upper threshold
  // rw-- 29: uint16_t  Send LoRa Message on luminance lower threshold
  //     Raw range: [0..16384]. Value range: [0..16384] lx
  //     Example: 200 is 200 lx
  //     Lux = Raw
  //     Note: Omitting all 2 luminance fields disables SFH7776 sensor.
  // rw-- 30: uint32_t  Send LoRa Message on axis acceleration above threshold
  //     Raw range: [0..3907]. Value range: [0..39.07] m/s^2
  //     Example: 987 is 9.87 m/s^2
  //     Metre per second squared = Value / 100
  // rw-- 31: uint32_t  Send LoRa Message on axis acceleration configuration
  //     Example: 0x075 is on-acc-refresh with 120 ms threshold duration and evaluate threshold on all axes.
  //     | mask | value                            | description                                         |
  //     |------|----------------------------------|-----------------------------------------------------|
  //     | 0x001 | 0:on-low-power 1:on-acc-refresh | Update mode of xyz reference axes                   |
  //     | 0x00e | N = [0..7]; ms = (N + 1) * 40   | trigger if threshold for N continuous 25 Hz samples |
  //     | 0x010 | 1:evaluate 0:ignore             | evaluate x-axis                                     |
  //     | 0x020 | 1:evaluate 0:ignore             | evaluate y-axis                                     |
  //     | 0x040 | 1:evaluate 0:ignore             | evaluate z-axis                                     |
  //     | 0x300 | 0:0.85 1:0.93 2:1.1 3:1.35 uA   | noise performance (current consumption)             |
  //     Note: Omitting all 2 acceleration fields disables BMA400 sensor.
  oneof has_sensor_timebase {uint32 sensor_timebase = 21 [(perm) = 0xC];}
  oneof has_sensor_send_trigger {uint32 sensor_send_trigger = 22 [(perm) = 0xC];}
  oneof has_sensor_send_strategy {uint32 sensor_send_strategy = 23 [(perm) = 0xC];}
  oneof has_sensor_humidity_upper_threshold {uint32 sensor_humidity_upper_threshold = 24 [(perm) = 0xC];}
  oneof has_sensor_humidity_lower_threshold {uint32 sensor_humidity_lower_threshold = 25 [(perm) = 0xC];}
  oneof has_sensor_temperature_upper_threshold {sint32 sensor_temperature_upper_threshold = 26 [(perm) = 0xC];}
  oneof has_sensor_temperature_lower_threshold {sint32 sensor_temperature_lower_threshold = 27 [(perm) = 0xC];}
  oneof has_sensor_luminance_upper_threshold {uint32 sensor_luminance_upper_threshold = 28 [(perm) = 0xC];}
  oneof has_sensor_luminance_lower_threshold {uint32 sensor_luminance_lower_threshold = 29 [(perm) = 0xC];}
  oneof has_sensor_axis_threshold {uint32 sensor_axis_threshold = 30 [(perm) = 0xC];}
  oneof has_sensor_axis_configure {uint32 sensor_axis_configure = 31 [(perm) = 0xC];}
}

message DeviceSensors {
  // r-r-  1:  uint8_t  Device n-fuse Part Number
  PartNr device_part_number = 1 [(readonly) = true, (perm) = 0xA];

  // r-r-  2: uint16_t  Battery Voltage
  //     Raw range: [201..327]. Value range: [2.01..3.27] V
  //     Example: 327 is 3.27 V
  //     Volts = Raw / 100
  //     Notes:
  //         sufficient: >2.5V low: >=2.3V AND <=2.5V critical: <2.3V
  oneof has_device_battery_voltage {uint32 device_battery_voltage = 2 [(readonly) = true, (perm) = 0xA];}

  // r-r-  3:  int16_t  Temperature          (STX) (STE)
  //     (STX) Raw range: [-4000..12499]. Value range: [-40.00..124.99] C.
  //     (STE) Raw range: [-4000.. 8500]. Value range: [-40.00.. 85.00] C.
  //     Example: -2223 is -22.23 C
  //     Celsius = Raw / 100
  // r-r-  4: uint32_t  Humidity             (STX) (STE)
  //     Raw range: [0..99998]. Value range: [0.000..99.998] %rH.
  //     Example: 37878 is 37.878 %rH
  //     Percent = Raw / 1000
  // r-r-  5: uint32_t  Pressure                   (STE)
  //     Raw range: [300..110000]. Value range: [30000..110000] Pa.
  //     Example: 100465 is 100465 Pa
  //     Pascal = Raw
  // r-r-  6:    float  Air Quality Index          (STE)
  //     Value range: [0..500] AQI.
  //     Example: 158.614 index
  //     AQI = Raw
  // r-r-  7: uint16_t  Luminance            (STX)
  //     Raw range: [0..16384]. Value range: [0..16384] lx.
  //     Example: 200 is 200 lx
  //     Lux = Raw
  // r-r- 14:    float  VOC Equivalent             (STE)
  //     Example: 5.344 ppm
  //     ppm = Raw
  // r-r- 15:    float  CO2 Equivalent             (STE)
  //     Example: 1817.266 ppm
  //     ppm = Raw
  // r-r- 16:  uint8_t  AQI, VOC, CO2 Accuracy     (STE)
  //     Raw range: [0..3]. Value range: [0..3] lx.
  //     Example: 0 means VOC, CO2, AQI readings are invalid
  //     0: No reading (stabilization/run-in ongoing)
  //     1: Low Accuracy
  //     2: Medium Accuracy
  //     3: High Accuracy
  //     ppm = Raw
  oneof has_sensor_temperature {sint32 sensor_temperature = 3 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_humidity {uint32 sensor_humidity = 4 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_pressure {uint32 sensor_pressure = 5 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_air_quality {float sensor_air_quality = 6 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_luminance {uint32 sensor_luminance = 7 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_air_voc_ppm {float sensor_air_voc_ppm = 14 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_air_co2_ppm {float sensor_air_co2_ppm = 15 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_air_accuracy {uint32 sensor_air_accuracy = 16 [(readonly) = true, (perm) = 0xA];}

  // r-r-  8:  int16_t  X-Axis Acceleration  (STX)
  // r-r-  9:  int16_t  Y-Axis Acceleration  (STX)
  // r-r- 10:  int16_t  Z-Axis Acceleration  (STX)
  //     Raw range: [-1960..1959]. Value range: [-19.60..19.59] m/s^2.
  //     Example: -987 is -9.87 m/s^2
  //     Metre per second squared = Raw / 100
  oneof has_sensor_x_axis {sint32 sensor_x_axis = 8 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_y_axis {sint32 sensor_y_axis = 9 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_z_axis {sint32 sensor_z_axis = 10 [(readonly) = true, (perm) = 0xA];}

  // r-r- 11:  uint8_t  Gesture count        (STA)
  oneof has_sensor_gesture_single_count {uint32 sensor_gesture_single_count = 11 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_gesture_double_count {uint32 sensor_gesture_double_count = 12 [(readonly) = true, (perm) = 0xA];}
  oneof has_sensor_gesture_long_count {uint32 sensor_gesture_long_count = 13 [(readonly) = true, (perm) = 0xA];}
}
```

The `oneof` keyword disambiguates a missing field from a field with default value, like 0. This is utilized for configuration, so if device has value 7, and host sends device a wire-format containing fixed64 field with value 0, it is set to 0, but if field is absent from wire format, it is left unchanged as 7.

The `readonly` is purely syntactic, the implication is these fields can't be configured by host. And serve only informational purpose.

The first byte in data must be a `0x00` for DeviceConfiguration, and `0x01` for DeviceSensors messages.

Comments regard protobuf value as *raw*, while *value* infers conceptual insight. Described type derives from C, and applies to *raw*, not *value*, as a narrower specifier complementary to protobuf:

- `uint16_t` (C) fits into `uint32` (protobuf), meaning larger numbers are invalid.
- `int16_t` (C) fits into `sint32` (protobuf), meaning larger numbers are invalid.
- `float` (C) matches the `float` (protobuf) in little endian.

### Read Configuration

<table>
  <tr>
    <th>Extends</th>
    <td>Simple Frame</td>
  </tr>
  <tr>
    <th>Privileged</th>
    <td>Required</td>
  </tr>
</table>

<table>
  <tr>
    <th rowspan="2">Step</th>
    <th rowspan="2">Sender</th>
    <th colspan="6">Wire format</th>
    <th rowspan="2">Description</th>
  </tr>
  <tr>
    <th>Fct</th>
    <th>C/R/A</th>
    <th>Err</th>
    <th>Chain</th>
    <th>Len</th>
    <th>Data</th>
  </tr>
  <tr>
    <td>A</td>
    <td>Host</td>
    <td><code>0x20</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Ask for configuration.</td>
  </tr>
  <tr>
    <td>A</td>
    <td>Host</td>
    <td><code>0x20</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00</code></td>
    <td>Ask for configuration.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x20</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x77</code></td>
    <td>
      <code>0x00<br></code>
      <code>0x08&nbsp;0x02<br></code>
      <code>0x18&nbsp;0x01<br></code>
      <code>0x21&nbsp;0x64&nbsp;0x65&nbsp;0x76&nbsp;0x69&nbsp;0x63&nbsp;0x65&nbsp;0x30<br></code>
      <code>0x32<br></code>
      <code>0x29&nbsp;0x70&nbsp;0xb3&nbsp;0xd5&nbsp;0x7e&nbsp;0xf0&nbsp;0x00&nbsp;0x51<br></code>
      <code>0x2f<br></code>
      <code>0x32&nbsp;0x10&nbsp;0x81&nbsp;0xff&nbsp;0x80&nbsp;0xde&nbsp;0x5e&nbsp;0x8f<br></code>
      <code>0x5c&nbsp;0x8e&nbsp;0x50&nbsp;0x84&nbsp;0x32&nbsp;0x24&nbsp;0xff&nbsp;0x29<br></code>
      <code>0x2c&nbsp;0x42<br></code>
      <code>0x3d&nbsp;0x77&nbsp;0x2a&nbsp;0x01&nbsp;0x26<br></code>
      <code>0x42&nbsp;0x10&nbsp;0x9c&nbsp;0x1e&nbsp;0xda&nbsp;0xe8&nbsp;0x57&nbsp;0x2c<br></code>
      <code>0xa0&nbsp;0x7f&nbsp;0x5f&nbsp;0x7e&nbsp;0x7b&nbsp;0x11&nbsp;0x3c&nbsp;0xd4<br></code>
      <code>0xf1&nbsp;0x50<br></code>
      <code>0x4a&nbsp;0x10&nbsp;0x77&nbsp;0x9b&nbsp;0x7f&nbsp;0xfc&nbsp;0xe1&nbsp;0x0c<br></code>
      <code>0xd2&nbsp;0xa4&nbsp;0x9d&nbsp;0x05&nbsp;0xb5&nbsp;0xf5&nbsp;0x8e&nbsp;0xea<br></code>
      <code>0xa1&nbsp;0x7b<br></code>
      <code>0x50&nbsp;0x00<br></code>
      <code>0x58&nbsp;0x01<br></code>
      <code>0x60&nbsp;0x03<br></code>
      <code>0x68&nbsp;0x05<br></code>
      <code>0x70&nbsp;0x09<br></code>
      <code>0x78&nbsp;0x01<br></code>
      <code>0x80&nbsp;0x01&nbsp;0x01<br></code>
      <code>0x88&nbsp;0x01&nbsp;0x01<br></code>
      <code>0x90&nbsp;0x01&nbsp;0x01<br></code>
      <code>0x98&nbsp;0x01&nbsp;0xe0&nbsp;0xa8&nbsp;0x01<br></code>
      <code>0xa0&nbsp;0x01&nbsp;0x01<br></code>
      <code>0xa8&nbsp;0x01&nbsp;0x01<br></code>
      <code>0xb0&nbsp;0x01&nbsp;0xcf&nbsp;0x0f<br></code>
      <code>0xb8&nbsp;0x01&nbsp;0xdd&nbsp;0x22<br></code>
      <code>0xc0&nbsp;0x01&nbsp;0xc8&nbsp;0x01<br></code>
      <code>0xc8&nbsp;0x01&nbsp;0x64<br></code>
      <code>0xd0&nbsp;0x01&nbsp;0x64<br></code>
      <code>0xd8&nbsp;0x01&nbsp;0x64<br></code>
      <code>0xe0&nbsp;0x01&nbsp;0x64<br></code>
    </td>
    <td>Provide the configuration.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x20</code></td>
    <td><code>0x01</code></td>
    <td><code>0x03</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Require prior password authentication.</td>
  </tr>
</table>

### Write Configuration

When writing configurations to device, if given semi-valid message, it may partially fail and apply due to eager parsing.

<table>
  <tr>
    <th>Extends</th>
    <td>Simple Frame</td>
  </tr>
  <tr>
    <th>Privileged</th>
    <td>Required</td>
  </tr>
</table>

<table>
  <tr>
    <th rowspan="2">Step</th>
    <th rowspan="2">Sender</th>
    <th colspan="6">Wire format</th>
    <th rowspan="2">Description</th>
  </tr>
  <tr>
    <th>Fct</th>
    <th>C/R/A</th>
    <th>Err</th>
    <th>Chain</th>
    <th>Len</th>
    <th>Data</th>
  </tr>
  <tr>
    <td>A</td>
    <td>Host</td>
    <td><code>0x21</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x60</code></td>
    <td>
      <code>0x00<br></code>
      <code>0x18&nbsp;0x01<br></code>
      <code>0x21&nbsp;0x64&nbsp;0x65&nbsp;0x76&nbsp;0x69&nbsp;0x63&nbsp;0x65&nbsp;0x30<br></code>
      <code>0x32<br></code>
      <code>0x29&nbsp;0x2f&nbsp;0x51&nbsp;0x00&nbsp;0xf0&nbsp;0x7e&nbsp;0xd5&nbsp;0xb3<br></code>
      <code>0x70<br></code>
      <code>0x32&nbsp;0x10&nbsp;0x81&nbsp;0xff&nbsp;0x80&nbsp;0xde&nbsp;0x5e&nbsp;0x8f<br></code>
      <code>0x5c&nbsp;0x8e&nbsp;0x50&nbsp;0x84&nbsp;0x32&nbsp;0x24&nbsp;0xff&nbsp;0x29<br></code>
      <code>0x2c&nbsp;0x42<br></code>
      <code>0x3d&nbsp;0x77&nbsp;0x2a&nbsp;0x01&nbsp;0x26<br></code>
      <code>0x42&nbsp;0x10&nbsp;0x9c&nbsp;0x1e&nbsp;0xda&nbsp;0xe8&nbsp;0x57&nbsp;0x2c<br></code>
      <code>0xa0&nbsp;0x7f&nbsp;0x5f&nbsp;0x7e&nbsp;0x7b&nbsp;0x11&nbsp;0x3c&nbsp;0xd4<br></code>
      <code>0xf1&nbsp;0x50<br></code>
      <code>0x4a&nbsp;0x10&nbsp;0x77&nbsp;0x9b&nbsp;0x7f&nbsp;0xfc&nbsp;0xe1&nbsp;0x0c<br></code>
      <code>0xd2&nbsp;0xa4&nbsp;0x9d&nbsp;0x05&nbsp;0xb5&nbsp;0xf5&nbsp;0x8e&nbsp;0xea<br></code>
      <code>0xa1&nbsp;0x7b<br></code>
      <code>0x58&nbsp;0x01<br></code>
      <code>0x60&nbsp;0x03<br></code>
      <code>0x68&nbsp;0x05<br></code>
      <code>0x70&nbsp;0x09<br></code>
      <code>0x78&nbsp;0x01<br></code>
      <code>0x98&nbsp;0x01&nbsp;0xe0&nbsp;0xa8&nbsp;0x01<br></code>
      <code>0xa0&nbsp;0x01&nbsp;0x01<br></code>
      <code>0xa8&nbsp;0x01&nbsp;0x01<br></code>
      <code>0xb0&nbsp;0x01&nbsp;0xcf&nbsp;0x0f<br></code>
      <code>0xb8&nbsp;0x01&nbsp;0xdd&nbsp;0x22<br></code>
      <code>0xc0&nbsp;0x01&nbsp;0xc8&nbsp;0x01<br></code>
      <code>0xc8&nbsp;0x01&nbsp;0x64<br></code>
      <code>0xd0&nbsp;0x01&nbsp;0x64<br></code>
      <code>0xd8&nbsp;0x01&nbsp;0x64<br></code>
      <code>0xe0&nbsp;0x01&nbsp;0x64<br></code>
    </td>
    <td>Pass configuration.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x21</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Configuration applied.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x21</code></td>
    <td><code>0x01</code></td>
    <td><code>0x03</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Require prior password authentication.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x21</code></td>
    <td><code>0x01</code></td>
    <td><code>0x06</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Data is partially or completely invalid.</td>
  </tr>
</table>

### Read Sensors

<table>
  <tr>
    <th>Extends</th>
    <td>Simple Frame</td>
  </tr>
  <tr>
    <th>Privileged</th>
    <td>Required</td>
  </tr>
</table>

<table>
  <tr>
    <th rowspan="2">Step</th>
    <th rowspan="2">Sender</th>
    <th colspan="6">Wire format</th>
    <th rowspan="2">Description</th>
  </tr>
  <tr>
    <th>Fct</th>
    <th>C/R/A</th>
    <th>Err</th>
    <th>Chain</th>
    <th>Len</th>
    <th>Data</th>
  </tr>
  <tr>
    <td>A</td>
    <td>Host</td>
    <td><code>0x20</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x01</code></td>
    <td><code>0x01</code></td>
    <td>Ask for sensors values.</td>
  </tr>
  <tr>
    <td>A</td>
    <td>Host</td>
    <td><code>0x22</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Ask for sensors values.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x22</code></td>
    <td><code>0x01</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td><code>0x77</code></td>
    <td>
      <code>0x01<br></code>
      <code>0x08&nbsp;0x02<br></code>
      <code>0x10&nbsp;0xe4&nbsp;0x01<br></code>
      <code>0x18&nbsp;0xdd&nbsp;0x22<br></code>
      <code>0x20&nbsp;0x80&nbsp;0xf1&nbsp;0x04<br></code>
      <code>0x28&nbsp;0xf4&nbsp;0x03<br></code>
      <code>0x30&nbsp;0x64<br></code>
      <code>0x38&nbsp;0xc8&nbsp;0x01<br></code>
      <code>0x40&nbsp;0x0e<br></code>
      <code>0x48&nbsp;0x10<br></code>
      <code>0x50&nbsp;0xb6&nbsp;0x0f<br></code>
      <code>0x58&nbsp;0x01<br></code>
      <code>0x60&nbsp;0x02<br></code>
      <code>0x68&nbsp;0x03<br></code>
    </td>
    <td>Return device sensor cvalues.</td>
  </tr>
  <tr>
    <td>B</td>
    <td>Device</td>
    <td><code>0x22</code></td>
    <td><code>0x01</code></td>
    <td><code>0x03</code></td>
    <td><code>0x00</code></td>
    <td><code>0x00</code></td>
    <td>N/A</td>
    <td>Require prior password authentication.</td>
  </tr>
</table>
