/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __NFCMSG_H
#define __NFCMSG_H
#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Exported types ------------------------------------------------------------*/
/* Exported constants --------------------------------------------------------*/
/* Protobuf format primitives */
#define PB_TAGTYPE_VARINT   0
#define PB_TAGTYPE_FIXED64  1
#define PB_TAGTYPE_BYTES    2
#define PB_TAGTYPE_FIXED32  5

/* Reference: MESSAGE_FORMAT_NFC.md
 * Version: 2022-02-22T12:00Z
 */

/* Message format identifiers
 * TX - MCU to Host only
 * RX - Host to MCU only
 * BX - Either way
 * Convention is to reflect the protobuf field name exactly, but uppercased.
 */

#define PBMSGID_DEVICE_CONFIGURATION  0
#define PBMSGID_DEVICE_SENSORS        1

/* message DeviceConfiguration
 * --------------------------- */
#define PBMSG_TX_DEVICE_PART_NUMBER_ID                    1
#define PBMSG_TX_DEVICE_PART_NUMBER_TYPE                  PB_TAGTYPE_VARINT
#define PBMSG_TX_DEVICE_PART_NUMBER                       ((uint32_t)PBMSG_TX_DEVICE_PART_NUMBER_ID << 3 | PBMSG_TX_DEVICE_PART_NUMBER_TYPE)
#define PBMSG_TX_DEVICE_FW_VERSION_ID                     2
#define PBMSG_TX_DEVICE_FW_VERSION_TYPE                   PB_TAGTYPE_VARINT
#define PBMSG_TX_DEVICE_FW_VERSION                        ((uint32_t)PBMSG_TX_DEVICE_FW_VERSION_ID << 3 | PBMSG_TX_DEVICE_FW_VERSION_TYPE)
#define PBMSG_TX_SECURE_ELEMENT_EMPTY_SLOTS_ID            3
#define PBMSG_TX_SECURE_ELEMENT_EMPTY_SLOTS_TYPE          PB_TAGTYPE_VARINT
#define PBMSG_TX_SECURE_ELEMENT_EMPTY_SLOTS               ((uint32_t)PBMSG_TX_SECURE_ELEMENT_EMPTY_SLOTS_ID << 3 | PBMSG_TX_SECURE_ELEMENT_EMPTY_SLOTS_TYPE)
#define PBMSG_BX_SECURE_ELEMENT_USE_ID                    4
#define PBMSG_BX_SECURE_ELEMENT_USE_TYPE                  PB_TAGTYPE_VARINT
#define PBMSG_BX_SECURE_ELEMENT_USE                       ((uint32_t)PBMSG_BX_SECURE_ELEMENT_USE_ID << 3 | PBMSG_BX_SECURE_ELEMENT_USE_TYPE)

#define PBMSG_BX_LORA_OTAA_ID                             5
#define PBMSG_BX_LORA_OTAA_TYPE                           PB_TAGTYPE_VARINT
#define PBMSG_BX_LORA_OTAA                                ((uint32_t)PBMSG_BX_LORA_OTAA_ID << 3 | PBMSG_BX_LORA_OTAA_TYPE)
#define PBMSG_BX_LORA_DEV_EUI_ID                          6
#define PBMSG_BX_LORA_DEV_EUI_TYPE                        PB_TAGTYPE_FIXED64
#define PBMSG_BX_LORA_DEV_EUI                             ((uint32_t)PBMSG_BX_LORA_DEV_EUI_ID << 3 | PBMSG_BX_LORA_DEV_EUI_TYPE)
#define PBMSG_BX_LORA_APP_EUI_ID                          7
#define PBMSG_BX_LORA_APP_EUI_TYPE                        PB_TAGTYPE_FIXED64
#define PBMSG_BX_LORA_APP_EUI                             ((uint32_t)PBMSG_BX_LORA_APP_EUI_ID << 3 | PBMSG_BX_LORA_APP_EUI_TYPE)
#define PBMSG_BX_LORA_APP_KEY_ID                          8
#define PBMSG_BX_LORA_APP_KEY_SIZE                        ((size_t)16)
#define PBMSG_BX_LORA_APP_KEY_TYPE                        PB_TAGTYPE_BYTES
#define PBMSG_BX_LORA_APP_KEY                             ((uint32_t)PBMSG_BX_LORA_APP_KEY_ID << 3 | PBMSG_BX_LORA_APP_KEY_TYPE)
#define PBMSG_BX_LORA_DEV_ADDR_ID                         9
#define PBMSG_BX_LORA_DEV_ADDR_TYPE                       PB_TAGTYPE_FIXED32
#define PBMSG_BX_LORA_DEV_ADDR                            ((uint32_t)PBMSG_BX_LORA_DEV_ADDR_ID << 3 | PBMSG_BX_LORA_DEV_ADDR_TYPE)
#define PBMSG_BX_LORA_MAC_NET_SESSION_KEY_ID              10
#define PBMSG_BX_LORA_MAC_NET_SESSION_KEY_SIZE            ((size_t)16)
#define PBMSG_BX_LORA_MAC_NET_SESSION_KEY_TYPE            PB_TAGTYPE_BYTES
#define PBMSG_BX_LORA_MAC_NET_SESSION_KEY                 ((uint32_t)PBMSG_BX_LORA_MAC_NET_SESSION_KEY_ID << 3 | PBMSG_BX_LORA_MAC_NET_SESSION_KEY_TYPE)
#define PBMSG_BX_LORA_MAC_APP_SESSION_KEY_ID              11
#define PBMSG_BX_LORA_MAC_APP_SESSION_KEY_SIZE            ((size_t)16)
#define PBMSG_BX_LORA_MAC_APP_SESSION_KEY_TYPE            PB_TAGTYPE_BYTES
#define PBMSG_BX_LORA_MAC_APP_SESSION_KEY                 ((uint32_t)PBMSG_BX_LORA_MAC_APP_SESSION_KEY_ID << 3 | PBMSG_BX_LORA_MAC_APP_SESSION_KEY_TYPE)
#define PBMSG_TX_LORA_JOINED_ID                           12
#define PBMSG_TX_LORA_JOINED_TYPE                         PB_TAGTYPE_VARINT
#define PBMSG_TX_LORA_JOINED                              ((uint32_t)PBMSG_TX_LORA_JOINED_ID << 3 | PBMSG_TX_LORA_JOINED_TYPE)
#define PBMSG_TX_LORA_FP_ID                               13
#define PBMSG_TX_LORA_FP_TYPE                             PB_TAGTYPE_VARINT
#define PBMSG_TX_LORA_FP                                  ((uint32_t)PBMSG_TX_LORA_FP_ID << 3 | PBMSG_TX_LORA_FP_TYPE)
#define PBMSG_BX_LORA_PORT_ID                             14
#define PBMSG_BX_LORA_PORT_TYPE                           PB_TAGTYPE_VARINT
#define PBMSG_BX_LORA_PORT                                ((uint32_t)PBMSG_BX_LORA_PORT_ID << 3 | PBMSG_BX_LORA_PORT_TYPE)
#define PBMSG_TX_LORA_TXP_ID                              15
#define PBMSG_TX_LORA_TXP_TYPE                            PB_TAGTYPE_VARINT
#define PBMSG_TX_LORA_TXP                                 ((uint32_t)PBMSG_TX_LORA_TXP_ID << 3 | PBMSG_TX_LORA_TXP_TYPE)
#define PBMSG_TX_LORA_SF_ID                               16
#define PBMSG_TX_LORA_SF_TYPE                             PB_TAGTYPE_VARINT
#define PBMSG_TX_LORA_SF                                  ((uint32_t)PBMSG_TX_LORA_SF_ID << 3 | PBMSG_TX_LORA_SF_TYPE)
#define PBMSG_TX_LORA_BW_ID                               17
#define PBMSG_TX_LORA_BW_TYPE                             PB_TAGTYPE_VARINT
#define PBMSG_TX_LORA_BW                                  ((uint32_t)PBMSG_TX_LORA_BW_ID << 3 | PBMSG_TX_LORA_BW_TYPE)
#define PBMSG_TX_LORA_CONFIRMED_MESSAGES_ID               18
#define PBMSG_TX_LORA_CONFIRMED_MESSAGES_TYPE             PB_TAGTYPE_VARINT
#define PBMSG_TX_LORA_CONFIRMED_MESSAGES                  ((uint32_t)PBMSG_TX_LORA_CONFIRMED_MESSAGES_ID << 3 | PBMSG_TX_LORA_CONFIRMED_MESSAGES_TYPE)
#define PBMSG_TX_LORA_ADAPTIVE_DATA_RATE_ID               19
#define PBMSG_TX_LORA_ADAPTIVE_DATA_RATE_TYPE             PB_TAGTYPE_VARINT
#define PBMSG_TX_LORA_ADAPTIVE_DATA_RATE                  ((uint32_t)PBMSG_TX_LORA_ADAPTIVE_DATA_RATE_ID << 3 | PBMSG_TX_LORA_ADAPTIVE_DATA_RATE_TYPE)
#define PBMSG_TX_LORA_RESPECT_DUTY_CYCLE_ID               20
#define PBMSG_TX_LORA_RESPECT_DUTY_CYCLE_TYPE             PB_TAGTYPE_VARINT
#define PBMSG_TX_LORA_RESPECT_DUTY_CYCLE                  ((uint32_t)PBMSG_TX_LORA_RESPECT_DUTY_CYCLE_ID << 3 | PBMSG_TX_LORA_RESPECT_DUTY_CYCLE_TYPE)

#define PBMSG_BX_SENSOR_TIMEBASE_ID                       21
#define PBMSG_BX_SENSOR_TIMEBASE_TYPE                     PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_TIMEBASE                          ((uint32_t)PBMSG_BX_SENSOR_TIMEBASE_ID << 3 | PBMSG_BX_SENSOR_TIMEBASE_TYPE)
#define PBMSG_BX_SENSOR_SEND_TRIGGER_ID                   22
#define PBMSG_BX_SENSOR_SEND_TRIGGER_TYPE                 PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_SEND_TRIGGER                      ((uint32_t)PBMSG_BX_SENSOR_SEND_TRIGGER_ID << 3 | PBMSG_BX_SENSOR_SEND_TRIGGER_TYPE)
#define PBMSG_BX_SENSOR_SEND_STRATEGY_ID                  23
#define PBMSG_BX_SENSOR_SEND_STRATEGY_TYPE                PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_SEND_STRATEGY                     ((uint32_t)PBMSG_BX_SENSOR_SEND_STRATEGY_ID << 3 | PBMSG_BX_SENSOR_SEND_STRATEGY_TYPE)
#define PBMSG_BX_SENSOR_HUMIDITY_UPPER_THRESHOLD_ID       24
#define PBMSG_BX_SENSOR_HUMIDITY_UPPER_THRESHOLD_TYPE     PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_HUMIDITY_UPPER_THRESHOLD          ((uint32_t)PBMSG_BX_SENSOR_HUMIDITY_UPPER_THRESHOLD_ID << 3 | PBMSG_BX_SENSOR_HUMIDITY_UPPER_THRESHOLD_TYPE)
#define PBMSG_BX_SENSOR_HUMIDITY_LOWER_THRESHOLD_ID       25
#define PBMSG_BX_SENSOR_HUMIDITY_LOWER_THRESHOLD_TYPE     PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_HUMIDITY_LOWER_THRESHOLD          ((uint32_t)PBMSG_BX_SENSOR_HUMIDITY_LOWER_THRESHOLD_ID << 3 | PBMSG_BX_SENSOR_HUMIDITY_LOWER_THRESHOLD_TYPE)
#define PBMSG_BX_SENSOR_TEMPERATURE_UPPER_THRESHOLD_ID    26
#define PBMSG_BX_SENSOR_TEMPERATURE_UPPER_THRESHOLD_TYPE  PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_TEMPERATURE_UPPER_THRESHOLD       ((uint32_t)PBMSG_BX_SENSOR_TEMPERATURE_UPPER_THRESHOLD_ID << 3 | PBMSG_BX_SENSOR_TEMPERATURE_UPPER_THRESHOLD_TYPE)
#define PBMSG_BX_SENSOR_TEMPERATURE_LOWER_THRESHOLD_ID    27
#define PBMSG_BX_SENSOR_TEMPERATURE_LOWER_THRESHOLD_TYPE  PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_TEMPERATURE_LOWER_THRESHOLD       ((uint32_t)PBMSG_BX_SENSOR_TEMPERATURE_LOWER_THRESHOLD_ID << 3 | PBMSG_BX_SENSOR_TEMPERATURE_LOWER_THRESHOLD_TYPE)
#define PBMSG_BX_SENSOR_LUMINANCE_UPPER_THRESHOLD_ID      28
#define PBMSG_BX_SENSOR_LUMINANCE_UPPER_THRESHOLD_TYPE    PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_LUMINANCE_UPPER_THRESHOLD         ((uint32_t)PBMSG_BX_SENSOR_LUMINANCE_UPPER_THRESHOLD_ID << 3 | PBMSG_BX_SENSOR_LUMINANCE_UPPER_THRESHOLD_TYPE)
#define PBMSG_BX_SENSOR_LUMINANCE_LOWER_THRESHOLD_ID      29
#define PBMSG_BX_SENSOR_LUMINANCE_LOWER_THRESHOLD_TYPE    PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_LUMINANCE_LOWER_THRESHOLD         ((uint32_t)PBMSG_BX_SENSOR_LUMINANCE_LOWER_THRESHOLD_ID << 3 | PBMSG_BX_SENSOR_LUMINANCE_LOWER_THRESHOLD_TYPE)
#define PBMSG_BX_SENSOR_AXIS_THRESHOLD_ID                 30
#define PBMSG_BX_SENSOR_AXIS_THRESHOLD_TYPE               PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_AXIS_THRESHOLD                    ((uint32_t)PBMSG_BX_SENSOR_AXIS_THRESHOLD_ID << 3 | PBMSG_BX_SENSOR_AXIS_THRESHOLD_TYPE)
#define PBMSG_BX_SENSOR_AXIS_CONFIGURE_ID                 31
#define PBMSG_BX_SENSOR_AXIS_CONFIGURE_TYPE               PB_TAGTYPE_VARINT
#define PBMSG_BX_SENSOR_AXIS_CONFIGURE                    ((uint32_t)PBMSG_BX_SENSOR_AXIS_CONFIGURE_ID << 3 | PBMSG_BX_SENSOR_AXIS_CONFIGURE_TYPE)

#define PBEEPROM_BUTTON_SINGLE_COUNT_ID                   2047
#define PBEEPROM_BUTTON_SINGLE_COUNT_TYPE                 PB_TAGTYPE_VARINT
#define PBEEPROM_BUTTON_SINGLE_COUNT                      ((uint32_t)PBEEPROM_BUTTON_SINGLE_COUNT_ID << 3 | PBEEPROM_BUTTON_SINGLE_COUNT_TYPE)
#define PBEEPROM_BUTTON_DOUBLE_COUNT_ID                   2046
#define PBEEPROM_BUTTON_DOUBLE_COUNT_TYPE                 PB_TAGTYPE_VARINT
#define PBEEPROM_BUTTON_DOUBLE_COUNT                      ((uint32_t)PBEEPROM_BUTTON_DOUBLE_COUNT_ID << 3 | PBEEPROM_BUTTON_DOUBLE_COUNT_TYPE)
#define PBEEPROM_BUTTON_LONG_COUNT_ID                     2045
#define PBEEPROM_BUTTON_LONG_COUNT_TYPE                   PB_TAGTYPE_VARINT
#define PBEEPROM_BUTTON_LONG_COUNT                        ((uint32_t)PBEEPROM_BUTTON_LONG_COUNT_ID << 3 | PBEEPROM_BUTTON_LONG_COUNT_TYPE)

#define PBENUM_PARTNR_STA  ((uint64_t)1)  // Gesture Button
#define PBENUM_PARTNR_STX  ((uint64_t)2)  // Multi Sensor
#define PBENUM_PARTNR_STE  ((uint64_t)3)  // Environment Sensor


#define PBENUM_FP_EU868    ((uint64_t)1)  // 868.1 868.3 868.5 867.1 867.3 867.5 867.7 867.9 kHz
#define PBENUM_FP_US915    ((uint64_t)2)

#define PBENUM_BW_125      ((uint64_t)1)  // 125 kHz
#define PBENUM_BW_250      ((uint64_t)2)  // 250 kHz
#define PBENUM_BW_500      ((uint64_t)3)  // 500 kHz

/* message DeviceSensors
 * --------------------- */
#define PBSMSG_TX_DEVICE_PART_NUMBER_ID             1
#define PBSMSG_TX_DEVICE_PART_NUMBER_TYPE           PB_TAGTYPE_VARINT
#define PBSMSG_TX_DEVICE_PART_NUMBER                ((uint32_t)PBSMSG_TX_DEVICE_PART_NUMBER_ID << 3 | PBSMSG_TX_DEVICE_PART_NUMBER_TYPE)
#define PBSMSG_TX_DEVICE_BATTERY_VOLTAGE_ID         2
#define PBSMSG_TX_DEVICE_BATTERY_VOLTAGE_TYPE       PB_TAGTYPE_VARINT
#define PBSMSG_TX_DEVICE_BATTERY_VOLTAGE            ((uint32_t)PBSMSG_TX_DEVICE_BATTERY_VOLTAGE_ID << 3 | PBSMSG_TX_DEVICE_BATTERY_VOLTAGE_TYPE)

#define PBSMSG_TX_SENSOR_TEMPERATURE_ID             3
#define PBSMSG_TX_SENSOR_TEMPERATURE_TYPE           PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_TEMPERATURE                ((uint32_t)PBSMSG_TX_SENSOR_TEMPERATURE_ID << 3 | PBSMSG_TX_SENSOR_TEMPERATURE_TYPE)
#define PBSMSG_TX_SENSOR_HUMIDITY_ID                4
#define PBSMSG_TX_SENSOR_HUMIDITY_TYPE              PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_HUMIDITY                   ((uint32_t)PBSMSG_TX_SENSOR_HUMIDITY_ID << 3 | PBSMSG_TX_SENSOR_HUMIDITY_TYPE)
#define PBSMSG_TX_SENSOR_PRESSURE_ID                5
#define PBSMSG_TX_SENSOR_PRESSURE_TYPE              PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_PRESSURE                   ((uint32_t)PBSMSG_TX_SENSOR_PRESSURE_ID << 3 | PBSMSG_TX_SENSOR_PRESSURE_TYPE)
#define PBSMSG_TX_SENSOR_AIR_QUALITY_ID             6
#define PBSMSG_TX_SENSOR_AIR_QUALITY_TYPE           PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_AIR_QUALITY                ((uint32_t)PBSMSG_TX_SENSOR_AIR_QUALITY_ID << 3 | PBSMSG_TX_SENSOR_AIR_QUALITY_TYPE)
#define PBSMSG_TX_SENSOR_LUMINANCE_ID               7
#define PBSMSG_TX_SENSOR_LUMINANCE_TYPE             PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_LUMINANCE                  ((uint32_t)PBSMSG_TX_SENSOR_LUMINANCE_ID << 3 | PBSMSG_TX_SENSOR_LUMINANCE_TYPE)
#define PBSMSG_TX_SENSOR_AIR_VOC_PPM_ID             14
#define PBSMSG_TX_SENSOR_AIR_VOC_PPM_TYPE           PB_TAGTYPE_FIXED32
#define PBSMSG_TX_SENSOR_AIR_VOC_PPM                ((uint32_t)PBSMSG_TX_SENSOR_AIR_VOC_PPM_ID << 3 | PBSMSG_TX_SENSOR_AIR_VOC_PPM_TYPE)
#define PBSMSG_TX_SENSOR_AIR_CO2_PPM_ID             15
#define PBSMSG_TX_SENSOR_AIR_CO2_PPM_TYPE           PB_TAGTYPE_FIXED32
#define PBSMSG_TX_SENSOR_AIR_CO2_PPM                ((uint32_t)PBSMSG_TX_SENSOR_AIR_CO2_PPM_ID << 3 | PBSMSG_TX_SENSOR_AIR_CO2_PPM_TYPE)
#define PBSMSG_TX_SENSOR_AIR_ACCURACY_ID            16
#define PBSMSG_TX_SENSOR_AIR_ACCURACY_TYPE          PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_AIR_ACCURACY               ((uint32_t)PBSMSG_TX_SENSOR_AIR_ACCURACY_ID << 3 | PBSMSG_TX_SENSOR_AIR_ACCURACY_TYPE)

#define PBSMSG_TX_SENSOR_X_AXIS_ID                  8
#define PBSMSG_TX_SENSOR_X_AXIS_TYPE                PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_X_AXIS                     ((uint32_t)PBSMSG_TX_SENSOR_X_AXIS_ID << 3 | PBSMSG_TX_SENSOR_X_AXIS_TYPE)
#define PBSMSG_TX_SENSOR_Y_AXIS_ID                  9
#define PBSMSG_TX_SENSOR_Y_AXIS_TYPE                PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_Y_AXIS                     ((uint32_t)PBSMSG_TX_SENSOR_Y_AXIS_ID << 3 | PBSMSG_TX_SENSOR_Y_AXIS_TYPE)
#define PBSMSG_TX_SENSOR_Z_AXIS_ID                  10
#define PBSMSG_TX_SENSOR_Z_AXIS_TYPE                PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_Z_AXIS                     ((uint32_t)PBSMSG_TX_SENSOR_Z_AXIS_ID << 3 | PBSMSG_TX_SENSOR_Z_AXIS_TYPE)

#define PBSMSG_TX_SENSOR_GESTURE_SINGLE_COUNT_ID    11
#define PBSMSG_TX_SENSOR_GESTURE_SINGLE_COUNT_TYPE  PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_GESTURE_SINGLE_COUNT       ((uint32_t)PBSMSG_TX_SENSOR_GESTURE_SINGLE_COUNT_ID << 3 | PBSMSG_TX_SENSOR_GESTURE_SINGLE_COUNT_TYPE)
#define PBSMSG_TX_SENSOR_GESTURE_DOUBLE_COUNT_ID    12
#define PBSMSG_TX_SENSOR_GESTURE_DOUBLE_COUNT_TYPE  PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_GESTURE_DOUBLE_COUNT       ((uint32_t)PBSMSG_TX_SENSOR_GESTURE_DOUBLE_COUNT_ID << 3 | PBSMSG_TX_SENSOR_GESTURE_DOUBLE_COUNT_TYPE)
#define PBSMSG_TX_SENSOR_GESTURE_LONG_COUNT_ID      13
#define PBSMSG_TX_SENSOR_GESTURE_LONG_COUNT_TYPE    PB_TAGTYPE_VARINT
#define PBSMSG_TX_SENSOR_GESTURE_LONG_COUNT         ((uint32_t)PBSMSG_TX_SENSOR_GESTURE_LONG_COUNT_ID << 3 | PBSMSG_TX_SENSOR_GESTURE_LONG_COUNT_TYPE)

/* External variables --------------------------------------------------------*/
/* Exported macros -----------------------------------------------------------*/
#define PBEncodeMsgField(msg, len, pos, ...)                                   \
  (PBEncodeField(                                                              \
    pos < len ? msg + pos : NULL,                                              \
    pos < len ? len - pos : 0, __VA_ARGS__))

/* Exported functions ------------------------------------------------------- */
size_t PBEncodeMsg_DeviceConfiguration(uint8_t *msg, size_t len, bool pw_valid);
size_t PBEncodeMsg_DeviceSensors(uint8_t *msg, size_t len, bool pw_valid);
uint8_t PBDecodeVarint(const uint8_t* varint, uint8_t maxbits, void* value);
uint64_t PBEncodeSInt(int64_t val);
int64_t PBDecodeSInt(uint64_t val);
size_t PBEncodeField(uint8_t * restrict out, size_t len, uint32_t key, ...);
void PBDecodeMsg(const uint8_t *msg, uint8_t len);
uint64_t u64(uint8_t b[static 8]);
void b64(uint8_t b[static 8], uint64_t v);


#ifdef __cplusplus
}
#endif
#endif /* __NFCMSG_H */
