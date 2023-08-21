# LoRaWAN

For LoRaWAN only uplink payload messages are described. Network related messages
like for the join procedure are not described here.

Things to consider:

- Bandwidth is scarce, so we have to use a binary format
- There are *Scheduled Messages* and *Event triggered Messages*
- Multi-byte fields are little endian

## Message Types

There are two different types of message types which vary slightly
depending on the variant used.

### Scheduled

Scheduled is a message type, which automatically sends a messages
at some regular time interval set by the user.
The _time base_ defines the interval in which the device wakes up.
By default with every wake up a message is sent.

### Event Triggered

Event triggered is a message type, which sends a message at certain events
like exceeding a certain threshold for acceleration or a temperature.
The possible events depend on the device variants and user configuration.

## Base Message

This message format is common for all device variants.

<table>
  <tr>
    <th>Trigger</th>
    <td>Depending on variant and configuration</td>
  </tr>
  <tr>
    <th>LoRaWAN Port</th>
    <td>1</td>
  </tr>
</table>

<table>
  <tr>
    <th>Byte</th>
    <th>Content</th>
    <th>Description</th>
  </tr>
  <tr>
    <td valign="top">0</td>
    <td valign="top">Version (u2) [7:6]</td>
    <td valign="top">
      Designator for the message format version used:<br>
      Possible value range (decimal): 0 - 3<br>
      1: Second version<br>
    </td>
  </tr>
  <tr>
    <td valign="top">0</td>
    <td valign="top">TX Power (u3) [4:2]</td>
    <td valign="top">
      Note that the index and the dB strength are reversed:<br>
      Possible value range (raw): 0 - 7<br>
      Possible value range (dB): 0 - 14<br>
      0: 14 dB<br>
      1: 12 dB<br>
      2: 10 dB<br>
      3:  8 dB<br>
      4:  6 dB<br>
      5:  4 dB<br>
      6:  2 dB<br>
      7:  0 dB<br>
    </td>
  </tr>
  <tr>
    <td valign="top">1</td>
    <td valign="top">Battery Voltage (u7, fix-point) [6:0]</td>
    <td valign="top">
      Battery voltage level<br>
      value [V] = (message_value / 100.0) + 2.<br>
      Possible range (raw): 1 .. 127, 0 is a special value indicating a faulty reading<br>
      Possible range (decimal):  2.01 V .. 3.27 V, values below 2.01 V will be mapped to 2.01 V, values above 3.27 V will be mapped to 3.27 V<br>
      <br>
      Derived status:<br>
      <br>
      Sufficient: U &gt; 2.5V<br>
      Low: 2.5V &gt;= U &gt;= 2.3V<br>
      Critical: U &lt; 2.3V<br>
    </td>
  </tr>
</table>

## sta-Variant (Button)

### Scheduled

<table>
  <tr>
    <th>Extends</th>
    <td>Base message</td>
  </tr>
</table>

<table>
  <tr>
    <th>Byte</th>
    <th>Content</th>
    <th>Description</th>
  </tr>
  <tr>
    <td valign="top">0</td>
    <td valign="top">Trigger (u1) [0]</td>
    <td valign="top">0: Scheduled</td>
  </tr>
  <tr>
    <td valign="top">2</td>
    <td valign="top">STM32 MCU Temperature (u8) [6:0]</td>
    <td valign="top">
      Temperature<br>
      value [°C] = (message_value / 255.0) * 165 - 40<br>
      Possible range (raw): 0x000 .. 0xff<br>
      Possible value range (decimal): -40.00 °C .. +125.00 °C<br>
    </td>
  </tr>
</table>

Message Structure:

| Byte | 7      | 6      | 5    | 4     | 3     | 2     | 1    | 0    | Description                              |
|------|--------|--------|------|-------|-------|-------|------|------|------------------------------------------|
| 0    | V_1 =0 | V_0 =1 |      | TXP_2 | TXP_1 | TXP_0 |      | T_0  | V - Version, TXP - TX Power, T - Trigger |
| 1    |        | BV_6   | BV_5 | BV_4  | BV_3  | BV_2  | BV_1 | BV_0 | BV - Battery Voltage                     |
| 2    | TE_7   | TE_6   | TE_5 | TE_4  | TE_3  | TE_2  | TE_1 | TE_0 | TE - MCU Temperature                     |

### Event Triggered

<table>
  <tr>
    <th>Extends</th>
    <td>Base message</td>
  </tr>
</table>

<table>
  <tr>
    <th>Byte</th>
    <th>Content</th>
    <th>Description</th>
  </tr>
  <tr>
    <td valign="top">0</td>
    <td valign="top">Trigger (u1) [0]</td>
    <td valign="top">1: Event</td>
  </tr>
  <tr>
    <td valign="top">0-1</td>
    <td valign="top">Gesture (u2) [7:1]</td>
    <td valign="top">
      0: Single press<br>
      1: Double press<br>
      2: Long press<br>
    </td>
  </tr>
  <tr>
    <td valign="top">2</td>
    <td valign="top">Gesture Count (u8) [7:0]</td>
    <td valign="top">
      The count of the current submitted gesture.<br>
      This will wrap around according to the value range.<br>
      <br>
      Possible value range: 0 .. 255<br>
    </td>
  </tr>
</table>

Message Structure:

| Byte | 7      | 6      | 5    | 4     | 3     | 2     | 1    | 0    | Description                                           |
|------|--------|--------|------|-------|-------|-------|------|------|-------------------------------------------------------|
| 0    | V_1 =0 | V_0 =1 |      | TXP_2 | TXP_1 | TXP_0 | G_0  | T_0  | V - Version, TXP - TX Power, G - Gesture, T - Trigger |
| 1    | G_1    | BV_6   | BV_5 | BV_4  | BV_3  | BV_2  | BV_1 | BV_0 | G - Gesture, BV - Battery Voltage                     |
| 2    | TE_7   | TE_6   | TE_5 | TE_4  | TE_3  | TE_2  | TE_1 | TE_0 | TE - MCU Temperature                                  |
| 3    | GC_7   | GC_6   | GC_5 | GC_4  | GC_3  | GC_2  | GC_1 | GC_0 | GC - Gesture Count                                    |

## stx-Variant (Multi Sensor)

<table>
  <tr>
    <th>Extends</th>
    <td>Base message</td>
  </tr>
</table>

<table>
  <tr>
    <th>Byte</th>
    <th>Content</th>
    <th>Description</th>
  </tr>
  <tr>
    <td valign="top">0</td>
    <td valign="top">Trigger (u5) [4:0]</td>
    <td valign="top">
      Trigger<br>
      0 - Scheduled time interval<br>
      1 - Motion above threshold<br>
      2 - Light intensity above threshold<br>
      3 - Light intensity below threshold<br>
      4 - Temperature above threshold<br>
      5 - Temperature below threshold<br>
      6 - Humidity above threshold<br>
      7 - Humidity below threshold<br>
      8 - Reed switch<br>
    </td>
  </tr>
  <tr>
    <td valign="top">2</td>
    <td valign="top">X-Axis (s8) [7:0]</td>
    <td valign="top">
      X-Axis<br>
      value [m/s^2] = (message_value / 128.0) * (2 * 9.80665)<br>
      Possible range (raw): -0x80 .. 0x7f<br>
      Possible value range (decimal): -19.61 m/s^2 .. 19.41 m/s^2.<br>
    </td>
  </tr>
  <tr>
    <td valign="top">3</td>
    <td valign="top">Y-Axis (s8) [7:0]</td>
    <td valign="top">
      Y-Axis<br>
      value [m/s^2] = (message_value / 128.0) * (2 * 9.80665)<br>
      Possible range (raw): -0x80 .. 0x7f<br>
      Possible value range (decimal): -19.61 m/s^2 .. 19.41 m/s^2.<br>
    </td>
  </tr>
  <tr>
    <td valign="top">4</td>
    <td valign="top">Z-Axis (s8) [7:0]</td>
    <td valign="top">
      Z-Axis<br>
      value [m/s^2] = (message_value / 128.0) * (2 * 9.80665)<br>
      Possible range (raw): -0x80 .. 0x7f<br>
      Possible value range (decimal): -19.61 m/s^2 .. 19.41 m/s^2.<br>
    </td>
  </tr>
  <tr>
    <td valign="top">5</td>
    <td valign="top">X-Axis Reference (s8) [7:0]</td>
    <td valign="top">
      X-Axis<br>
      value [m/s^2] = (message_value / 128.0) * (2 * 9.80665)<br>
      Possible range (raw): -0x80 .. 0x7f<br>
      Possible value range (decimal): -19.61 m/s^2 .. 19.41 m/s^2.<br>
    </td>
  </tr>
  <tr>
    <td valign="top">6</td>
    <td valign="top">Y-Axis Reference (s8) [7:0]</td>
    <td valign="top">
      Y-Axis<br>
      value [m/s^2] = (message_value / 128.0) * (2 * 9.80665)<br>
      Possible range (raw): -0x80 .. 0x7f<br>
      Possible value range (decimal): -19.61 m/s^2 .. 19.41 m/s^2.<br>
    </td>
  </tr>
  <tr>
    <td valign="top">7</td>
    <td valign="top">Z-Axis Reference (s8) [7:0]</td>
    <td valign="top">
      Z-Axis<br>
      value [m/s^2] = (message_value / 128.0) * (2 * 9.80665)<br>
      Possible range (raw): -0x80 .. 0x7f<br>
      Possible value range (decimal): -19.61 m/s^2 .. 19.41 m/s^2.<br>
    </td>
  </tr>
  <tr>
    <td valign="top">8-9</td>
    <td valign="top">HDC2080 Temperature (u9) [7:0]</td>
    <td valign="top">
      Temperature<br>
      value [°C] = (message_value / 512.0) * 165 - 40<br>
      Possible range (raw): 0x000 .. 0x1ff<br>
      Possible value range (decimal): -40.00 °C .. +124.67 °C<br>
    </td>
  </tr>
  <tr>
    <td valign="top">9</td>
    <td valign="top">HDC2080 Humidity (u7) [6:0]</td>
    <td valign="top">
      Relative humidity<br>
      value [%rH] = message_value.<br>
      Possible value range (raw): 0 .. 100<br>
      Possible value range (decimal): 0 %rH .. 100 %rH<br>
    </td>
  </tr>
  <tr>
    <td valign="top">10-11</td>
    <td valign="top">Luminance (u14) [0:5]</td>
    <td valign="top">
      Illuminance<br>
      value [lx] = message_value.<br>
      Possible value range (raw): 0 lx .. 15679 lx<br>
    </td>
  </tr>
</table>

Message Structure:

| Byte | 7      | 6      | 5     | 4     | 3     | 2     | 1     | 0     | Description                              |
|------|--------|--------|-------|-------|-------|-------|-------|-------|------------------------------------------|
| 0    | V_1 =0 | V_0 =1 |       | TXP_2 | TXP_1 | TXP_0 | T_1   | T_0   | V - Version, TXP - TX Power, T - Trigger |
| 1    | T_2    | BV_6   | BV_5  | BV_4  | BV_3  | BV_2  | BV_1  | BV_0  | T - Trigger, BV - Battery Voltage        |
| 2    | X_A_7  | X_A_6  | X_A_5 | X_A_4 | X_A_3 | X_A_2 | X_A_1 | X_A_0 | X_A - X-axis to                          |
| 3    | Y_A_7  | Y_A_6  | Y_A_5 | Y_A_4 | Y_A_3 | Y_A_2 | Y_A_1 | Y_A_0 | Y_A - Y-axis to                          |
| 4    | Z_A_7  | Z_A_6  | Z_A_5 | Z_A_4 | Z_A_3 | Z_A_2 | Z_A_1 | Z_A_0 | Z_A - Z-axis to                          |
| 5    | X_R_7  | X_R_6  | X_R_5 | X_R_4 | X_R_3 | X_R_2 | X_R_1 | X_R_0 | X_R - X-axis from                        |
| 6    | Y_R_7  | Y_R_6  | Y_R_5 | Y_R_4 | Y_R_3 | Y_R_2 | Y_R_1 | Y_R_0 | Y_R - Y-axis from                        |
| 7    | Z_R_7  | Z_R_6  | Z_R_5 | Z_R_4 | Z_R_3 | Z_R_2 | Z_R_1 | Z_R_0 | Z_R - Z-axis from                        |
| 8    | HT_7   | HT_6   | HT_5  | HT_4  | HT_3  | HT_2  | HT_1  | HT_0  | HT - HDC2080 Temperature                 |
| 9    | HT_8   | HH_6   | HH_5  | HH_4  | HH_3  | HH_2  | HH_1  | HH_0  | HH - HDC2080 Humidity                    |
| 10   | IL_7   | IL_6   | IL_5  | IL_4  | IL_3  | IL_2  | IL_1  | IL_0  | IL - Illuminance                         |
| 11   | T_4    | T_3    | IL_13 | IL_12 | IL_11 | IL_10 | IL_9  | IL_8  | T - Trigger                              |

## ste-Variant (Environment Sensor)

<table>
  <tr>
    <th>Extends</th>
    <td>Base message</td>
  </tr>
</table>

<table>
  <tr>
    <th>Byte</th>
    <th>Content</th>
    <th>Description</th>
  </tr>
  <tr>
    <td valign="top">0</td>
    <td valign="top">BSEC Accuracy (u2) [0:1]</td>
    <td valign="top">
      IAQ, VOC, CO2 Accuracy<br>
      0: No Reading (stabilization/run-in ongoing)<br>
      1: Low Accuracy<br>
      2: Medium Accuracy<br>
      3: High Accuracy<br>
      Possible range (raw): 0x0 .. 0x3<br>
    </td>
  </tr>
  <tr>
    <td valign="top">2-3</td>
    <td valign="top">BME680 Temperature (u9) [0:7]</td>
    <td valign="top">
      Temperature<br>
      value [°C] = (message_value / 511.0) * 125 - 40<br>
      Possible range (raw): 0x000 .. 0x1ff<br>
      Possible value range (decimal): -40.00 °C .. +85.00 °C<br>
    </td>
  </tr>
  <tr>
    <td valign="top">3</td>
    <td valign="top">BME680 Humidity (u7)</td>
    <td valign="top">
      Relative humidity<br>
      value [%rH] = message_value<br>
      Possible value range (raw): 0 .. 100<br>
      Possible value range (decimal): 0 %rH .. 100 %rH<br>
    </td>
  </tr>
  <tr>
    <td valign="top">4-5</td>
    <td valign="top">BME680 Pressure (u16) [0:7]</td>
    <td valign="top">
      Pressure<br>
      1 hPa (hectopascal) == 100 Pa (pascal)<br>
      value [Pa] = message_value / 65535 * 80000 + 30000<br>
      Possible range (raw): 0x0000 .. 0xffff<br>
      Possible value range (decimal): 300 hPa .. 1100 hPa<br>
    </td>
  </tr>
  <tr>
    <td valign="top">6,1</td>
    <td valign="top">BSEC IAQ Indoor Air Quality (u9) [7:7]</td>
    <td valign="top">
      Indoor Air Quality/Air Quality Index<br>
      0: Clean air<br>
      25: Typical good air<br>
      250: Typical polluted air<br>
      500: Heavily polluted air<br>
      value [index] = message_value<br>
      Possible range (raw): 0x000 .. 0x1f4<br>
      Possible value range (decimal): 0 .. 500<br>
    </td>
  </tr>
  <tr>
    <td valign="top">7,9,0</td>
    <td valign="top">BSEC bVOC-e Volatile Organic Compound (f15)</td>
    <td valign="top">
      breath Volatile Organic Compound Eqivalent<br>
      custom float type: base-8 3-bit exponent, 10-bit fractional mantissa<br>
      mantissa = message_value & 0x03ff<br>
      exponent = message_value & 0x1c00<br>
      if(exponent == 0)<br>
        float = mantissa / 1024.0<br>
      else<br>
	floor = 8^(exponent-1)<br>
	ceil  = 8^(exponent)<br>
	range = ceil - floor<br>
        float = mantissa / 1024.0 * range + floor<br>
      <br>
      value [ppm] = float<br>
      Possible value range (raw): 0x0000 .. 0x7fff<br>
      Possible value range (decimal): 0.000 .. 2095360 ppm<br>
    </td>
  </tr>
  <tr>
    <td valign="top">8,9,0</td>
    <td valign="top">BME680 CO2-e (u15)</td>
    <td valign="top">
      CO2 Equivalent<br>
      value [ppm] = message value<br>
      Possible range (raw): 0x000 .. 0x7fff<br>
      Possible value range (decimal): 0 ppm .. 32767 ppm<br>
    </td>
  </tr>
</table>

Message Structure:

| Byte | 7      | 6      | 5      | 4      | 3      | 2      | 1     | 0     | Description                                                      |
|------|--------|--------|--------|--------|--------|--------|-------|-------|------------------------------------------------------------------|
| 0    | V_1 =0 | V_0 =1 |        | TXP_2  | TXP_1  | TXP_0  |       |       | V - Version, TXP - TX Power                                      |
| 1    |        | BV_6   | BV_5   | BV_4   | BV_3   | BV_2   | BV_1  | BV_0  | BV - Battery Voltage                                             |
| 2    | T_7    | T_6    | T_5    | T_4    | T_3    | T_2    | T_1   | T_0   | T - BME680 Temperature                                           |
| 3    | T_8    | H_6    | H_5    | H_4    | H_3    | H_2    | H_1   | H_0   | H - BME680 Humidity                                              |
| 4    | P_7    | P_6    | P_5    | P_4    | P_3    | P_2    | P_1   | P_0   | P - BME680 Pressure                                              |
| 5    | P_15   | P_14   | P_13   | P_12   | P_11   | P_10   | P_9   | P_8   |                                                                  |
| 6    | AQI_7  | AQI_6  | AQI_5  | AQI_4  | AQI_3  | AQI_2  | AQI_1 | AQI_0 | AQI - BSEC IAQ (Air Quality Index)                               |
| 7    | VOC_7  | VOC_6  | VOC_5  | VOC_4  | VOC_3  | VOC_2  | VOC_1 | VOC_0 | VOC - BSEC b-VOC-e (Breath Volatile Organic Compound Equivalent) |
| 8    | CO2_7  | CO2_6  | CO2_5  | CO2_4  | CO2_3  | CO2_2  | CO2_1 | CO2_0 | CO2 - BSEC CO2-e (CO2 Equivalent)                                |
| 9    | CO2_11 | CO2_10 | CO2_9  | CO2_8  | VOC_11 | VOC_10 | VOC_9 | VOC_8 | CO2, VOC                                                         |
| 10   | AQI_8  |        | VOC_15 | CO2_14 | CO2_13 | CO2_12 | IA_1  | IA_0  | IA - BSEC Accuracy                                               |
