#include "eeprom.h"
#include "protobuf.h"
#include "LoRaMac-node/boards/utilities.h"  // Crc32*
#include "LoRaMac-node/boards/board.h"      // BoardGetUniqueId
#include "hardware.h"          // EEPROM_APP
#include <string.h>            // memcpy

struct DeviceConfig DevCfg = {
  /* LoRaWAN Defaults */
  .isOtaa = true,
  .devEui = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
  .appEui = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
  .appKey = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
  .region = LORAMAC_REGION_EU868, // You must adjust .sf .bw .txPower respectively!
  .sf = 12,             // EU868_DEFAULT_DATARATE
  .bw = PBENUM_BW_125,  // EU868_DEFAULT_DATARATE
  .txPower = 16,        // EU868_DEFAULT_TX_POWER
  .txPort = 1,
  .confirmedMsgs = true,
  .adaptiveDatarate = true,
  .dutyCycle = true,

  /* Sensor Defaults */
  .sendInterval = 86400, /* 24 hours */
  .sendTrigger = SEND_TRIGGER_ALWAYS,
  .sendStrategy = SEND_STRATEGY_PERIODIC,

#if defined(STX)
  /* BMA400 Defaults (Accelerometer) */
  .useSensor.bma400 = false,

  /* HDC2080 Defaults (Temperature/Humidity) */
  .useSensor.hdc2080 = false,

  /* SFH7776 Defaults (Luminance) */
  .useSensor.sfh7776 = false,

#endif
};

static void DebugArr(const void *buf, size_t len) {
  for(size_t i = 0; i < len; i++) {
    DEBUG_PRINTF("%02x ", ((const uint8_t *)buf)[i]);
  }
}

static void DebugLE(const uint8_t *buf, uint16_t len) {
  if(len) do {
    DBG_PRINTF("%02x", buf[--len]);
  } while(len);
}

void EEPROM_Load(void) {
  uint32_t crc = ((uint32_t*)EEPROM_APP)[0];
  uint32_t len = ((uint32_t*)EEPROM_APP)[1];
  uint8_t *msg = (uint8_t*)EEPROM_APP + 8;
  uint8_t pos = 0;
  const char *debug_msg = "\n";
  uint8_t debug_fieldpos = 0;

  if(len > EEPROM_APP_END - EEPROM_APP - 8 || len < 10 || *msg || crc != EEPROM_CRC(msg, len)) {
    DEBUG_MSG("EEPROM ERR Missing. Saving defaults...\n");

    // Set the MCU's chip ID as DevEUI
    // TODO: Insert in #PRODUCTION. Helps developing multiple devices under same DevEUI.
    BoardGetUniqueId(DevCfg.devEui);

    EEPROM_Save();
  }

  crc = ((uint32_t*)EEPROM_APP)[0];
  len = ((uint32_t*)EEPROM_APP)[1];

  pos++;

  /* Deserialize EEPROM protobuf into DevCfg */
  /* Each iteration is 1 key-value field */
  while(pos != len) {
    /*
     * Decode Key
     */
    uint8_t tagtype = msg[pos] & 0x7;
    uint32_t tagnr = 0;
    uint8_t val_rawbytes;
    uint64_t val_int = 0;

    debug_fieldpos = pos;

    /* Continuation bit set, tag could be 2 to 5 bytes, values [16,2^29-1] */
    if(msg[pos] & 0x80) {
      /* Reuse code to decode subsequent 1 to 4 bytes. */
      uint8_t tagnr_bitlimit = len - pos < 5 ? (len - pos) * 7 : 25;
      uint8_t tagnr_bytes = PBDecodeVarint(msg + pos + 1, tagnr_bitlimit, &tagnr);

      /* Prevent varint spill, i.e. continuation bit set in all *accessed* bytes */
      if(!tagnr_bytes) {
        debug_msg = ", Out-of-bounds varint tagnr\n";
        Breakpoint();
        goto err;
      }

      /* Merge value of 1st byte with value of subsequent 1 to 4 bytes. */
      tagnr <<= 4;
      tagnr |= (msg[pos] & 0x78) >> 3;
      pos += tagnr_bytes + 1;

    /* Continuation bit clear, tag is 1 byte, values [1,15] */
    } else {
      tagnr = (msg[pos] & 0x78) >> 3;
      pos += 1;
    }

    /* Key being zero is ill-formed */
    if(!tagnr) {
      debug_msg = ", Ill-formed tagnr\n";
      Breakpoint();
      goto err;
    }

    /*
     * Decode Value
     */

    /* Key without value is ill-formed. */
    if(!(len - pos)) {
      debug_msg = ", Out-of-bounds tag w/o value\n";
      goto err;
    }

    /* Need size in case to skip unknown field. */
    switch(tagtype) {
    case PB_TAGTYPE_VARINT: {
      uint8_t varint_bitlimit = len - pos < 10 ? (len - pos) * 7 : 64;
      val_rawbytes = PBDecodeVarint(msg + pos, varint_bitlimit, &val_int);
      break;
    }
    case PB_TAGTYPE_FIXED64: {
      val_rawbytes = 8;
      memcpy(&val_int, msg + pos, val_rawbytes);
      break;
    }
    case PB_TAGTYPE_BYTES: {
      /* Bytes type is varint+rawbytes, where varint denotes rawbytes length */
      uint8_t varint_bitlimit = len - pos == 1 ? 7 : 8;
      val_rawbytes = PBDecodeVarint(msg + pos, varint_bitlimit, &val_int);

      /* Prevent varint spill */
      if(!val_rawbytes) break;

      pos += val_rawbytes;

      /* Prevent bytes spill */
      val_rawbytes = val_int > 250 || val_int > (uint8_t)(len - pos)
        ? 0 : val_int;

      break;
    }
    case PB_TAGTYPE_FIXED32: {
      val_rawbytes = 4;
      memcpy(&val_int, msg + pos, val_rawbytes);
      break;
    }
    default: {
      debug_msg = ", Ill-formed tagtype\n";
      Breakpoint();
      goto err;
      break;
    }
    }

    /* Value was too large or ill-formed */
    if(!val_rawbytes) {
      debug_msg = ", Ill-formed value\n";
      Breakpoint();
      goto err;
    }

    /*
     * Read Value
     */
    if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_OTAA) {
      DevCfg.isOtaa = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_DEV_EUI) {
      b64(DevCfg.devEui, val_int);
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_APP_EUI) {
      b64(DevCfg.appEui, val_int);
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_APP_KEY && val_rawbytes == sizeof DevCfg.appKey) {
      memcpy(DevCfg.appKey, msg + pos, val_rawbytes);
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_DEV_ADDR) {
      DevCfg.devAddr = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_MAC_NET_SESSION_KEY && val_rawbytes == sizeof DevCfg.nwkSKey) {
      memcpy(DevCfg.nwkSKey, msg + pos, val_rawbytes);
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_MAC_APP_SESSION_KEY && val_rawbytes == sizeof DevCfg.appSKey) {
      memcpy(DevCfg.appSKey, msg + pos, val_rawbytes);
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_FP) {
      DevCfg.region = val_int == PBENUM_FP_EU868 ? LORAMAC_REGION_EU868 : LORAMAC_REGION_US915;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_PORT) {
      DevCfg.txPort = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_TXP) {
      DevCfg.txPower = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_SF) {
      DevCfg.sf = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_BW) {
      DevCfg.bw = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_CONFIRMED_MESSAGES) {
      DevCfg.confirmedMsgs = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_ADAPTIVE_DATA_RATE) {
      DevCfg.adaptiveDatarate = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_RESPECT_DUTY_CYCLE) {
      DevCfg.dutyCycle = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_TIMEBASE) {
      DevCfg.sendInterval = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_SEND_TRIGGER) {
      DevCfg.sendTrigger = val_int;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_SEND_STRATEGY) {
      DevCfg.sendStrategy = val_int;
#if defined(STX)
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_HUMIDITY_UPPER_THRESHOLD) {
      DevCfg.hdc2080_threshold = val_int;
      DevCfg.hdc2080_mode = HDC2080_HUMIDITY_HIGH;
      DevCfg.useSensor.hdc2080 = true;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_HUMIDITY_LOWER_THRESHOLD) {
      DevCfg.hdc2080_threshold = val_int;
      DevCfg.hdc2080_mode = HDC2080_HUMIDITY_LOW;
      DevCfg.useSensor.hdc2080 = true;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_TEMPERATURE_UPPER_THRESHOLD) {
      DevCfg.hdc2080_threshold = PBDecodeSInt(val_int);
      DevCfg.hdc2080_mode = HDC2080_TEMPERATURE_HIGH;
      DevCfg.useSensor.hdc2080 = true;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_TEMPERATURE_LOWER_THRESHOLD) {
      DevCfg.hdc2080_threshold = PBDecodeSInt(val_int);
      DevCfg.hdc2080_mode = HDC2080_TEMPERATURE_LOW;
      DevCfg.useSensor.hdc2080 = true;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_LUMINANCE_UPPER_THRESHOLD) {
      DevCfg.sfh7776_threshold_upper = val_int;
      DevCfg.useSensor.sfh7776 = true;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_LUMINANCE_LOWER_THRESHOLD) {
      DevCfg.sfh7776_threshold_lower = val_int;
      DevCfg.useSensor.sfh7776 = true;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_AXIS_THRESHOLD) {
      DevCfg.bma400_threshold = val_int;
      DevCfg.useSensor.bma400 = true;
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_AXIS_CONFIGURE) {
      DevCfg.bma400_config = val_int;
      DevCfg.useSensor.bma400 = true;
#elif defined(STA)
    } else if((tagnr << 3 | tagtype) == PBEEPROM_BUTTON_SINGLE_COUNT) {
      DevCfg.singleCount = val_int;
    } else if((tagnr << 3 | tagtype) == PBEEPROM_BUTTON_DOUBLE_COUNT) {
      DevCfg.doubleCount = val_int;
    } else if((tagnr << 3 | tagtype) == PBEEPROM_BUTTON_LONG_COUNT) {
      DevCfg.longCount = val_int;
#endif

    /* Undefined key-value field, Skip. */
    } else {
      DEBUG_MSG("EEPROM ERR <RD Undefined 0x"), DebugLE(msg + debug_fieldpos, len - debug_fieldpos);
      DBG_PRINTF(", TAGNR %u, TAGTYPE %u, Unknown key-value\n", tagnr, tagtype);
    }


    /* Move onto the next key-value */
    pos += val_rawbytes;
  }

  // Trigger events that apply changes to sensors, lrw and etc.
  memset(&DevCfg.changed, ~0, sizeof DevCfg.changed);

  /* Log configs */
  DEBUG_PRINTF("EEPROM Loaded size:%3d crc32:0x%08x\n", len, crc);
  DEBUG_PRINTF("EEPROM DevCfg.isOtaa            %x\n", DevCfg.isOtaa);
  DEBUG_MSG(   "EEPROM DevCfg.devEui            "), DebugArr(DevCfg.devEui, sizeof DevCfg.devEui), DEBUG_MSG("\n");
  DEBUG_MSG(   "EEPROM DevCfg.appEui            "), DebugArr(DevCfg.appEui, sizeof DevCfg.appEui), DEBUG_MSG("\n");
  DEBUG_MSG(   "EEPROM DevCfg.appKey            "), DebugArr(DevCfg.appKey, sizeof DevCfg.appKey), DEBUG_MSG("\n");
  DEBUG_PRINTF("EEPROM DevCfg.devAddr           0x%08x\n", DevCfg.devAddr);
  DEBUG_MSG(   "EEPROM DevCfg.nwkSKey           "), DebugArr(DevCfg.nwkSKey, sizeof DevCfg.nwkSKey), DEBUG_MSG("\n");
  DEBUG_MSG(   "EEPROM DevCfg.appSKey           "), DebugArr(DevCfg.appSKey, sizeof DevCfg.appSKey), DEBUG_MSG("\n");
  DEBUG_PRINTF("EEPROM DevCfg.region            %s\n", DevCfg.region == LORAMAC_REGION_EU868 ? "EU868" : "US915");
  DEBUG_PRINTF("EEPROM DevCfg.txPort            %d\n", DevCfg.txPort);
  DEBUG_PRINTF("EEPROM DevCfg.txPower           %d dBm\n", DevCfg.txPower);
  DEBUG_PRINTF("EEPROM DevCfg.sf                %d\n", DevCfg.sf);
  DEBUG_PRINTF("EEPROM DevCfg.bw                %d\n", DevCfg.bw);
  DEBUG_PRINTF("EEPROM DevCfg.confirmedMsgs     %x\n", DevCfg.confirmedMsgs);
  DEBUG_PRINTF("EEPROM DevCfg.adaptiveDatarate  %x\n", DevCfg.adaptiveDatarate);
  DEBUG_PRINTF("EEPROM DevCfg.dutyCycle         %x\n", DevCfg.dutyCycle);

  return;
err:
  DEBUG_MSG("EEPROM ERR <RD Undefined 0x"), DebugLE(msg + debug_fieldpos, len - debug_fieldpos), DBG_PRINTF("%s", debug_msg);;
  DEBUG_MSG("EEPROM Invalidating and rebooting.");
  HW_EraseEEPROM(EEPROM_APP);
  HW_EraseEEPROM(EEPROM_APP + 4);
  NVIC_SystemReset();
}

/*
 * DESCRIPTION
 *        The NFC protobuf message is reused for EEPROM store. Though we need
 *        to store more than NFC provides. So IDs of 2047 and downwards are
 *        used.
 */
void EEPROM_Save(void) {
  uint8_t msg[256];
  size_t len = sizeof msg;
  size_t size = 1;

  /* 1st byte always zero, to allow future (unlikely) breaking changes */
  msg[0] = 0;

  /* Serialize DevCfg into a protobuf */
  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_OTAA, (uint64_t)DevCfg.isOtaa);
  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_DEV_EUI, u64(DevCfg.devEui));
  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_APP_EUI, u64(DevCfg.appEui));
  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_APP_KEY, PBMSG_BX_LORA_APP_KEY_SIZE, DevCfg.appKey);
  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_DEV_ADDR, DevCfg.devAddr);
  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_MAC_NET_SESSION_KEY, PBMSG_BX_LORA_MAC_NET_SESSION_KEY_SIZE, DevCfg.nwkSKey);
  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_MAC_APP_SESSION_KEY, PBMSG_BX_LORA_MAC_APP_SESSION_KEY_SIZE, DevCfg.appSKey);
  size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_FP, (uint64_t)(DevCfg.region == LORAMAC_REGION_EU868 ? PBENUM_FP_EU868 : PBENUM_FP_US915));
  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_PORT, (uint64_t)DevCfg.txPort);
  size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_TXP, (uint64_t)DevCfg.txPower);
  size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_SF, (uint64_t)DevCfg.sf);
  size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_BW, (uint64_t)DevCfg.bw);
  size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_CONFIRMED_MESSAGES, (uint64_t)DevCfg.confirmedMsgs);
  size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_ADAPTIVE_DATA_RATE, (uint64_t)DevCfg.adaptiveDatarate);
  size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_RESPECT_DUTY_CYCLE, (uint64_t)DevCfg.dutyCycle);

  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_TIMEBASE, (uint64_t)DevCfg.sendInterval);
  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_SEND_TRIGGER, (uint64_t)DevCfg.sendTrigger);
  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_SEND_STRATEGY, (uint64_t)DevCfg.sendStrategy);

#if defined(STX)
  if(DevCfg.useSensor.hdc2080) switch(DevCfg.hdc2080_mode) {
  case HDC2080_TEMPERATURE_HIGH:  size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_TEMPERATURE_UPPER_THRESHOLD, PBEncodeSInt(DevCfg.hdc2080_threshold)); break;
  case HDC2080_TEMPERATURE_LOW:   size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_TEMPERATURE_LOWER_THRESHOLD, PBEncodeSInt(DevCfg.hdc2080_threshold)); break;
  case HDC2080_HUMIDITY_HIGH:     size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_HUMIDITY_UPPER_THRESHOLD, PBEncodeSInt(DevCfg.hdc2080_threshold));    break;
  case HDC2080_HUMIDITY_LOW:      size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_HUMIDITY_LOWER_THRESHOLD, DevCfg.hdc2080_threshold);                  break;
  }

  if(DevCfg.useSensor.sfh7776) {
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_LUMINANCE_UPPER_THRESHOLD, (uint64_t)DevCfg.sfh7776_threshold_upper);
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_LUMINANCE_LOWER_THRESHOLD, (uint64_t)DevCfg.sfh7776_threshold_lower);
  }
  if(DevCfg.useSensor.bma400) {
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_AXIS_THRESHOLD, (uint64_t)DevCfg.bma400_threshold);
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_AXIS_CONFIGURE, (uint64_t)DevCfg.bma400_config);
  }

#elif defined(STA)
  size += PBEncodeMsgField(msg, len, size, PBEEPROM_BUTTON_SINGLE_COUNT, (uint64_t)DevCfg.singleCount);
  size += PBEncodeMsgField(msg, len, size, PBEEPROM_BUTTON_DOUBLE_COUNT, (uint64_t)DevCfg.doubleCount);
  size += PBEncodeMsgField(msg, len, size, PBEEPROM_BUTTON_LONG_COUNT, (uint64_t)DevCfg.longCount);
#endif

  /* Erase EEPROM */
  HW_ResetEEPROM((void*)(EEPROM_APP + 8), size);

  /* Save CRC, length and protobuf to EEPROM */
  HW_ProgramEEPROM(EEPROM_APP, EEPROM_CRC(msg, size));
  HW_ProgramEEPROM(EEPROM_APP + 4, size);
  HW_WriteEEPROM((void*)(EEPROM_APP + 8), msg, size);
}

uint32_t EEPROM_CRC(const uint8_t *buf, size_t size) {
  return Crc32Finalize(Crc32Update(Crc32Init(), buf, size));
}
