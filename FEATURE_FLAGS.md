# Feature Flags

All the *Feature Flags* are defined in the file `main.h`, appropriate flags are enabled and unwanted flags are disabled as per the variant and requirement.

| No |           Flag          | Description                                                                                                                   |
|:--:|:-----------------------:|:------------------------------------------------------------------------------------------------------------------------------|
|  1 |           STA           | action variant with a tactile switch                                                                                          |
|  2 |           STX           | multisensor variant with five sensor measurements                                                                             |
|  3 |           STE           | environment sensor with Bosch BME680                                                                                          |
|  4 |           NFC           | Enable/Disable NFC                                                                                                            |
|  5 |         LORAWAN         | Enable/Disable LoRaWAN                                                                                                        |
|  6 |      ACTION_SENSOR      | Enable/Disable Button                                                                                                         |
|  7 |          BME680         | Enable/Disable Temperature, Pressure and Humidity sensor                                                                      |
|  8 |          BMA400         | Enable/Disable Accelerometer sensor                                                                                           |
|  9 |         SFH7776         | Enable/Disable Light sensor                                                                                                   |
| 10 |         HDC2080         | Enable/Disable Temperature, Humidity sensor with interrupt based on temperature and humidity                                  |
| 11 | SIMPLE_TWO_GESTURE_MODE | Replaces 3 gesture mode with 2 gesture mode, disabling double tap, thus removing gesture latency. LED patterns remapped.      |
| 12 |     ST25DV_PASSWORD     | NB: Stored in FLASH! Meaning a factory reset defaults to this password. You likely want to modify password in EEPROM instead. |
