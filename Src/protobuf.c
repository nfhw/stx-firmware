//bin/true; export WFLAGS="-Wall -Wextra -Wpedantic -Wformat=2 -Wwrite-strings -Wswitch-default -Wold-style-definition -Wstrict-prototypes -Wc++-compat -Wcast-align=strict -Wcast-qual"
//usr/bin/env gcc -DUNITTEST -ggdb3 $WFLAGS -O3 -fsanitize=address,undefined -std=iso9899:2018 -I"${0%/*}/../Inc" -o "${o=`mktemp`}" "$0" && exec setarch -R -- sh -c 'set -x; exec -a "$0" "$@"' "$0" "$o" "$@";
//bin/true; exit 1

/* Includes ------------------------------------------------------------------*/
#include "protobuf.h"
#include "lrw.h"       /* lrw_GetIsOtaDevice */
#include "eeprom.h"    /* BackUpFlash */
#include "main.h"
#include "mac/LoRaMac.h"
#include "mac/region/Region.h"  //
#include <assert.h>             // assert
#include <inttypes.h>  /* PRIu8 uint8_t */
#include <stdalign.h>  /* alignas */
#include <stdarg.h>    /* va_arg */
#include <stdio.h>     /* printf */
#include <stdlib.h>    /* EXIT_SUCCESS */
#include <string.h>    /* memcmp */
#include <stdbool.h>   /* bool true false */

/* Hosted environment only */
#ifdef UNITTEST
#define DBG_PRINTF printf
#else
#include "hardware.h"
#endif

/* External variables --------------------------------------------------------*/
/* Private typedef -----------------------------------------------------------*/
/* Private defines -----------------------------------------------------------*/
/* Private macros ------------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
/* Global variables ----------------------------------------------------------*/
/* Public functions ----------------------------------------------------------*/
/**
 * DESCRIPTION
 *        Shorthand to do unbuffered print of byte sequence.
 */
static void PrintBuffer(const char* pre, const uint8_t buf[], uint16_t len, const char* post) {
  DBG_PRINTF("%s0x", pre);
  if(len) do {
    DBG_PRINTF("%02x", buf[--len]);
  } while(len);
  DBG_PRINTF("%s", post);
}

/**
 * DESCRIPTION
 *        Shorthand for passing uint64 values during PBEncode.
 *
 *        0 1 2 3 --el-memcpy--> 3210 --proto--> 0 1 2 3
 *        0 1 2 3 --be-memcpy--> 0123 --proto--> 3 2 1 0
 *        0 1 2 3 --el-boolor--> 3210 --proto--> 0 1 2 3
 *        0 1 2 3 --be-boolor--> 3210 --proto--> 0 1 2 3
 */
uint64_t u64(uint8_t b[static 8]) {
  return
      (uint64_t)b[7] << 56 | (uint64_t)b[6] << 48 |
      (uint64_t)b[5] << 40 | (uint64_t)b[4] << 32 |
      (uint64_t)b[3] << 24 | (uint64_t)b[2] << 16 |
      (uint64_t)b[1] << 8  | (uint64_t)b[0];
}

void b64(uint8_t b[static 8], uint64_t v) {
  b[0] = v >>  0 & 0xFF;
  b[1] = v >>  8 & 0xFF;
  b[2] = v >> 16 & 0xFF;
  b[3] = v >> 24 & 0xFF;
  b[4] = v >> 32 & 0xFF;
  b[5] = v >> 40 & 0xFF;
  b[6] = v >> 48 & 0xFF;
  b[7] = v >> 56 & 0xFF;
}

/* NAME
 *        PBEncodeField - generic encoder of single protobuf key-value
 *
 * DESCRIPTION
 *        Output buffer `out` of `len` may be scant or null, as return > len or
 *        len == 0, respectively. Thus latter can deduce size pre-allocation.
 *
 *        The `key` specifies a 29-bit identifier (msb), and 3-bit type (lsb).
 *        Convention is to pass PBMSG_ macro encoding both.
 *
 *        Next is either 1 or 2 fields, fated by type in `key` argument:
 *
 *            0: (uint64_t)varint                PB_TAGTYPE_VARINT
 *            1: (uint64_t)fixed64               PB_TAGTYPE_FIXED64
 *            2: (size_t)size, (uint8_t *)bytes  PB_TAGTYPE_BYTES
 *            5: (uint32_t)fixed32               PB_TAGTYPE_FIXED32
 *
 *        Make sure to cast appropriately, or UB will getcha!
 *
 * RETURN VALUE
 *        Size of encoded filed. If greater than buffer length, write is
 *        partial. 0 indicates an error.
 *
 * BUGS
 *        Heed perils of variable argument lists! If passing literals, cast!
 *        Else u32 value 3 becomes a u64 + UB, e.g. 0xb4dc0ded_00000003.
 */
size_t PBEncodeField(uint8_t * restrict out, size_t len, uint32_t key, ...) {
  va_list ap;
  size_t size = 0;
  const uint8_t type = key & 0x7;
  const uint32_t id = key >> 3;

  /* contract programming * preconditions */
  assert(type == 0 || type == 1 || type == 2 || type == 5);
  assert(out || !len);
  assert(id);

  /* Encode key */

  /* encode 1st byte of any key */
  if(size++ < len)
    /* 3 type bits | 4 id bits | 8th continuation bit */
    out[size - 1] = (key & 0x7f) | (key >> 7 ? 0x80 : 0);

  /* for each 7-bits encode 1-byte (25-bits, 4-bytes total) */
  for(uint32_t i = id >> 4; i; i >>= 7)
    if(size++ < len)
      /* 7 id bits | 8th continuation bit */
      out[size - 1] = (i & 0x7f) | (i >> 7 ? 0x80 : 0);

  /* Encode value */

  va_start(ap, key);
  switch(type) {
  case PB_TAGTYPE_VARINT: {
    /* foreach 7-bits encode 1-byte (64-bits, 10-bytes total) */
    uint64_t in = va_arg(ap, uint64_t);
    do {
      if(size++ < len)
        out[size - 1] = (in & 0x7f) | (in >> 7 ? 0x80 : 0);
    } while(in >>= 7);
    break;;
  }
  case PB_TAGTYPE_FIXED64: {
    uint64_t x = va_arg(ap, uint64_t);
    const size_t cpylen = size > len ? 0 : size + 8 > len ? len - size : 8;
    if(cpylen)
      memcpy(out + size, (const uint8_t[8]){
        x >>  0, x >>  8, x >> 16, x >> 24,
        x >> 32, x >> 40, x >> 48, x >> 56}, cpylen);
    size += 8;
    break;;
  }
  case PB_TAGTYPE_FIXED32: {
    uint32_t x = va_arg(ap, uint32_t);
    const size_t cpylen = size > len ? 0 : size + 4 > len ? len - size : 4;
    if(cpylen)
      memcpy(out + size, (const uint8_t[4]){
        x >>  0, x >>  8, x >> 16, x >> 24}, cpylen);
    size += 4;
    break;;
  }
  case PB_TAGTYPE_BYTES: {
    const size_t buflen = va_arg(ap, size_t);
    const uint8_t *buf = va_arg(ap, uint8_t * restrict);
    uint64_t x = buflen;

    /* foreach 7-bits encode 1-byte (64-bits, 10-bytes total) */
    do {
      if(size++ < len)
        out[size - 1] = (x & 0x7f) | (x >> 7 ? 0x80 : 0);
    } while(x >>= 7);

    const size_t cpylen = size > len ? 0 : size + buflen > len ? len - size : buflen;
    if(cpylen)
      memcpy(out + size, buf, cpylen);
    size += buflen;
    break;;
  }
  default: break;;
  }
  va_end(ap);

  return size;
}

/**
 * DESCRIPTION
 *        Takes variable-sized array `varint` that can go up to 10 bytes.
 *        From which a uint64_t `value` is decoded.
 *        Continue bit 0x80 of each byte, if clear, terminates varint.
 *        Thus each input byte consists of 7 bits essentially.
 *
 *        The `value` is never written or bitshifted, but OR'ed.
 *        This way it may point to smaller integer types, casted as uint64_t*.
 *        You must clear `value` beforehand.
 *
 *        The `maxbits` protects both input `varint` going out of bounds, and
 *        output `value` being written out of bounds. Sensible values are [1,64].
 *
 * RETURN VALUE
 *        Return length of varint, from 1 to 10, or 0 on invalid byte sequence.
 *
 * EXAMPLE
 *               (out) uint64_t | varint (in)
 *        0x0000_0000_0000_007f | 0x7f
 *        0x0000_0000_0000_0080 | 0x80 0x01
 *        0x0000_0000_0000_0100 | 0x80 0x02
 *        0x0000_0000_0000_0200 | 0x80 0x04
 *        0x7fff_ffff_ffff_ffff | 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0x7f
 *        0xffff_ffff_ffff_ffff | 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0x0
 *        0xffff_ffff_ffff_ffff | 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0xff 0x7f
 *
 */
uint8_t PBDecodeVarint(const uint8_t* varint, uint8_t maxbits, void* value) {
  uint8_t destbytes, nextbits, bitmask, bits = 0;

  destbytes = maxbits / 8 + !!(maxbits % 8);
  destbytes =
      destbytes <= 1 ? 1 :
      destbytes <= 2 ? 2 :
      destbytes <= 4 ? 4 :
      destbytes <= 8 ? 8 : 8;

  do {
    /* Next input byte only on 2nd iteration */
    varint += !!bits;

    /* Prepare stencil to carve bits from input byte */
    nextbits = maxbits - bits;
    nextbits = nextbits > 7 ? 7 : nextbits;
    bitmask = ((uint8_t)1 << nextbits) - 1;

    /* Carve bits, affix to value */
    switch(destbytes) {
    case 1: *(uint8_t *)value |= ((bitmask & *varint) + (uint8_t )0) << bits; break;
    case 2: *(uint16_t*)value |= ((bitmask & *varint) + (uint16_t)0) << bits; break;
    case 4: *(uint32_t*)value |= ((bitmask & *varint) + (uint32_t)0) << bits; break;
    case 8: *(uint64_t*)value |= ((bitmask & *varint) + (uint64_t)0) << bits; break;
    default: return 0; break;
    }
    bits += nextbits;

  /* Check continuation bit after taking value */
  } while(0x80 & *varint && bits < maxbits);

  /* Return input bytes read or 0 if too many continuation bits set */
  return *varint & 0x80 ? 0 : bits / 7 + !!(bits % 7);
}

uint64_t PBEncodeSInt(int64_t val) {
	return (uint64_t)val << 1 ^ (val < 0 ? UINT64_MAX : 0);
}

int64_t PBDecodeSInt(uint64_t val) {
  return (int64_t)(val & 1 ? ~(val >> 1) : val >> 1);
}

/**
 * DESCRIPTION
 *        Wire format inherited from Google protobuf. Key size from 1 to 5 bytes.
 *        Three low-order bits of 1st byte are type, rest are identifier as varint.
 *        Identifier inclusive range [1,536870911]. That's 2^29-1 values.
 *
 *        Types:
 *            0: `uint64`   Varint. Variable integer. See PBDecodeVarint()
 *            1: `fixed64`  8 bytes. Fixed integer.
 *            2: `bytes`    Varint+payload. Variable byte array. Length range [0,2^32].
 *            5: `fixed32`  4 bytes. Fixed integer.
 *
 *        Wire format integers are little endian.
 *        E.g. lowest memory address contains littlest end (LSB).
 *        Arrays don't have endianess, and reflect memory order.
 *
 * BUGS
 *        Field overrides and merge messages not supported. Max msg size is 251 bytes.
 *        Partial invalid messages may apply effect.
 *        Arrays larger than 250 bytes not supported.
 *
 * EXAMPLE
 *               max key                     max varint
 *        f8 ff ff ff 0f  ff ff ff ff ff ff ff ff ff 01
 *        f8 ff ff ff ff  ff ff ff ff ff ff ff ff ff f1
 *        uint64 536870911 = 18446744073709551615
 *
 *            lowest key  tiny varint
 *                    08  01
 *        uint64 1 = 1
 *
 *            larger key                  fixed64
 *                 81 01  01 00 00 00 00 00 00 00
 *        fixed64 128 = 1
 *
 *            larger key  varint_length  payload
 *              82 80 40             05  aa bb cc dd ee
 *        bytes 131072 = {0xaa, 0xbb, 0xcc, 0xdd, 0xee}
 */
void PBDecodeMsg(const uint8_t *msg, uint8_t len) {
  MibRequestConfirm_t mibReq;
  uint8_t pos = 0;
  const char *debug_msg = NULL;
  uint8_t debug_fieldpos = 0;
  bool use_bma400 = false, use_hdc2080 = false, use_sfh7776 = false;

  /* 1st byte always zero, to allow future (unlikely) breaking changes */
  if(len < 1 || msg[0]) {
    debug_msg = ", Unknown message version\n";
    goto abort;
  }
  if(len == 1) {
    debug_msg = ", Out-of-bounds\n";
    goto abort;
  }
  pos++;

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
        goto abort;
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
      goto abort;
    }

    /*
     * Decode Value
     */

    /* Key without value is ill-formed. */
    if(!(len - pos)) {
      debug_msg = ", Out-of-bounds tag w/o value\n";
      goto abort;
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
      goto abort;
      break;
    }
    }

    /* Value was too large or ill-formed */
    if(!val_rawbytes) {
      debug_msg = ", Ill-formed value\n";
      goto abort;
    }

    /*
     * Read Value
     */

    /* LoRaWAN */

    /* rwr-  5:    bool   (TTN) Activation Method */
    if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_OTAA) {
      DBG_PRINTF("NFC <RX lora_otaa 0x%02x\n", val_int);
      val_int = !!val_int;
      DEVCFG_SET(DevCfg.isOtaa, val_int) && (DevCfg.changed.lrw = true);

    /* rwr-  6: char[8]   (TTN) Device EUI */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_DEV_EUI) {
      uint8_t deveui[8];
      PrintBuffer("NFC <RX lora_dev_eui ", &val_int, sizeof val_int, "\n");
      b64(deveui, val_int);
      DEVCFG_MEMCPY(DevCfg.devEui, deveui, sizeof deveui) && (DevCfg.changed.lrw = true);

    /* rwr-  7: char[8]   (TTN) Application EUI */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_APP_EUI) {
      uint8_t appeui[8];
      PrintBuffer("NFC <RX lora_app_eui ", &val_int, sizeof val_int, "\n");
      b64(appeui, val_int);
      DEVCFG_MEMCPY(DevCfg.appEui, appeui, sizeof appeui) && (DevCfg.changed.lrw = true);

    /* rw--  8: char[16]  (TTN) App Key */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_APP_KEY && val_rawbytes == 16) {
      PrintBuffer("NFC <RX lora_app_key ", msg + pos, val_rawbytes, "\n");
      DEVCFG_MEMCPY(DevCfg.appKey, msg + pos, val_rawbytes) && (DevCfg.changed.lrw = true);

    /* rwr-  9: uint32_t  (TTN) Device Address */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_DEV_ADDR) {
      DBG_PRINTF("NFC <RX lora_dev_addr 0x%08x\n", val_int);
      DEVCFG_SET(DevCfg.devAddr, val_int) && (DevCfg.changed.lrw = true);

    /* rw-- 10: char[16]  (TTN) Network Session Key */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_MAC_NET_SESSION_KEY && val_rawbytes == 16) {
      PrintBuffer("NFC <RX lora_mac_net_session_key ", msg + pos, val_rawbytes, "\n");
      DEVCFG_MEMCPY(DevCfg.nwkSKey, msg + pos, val_rawbytes) && (DevCfg.changed.lrw = true);

    /* rw-- 11: char[16]  (TTN) App Session Key */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_MAC_APP_SESSION_KEY && val_rawbytes == 16) {
      PrintBuffer("NFC <RX lora_mac_app_session_key ", msg + pos, val_rawbytes, "\n");
      DEVCFG_MEMCPY(DevCfg.appSKey, msg + pos, val_rawbytes) && (DevCfg.changed.lrw = true);

    /* rwr- 12:     bool  LoRa Join status */
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_JOINED) {
      DBG_PRINTF("NFC <RX lora_joined 0x%02x\n", val_int);
      if(!val_int) {
        mibReq.Type = MIB_NETWORK_ACTIVATION;
        mibReq.Param.NetworkActivation = ACTIVATION_TYPE_NONE;
        LoRaMacMibSetRequestConfirm(&mibReq);
        // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
      }

    /* rwr- 13: uint8_t LoRa Frequency Plan */
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_FP) {
      DBG_PRINTF("NFC <RX lora_fp 0x%02x\n", val_int);
      switch(val_int) {
      case PBENUM_FP_EU868: DEVCFG_SET(DevCfg.region, LORAMAC_REGION_EU868) && (DevCfg.changed.lrw = true); break;
      case PBENUM_FP_US915: DEVCFG_SET(DevCfg.region, LORAMAC_REGION_US915) && (DevCfg.changed.lrw = true); break;
      default: DEBUG_MSG("NFC Bad Value!\n");
      }

    /* rwr- 14:  uint8_t  LoRa Port */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_LORA_PORT) {
      DBG_PRINTF("NFC <RX lora_port 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.txPort, val_int) && (DevCfg.changed.lrw = true);

    /* rwr- 15:  uint8_t  LoRa Transmit Power */
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_TXP) {
      DBG_PRINTF("NFC <RX lora_txp 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.txPower, val_int) && (DevCfg.changed.lrw = true);

    /* rwr- 16:  uint8_t  LoRa Spreading Factor */
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_SF) {
      DBG_PRINTF("NFC <RX lora_sf 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.sf, val_int) && (DevCfg.changed.lrw = true);

    /* rwr- 17:  uint8_t  LoRa Bandwidth */
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_BW) {
      DBG_PRINTF("NFC <RX lora_bw 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.bw, val_int) && (DevCfg.changed.lrw = true);

    /* rwr- 18:     bool  LoRa Confirmed Messages */
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_CONFIRMED_MESSAGES) {
      DBG_PRINTF("NFC <RX lora_confirmed_messages 0x%02x\n", val_int);
      val_int = !!val_int;
      DEVCFG_SET(DevCfg.confirmedMsgs, val_int) && (DevCfg.changed.lrw = true);

    /* rwr- 19:     bool  LoRa Adaptive Data Rate */
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_ADAPTIVE_DATA_RATE) {
      DBG_PRINTF("NFC <RX lora_adaptive_data_rate 0x%02x\n", val_int);
      val_int = !!val_int;
      DEVCFG_SET(DevCfg.adaptiveDatarate, val_int) && (DevCfg.changed.lrw = true);

    /* rwr- 20:     bool  LoRa Respect Duty Cycle */
    } else if((tagnr << 3 | tagtype) == PBMSG_TX_LORA_RESPECT_DUTY_CYCLE) {
      DBG_PRINTF("NFC <RX lora_respect_duty_cycle 0x%02x\n", val_int);
      val_int = !!val_int;
      DEVCFG_SET(DevCfg.dutyCycle, val_int) && (DevCfg.changed.lrw = true);

    /* Sensors */

    /* rw-- 21: uint32_t  Send interval of LoRa Messages */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_TIMEBASE) {
      DBG_PRINTF("NFC <RX sensor_timebase 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.sendInterval, val_int) && (DevCfg.changed.resched = true);

    /* rw-- 22:  uint8_t  Send Trigger */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_SEND_TRIGGER) {
      DBG_PRINTF("NFC <RX sensor_send_trigger 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.sendTrigger, val_int) && (DevCfg.changed.resched = true);

    /* rw-- 23:  uint8_t  Send Strategy */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_SEND_STRATEGY) {
      DBG_PRINTF("NFC <RX sensor_send_strategy 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.sendStrategy, val_int) && (DevCfg.changed.resched = true);

#if defined(STX)
    /* rw-- 24:  uint8_t  Send LoRa Message on humidity upper threshold */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_HUMIDITY_UPPER_THRESHOLD) {
      DBG_PRINTF("NFC <RX sensor_humidity_upper_threshold 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.hdc2080_threshold, val_int) && (DevCfg.changed.hdc2080 = true);
      DEVCFG_SET(DevCfg.hdc2080_mode, HDC2080_HUMIDITY_HIGH) && (DevCfg.changed.hdc2080 = true);
      use_hdc2080 = true;

    /* rw-- 25:  uint8_t  Send LoRa Message on humidity lower threshold */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_HUMIDITY_LOWER_THRESHOLD) {
      DBG_PRINTF("NFC <RX sensor_humidity_lower_threshold 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.hdc2080_threshold, val_int) && (DevCfg.changed.hdc2080 = true);
      DEVCFG_SET(DevCfg.hdc2080_mode, HDC2080_HUMIDITY_LOW) && (DevCfg.changed.hdc2080 = true);
      use_hdc2080 = true;

    /* rw-- 26:  int16_t  Send LoRa Message on temperature upper threshold */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_TEMPERATURE_UPPER_THRESHOLD) {
      DBG_PRINTF("NFC <RX sensor_temperature_upper_threshold 0x%02x\n", val_int);
      uint64_t v = PBDecodeSInt(val_int);
      DEVCFG_SET(DevCfg.hdc2080_threshold, v) && (DevCfg.changed.hdc2080 = true);
      DEVCFG_SET(DevCfg.hdc2080_mode, HDC2080_TEMPERATURE_HIGH) && (DevCfg.changed.hdc2080 = true);
      use_hdc2080 = true;

    /* rw-- 27:  int16_t  Send LoRa Message on temperature lower threshold */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_TEMPERATURE_LOWER_THRESHOLD) {
      DBG_PRINTF("NFC <RX sensor_temperature_lowe_thresholdr 0x%02x\n", val_int);
      uint64_t v = PBDecodeSInt(val_int);
      DEVCFG_SET(DevCfg.hdc2080_threshold, v) && (DevCfg.changed.hdc2080 = true);
      DEVCFG_SET(DevCfg.hdc2080_mode, HDC2080_TEMPERATURE_LOW) && (DevCfg.changed.hdc2080 = true);
      use_hdc2080 = true;

    /* rw-- 28: uint16_t  Send LoRa Message on luminance upper threshold */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_LUMINANCE_UPPER_THRESHOLD) {
      DBG_PRINTF("NFC <RX sensor_luminance_upper_threshold 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.sfh7776_threshold_upper, val_int) && (DevCfg.changed.sfh7776 = true);
      use_sfh7776 = true;

    /* rw-- 29: uint16_t  Send LoRa Message on luminance lower threshold */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_LUMINANCE_LOWER_THRESHOLD) {
      DBG_PRINTF("NFC <RX sensor_luminance_lower_threshold 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.sfh7776_threshold_lower, val_int) && (DevCfg.changed.sfh7776 = true);
      use_sfh7776 = true;

    /* rw-- 30: uint32_t  Send LoRa Message on axis acceleration above threshold */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_AXIS_THRESHOLD) {
      DBG_PRINTF("NFC <RX sensor_axis_threshold 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.bma400_threshold, val_int) && (DevCfg.changed.bma400 = true);
      use_bma400 = true;

    /* rw-- 31: uint32_t  Send LoRa Message on axis acceleration configuration */
    } else if((tagnr << 3 | tagtype) == PBMSG_BX_SENSOR_AXIS_CONFIGURE) {
      DBG_PRINTF("NFC <RX sensor_axis_configure 0x%02x\n", val_int);
      DEVCFG_SET(DevCfg.bma400_config, val_int) && (DevCfg.changed.bma400 = true);
      use_bma400 = true;

#endif

    /* Undefined key-value field, Skip. */
    } else {
      PrintBuffer("NFC <RX Undefined ", msg + debug_fieldpos, len - debug_fieldpos, "");
      DBG_PRINTF(", TAGNR %u, TAGTYPE %u, Unknown key-value\n", tagnr, tagtype);
    }

    /* Move onto the next key-value */
    pos += val_rawbytes;
  }

abort:
#ifdef STX
  DEVCFG_SET(DevCfg.useSensor.bma400,  use_bma400)  && (DevCfg.changed.bma400  = true);
  DEVCFG_SET(DevCfg.useSensor.sfh7776, use_sfh7776) && (DevCfg.changed.sfh7776 = true);
  DEVCFG_SET(DevCfg.useSensor.hdc2080, use_hdc2080) && (DevCfg.changed.hdc2080 = true);
#endif

  if(debug_msg) {
    PrintBuffer("NFC <RX Undefined ", msg + debug_fieldpos, len - debug_fieldpos, debug_msg);
  }
  return;
}

size_t PBEncodeMsg_DeviceSensors(uint8_t *msg, size_t len, bool pw_valid) {
  size_t size = 0;
  uint32_t b;
  (void)pw_valid;
  float voltage, temperature;

  /* discriminator byte specifies message DeviceSensors */
  if(size++ < len)
    msg[0] = PBMSGID_DEVICE_SENSORS;

  /* enum: Device Part Number */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_DEVICE_PART_NUMBER,
#ifdef STX
      PBENUM_PARTNR_STX
#elif defined(STE)
      PBENUM_PARTNR_STE
#elif defined(STA)
      PBENUM_PARTNR_STA
#endif
  );

  /*  uint8_t: Device Battery Voltage */
  getBatteryVoltageAndTemperature(&voltage, &temperature);
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_DEVICE_BATTERY_VOLTAGE, (uint64_t)(voltage * 100));

#ifdef STE
#ifndef BSEC
  BME680_Read();
#endif
  /*  int16_t: Temperature */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_TEMPERATURE, PBEncodeSInt(bme680.data.temperature));

  /* uint32_t: Humidity */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_HUMIDITY, (uint64_t)bme680.data.humidity);

  /* uint16_t: Pressure */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_PRESSURE, (uint64_t)bme680.data.pressure);

#ifdef BSEC
  /*    float: Air Quality Index */
  memcpy(b, &bme680.bsec.iaq, sizeof b), size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_AIR_QUALITY, (uint32_t)b);

  /*    float: VOC Equivalent */
  memcpy(b, &bme680.bsec.voc, sizeof b), size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_AIR_VOC_PPM, (uint32_t)b);

  /*    float: CO2 Equivalent */
  memcpy(b, &bme680.bsec.co2, sizeof b), size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_AIR_CO2_PPM, (uint32_t)b);

  /*  uint8_t: Air Accuracy */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_AIR_ACCURACY, (uint64_t)bme680.bsec.acc);

#endif
#elif defined(STX)
  HDC2080_Read();
  SFH7776_Read();
  BMA400_Read();
  /*  int16_t: Temperature */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_TEMPERATURE, PBEncodeSInt(hdc2080.fix_temp));

  /* uint32_t: Humidity */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_HUMIDITY, (uint64_t)hdc2080.raw_humid * 100000 / 65536);

  /* uint16_t: Luminance */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_LUMINANCE, (uint64_t)sfh7776.lux);

  /*  int16_t: X-Axis Acceleration */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_X_AXIS, PBEncodeSInt(bma400.fix_x));

  /*  int16_t: Y-Axis Acceleration */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_Y_AXIS, PBEncodeSInt(bma400.fix_y));

  /*  int16_t: Z-Axis Acceleration */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_Z_AXIS, PBEncodeSInt(bma400.fix_z));
#elif defined(STA)
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_TEMPERATURE, PBEncodeSInt(temperature * 100));
  /*  uint8_t: Gesture Count */
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_GESTURE_SINGLE_COUNT, (uint64_t)DevCfg.singleCount);
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_GESTURE_DOUBLE_COUNT, (uint64_t)DevCfg.doubleCount);
  size += PBEncodeMsgField(msg, len, size, PBSMSG_TX_SENSOR_GESTURE_LONG_COUNT, (uint64_t)DevCfg.longCount);
#endif

  return size;
}

size_t PBEncodeMsg_DeviceConfiguration(uint8_t *msg, size_t len, bool pw_valid) {
  size_t size = 0;

  /* discriminator byte specifies message DeviceConfiguration */
  if(size++ < len)
    msg[0] = PBMSGID_DEVICE_CONFIGURATION;

  /* Device Info
   * ----------- */

  /* enum: Device Part Number */
  size += PBEncodeMsgField(msg, len, size, PBMSG_TX_DEVICE_PART_NUMBER,
#ifdef STX
      PBENUM_PARTNR_STX
#elif defined(STE)
      PBENUM_PARTNR_STE
#elif defined(STA)
      PBENUM_PARTNR_STA
#endif
  );
  /* v1.0 Release */
  size += PBEncodeMsgField(msg, len, size, PBMSG_TX_DEVICE_FW_VERSION, (uint64_t)FIRMWARE_VERSION);

  /* Development version is 0, and zero is implied implicitly. No need to
   * explicitly encode "Device Firmware Version" */

  if(pw_valid) {
    MibRequestConfirm_t mibReq;
    GetPhyParams_t getPhy;
    LoRaMacNvmData_t *nvm;
    int8_t datarate;
    int8_t value;

    // Obtain direct access to low-level LoRaMac-node context, some things can't get any other way.
    mibReq.Type = MIB_NVM_CTXS;
    LoRaMacMibGetRequestConfirm(&mibReq);
    nvm = mibReq.Param.Contexts;

    mibReq.Type = MIB_CHANNELS_DATARATE;
    LoRaMacMibGetRequestConfirm(&mibReq);
    datarate = mibReq.Param.ChannelsDatarate;

    /* LoRa Settings
     * ------------- */

    /* rw--  5:    bool   (TTN) Activation Method */
    mibReq.Type = MIB_NETWORK_ACTIVATION;
    LoRaMacMibGetRequestConfirm(&mibReq);
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_OTAA, (uint64_t)(mibReq.Param.NetworkActivation != ACTIVATION_TYPE_ABP));

    /* rw--  6: char[8]   (TTN) Device EUI */
    mibReq.Type = MIB_DEV_EUI;
    LoRaMacMibGetRequestConfirm(&mibReq);
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_DEV_EUI, u64(mibReq.Param.DevEui));

    /* rw--  7: char[8]   (TTN) Application EUI */
    mibReq.Type = MIB_JOIN_EUI;
    LoRaMacMibGetRequestConfirm(&mibReq);
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_APP_EUI, u64(mibReq.Param.JoinEui));

    /* rw--  8: char[16]  (TTN) App Key */
    size += PBEncodeMsgField(msg, len, size,
        PBMSG_BX_LORA_APP_KEY,
        PBMSG_BX_LORA_APP_KEY_SIZE, nvm->SecureElement.KeyList[NWK_KEY].KeyValue);

    /* rw--  9: uint32_t  (TTN) Device Address */
    mibReq.Type = MIB_DEV_ADDR;
    LoRaMacMibGetRequestConfirm(&mibReq);
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_DEV_ADDR, mibReq.Param.DevAddr);

    /* rw-- 10: char[16]  (TTN) Network Session Key */
    size += PBEncodeMsgField(msg, len, size,
        PBMSG_BX_LORA_MAC_NET_SESSION_KEY,
        PBMSG_BX_LORA_MAC_NET_SESSION_KEY_SIZE, nvm->SecureElement.KeyList[F_NWK_S_INT_KEY].KeyValue);

    /* rw-- 11: char[16]  (TTN) App Session Key */
    size += PBEncodeMsgField(msg, len, size,
        PBMSG_BX_LORA_MAC_APP_SESSION_KEY,
        PBMSG_BX_LORA_MAC_APP_SESSION_KEY_SIZE, nvm->SecureElement.KeyList[APP_S_KEY].KeyValue);

    /* rw-- 12:     bool  LoRa Join status */
    mibReq.Type = MIB_NETWORK_ACTIVATION;
    LoRaMacMibGetRequestConfirm(&mibReq);
    size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_JOINED, (uint64_t)(mibReq.Param.NetworkActivation != ACTIVATION_TYPE_NONE));

    /* rw-- 13:  uint8_t  LoRa Frequency Plan */
    size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_FP, (uint64_t)(DevCfg.region == LORAMAC_REGION_EU868 ? PBENUM_FP_EU868 : PBENUM_FP_US915));

    /* rw-- 14:  uint8_t  LoRa Port */
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_LORA_PORT, (uint64_t)DevCfg.txPort);

    /* rw-- 15:  uint8_t  LoRa Transmit Power */
    mibReq.Type = MIB_CHANNELS_TX_POWER;
    LoRaMacMibGetRequestConfirm(&mibReq);
    size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_TXP, (uint64_t)LRW_FromTxPower(mibReq.Param.ChannelsTxPower));

    /* rw-- 16:  uint8_t  LoRa Spreading Factor */
    getPhy.Attribute = PHY_SF_FROM_DR;
    getPhy.Datarate = datarate;
    value = RegionGetPhyParam(DevCfg.region, &getPhy).Value;
    size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_SF, (uint64_t)value);

    /* rw-- 17:  uint8_t  LoRa Bandwidth */
    getPhy.Attribute = PHY_BW_FROM_DR;
    getPhy.Datarate = datarate;
    value = RegionGetPhyParam(DevCfg.region, &getPhy).Value;
    size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_BW, (uint64_t)value + 1);

    /* rw-- 18:     bool  LoRa Confirmed Messages */
    size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_CONFIRMED_MESSAGES, (uint64_t)DevCfg.confirmedMsgs);

    /* rw-- 19:     bool  LoRa Adaptive Data Rate */
    mibReq.Type = MIB_ADR;
    LoRaMacMibGetRequestConfirm(&mibReq);
    size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_ADAPTIVE_DATA_RATE, (uint64_t)mibReq.Param.AdrEnable);

    /* rw-- 20:     bool  LoRa Respect Duty Cycle */
    size += PBEncodeMsgField(msg, len, size, PBMSG_TX_LORA_RESPECT_DUTY_CYCLE, (uint64_t)nvm->MacGroup2.DutyCycleOn);

    /* Sensor Settings
     * --------------- */

    /* uint32_t: Time Base */
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_TIMEBASE, (uint64_t)DevCfg.sendInterval);

    /*     bool: Send Trigger */
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_SEND_TRIGGER, (uint64_t)DevCfg.sendTrigger);

    /*     bool: Send Strategy */
    size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_SEND_STRATEGY, (uint64_t)DevCfg.sendStrategy);

#if defined(STE)
    // STE has no configuration
#elif defined(STX)
    if(DevCfg.useSensor.hdc2080) switch(DevCfg.hdc2080_mode) {
    case HDC2080_TEMPERATURE_HIGH:
      /*  int32_t: Send LoRa Message on temperature upper threshold */
      size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_TEMPERATURE_UPPER_THRESHOLD, PBEncodeSInt(DevCfg.hdc2080_threshold));
      break;
    case HDC2080_TEMPERATURE_LOW:
      /*  int32_t: Send LoRa Message on temperature lower threshold */
      size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_TEMPERATURE_LOWER_THRESHOLD, PBEncodeSInt(DevCfg.hdc2080_threshold));
      break;
    case HDC2080_HUMIDITY_HIGH:
      /*  int32_t: Send LoRa Message on temperature upper threshold */
      size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_HUMIDITY_UPPER_THRESHOLD, DevCfg.hdc2080_threshold);
      break;
    case HDC2080_HUMIDITY_LOW:
      /*  int32_t: Send LoRa Message on temperature upper threshold */
      size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_HUMIDITY_LOWER_THRESHOLD, DevCfg.hdc2080_threshold);
      break;
    }

    if(DevCfg.useSensor.sfh7776) {
      /*  int32_t: Send LoRa Message on luminance upper threshold */
      size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_LUMINANCE_UPPER_THRESHOLD, (uint64_t)DevCfg.sfh7776_threshold_upper);

      /*  int32_t: Send LoRa Message on luminance lower threshold */
      size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_LUMINANCE_LOWER_THRESHOLD, (uint64_t)DevCfg.sfh7776_threshold_lower);
    }

    if(DevCfg.useSensor.bma400) {
      /*  int32_t: Send LoRa Message on axis acceleration above threshold */
      size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_AXIS_THRESHOLD, (uint64_t)DevCfg.bma400_threshold);

      /*  int32_t: Send LoRa Message on axis acceleration configure */
      size += PBEncodeMsgField(msg, len, size, PBMSG_BX_SENSOR_AXIS_CONFIGURE, (uint64_t)DevCfg.bma400_config);
    }

#endif
  }

  return size;
}

#if UNITTEST
static void Usage_PBEncodeSInt(void) {
	assert(0x0000000000000000 == PBEncodeSInt(0));
	assert(0x0000000000000001 == PBEncodeSInt(-1));
	assert(0x0000000000000002 == PBEncodeSInt(1));
	assert(0x0000000000000003 == PBEncodeSInt(-2));
	assert(0x0000000000000004 == PBEncodeSInt(2));
	assert(0xfffffffffffffffe == PBEncodeSInt(INT64_MAX));
	assert(0xffffffffffffffff == PBEncodeSInt(INT64_MIN));
}

static int Usage_PBEncodeField(void) {
  size_t r;
  uint8_t buf[256];

  /* varint * Shortest explicit key/value */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, sizeof buf, (uint32_t)1 << 3 | PB_TAGTYPE_VARINT, (uint64_t)0);
  assert(r == 2);
  assert(!memcmp(buf, (const uint8_t[]){0x08, 0x00}, 2));

  /* varint * Longest key/value */
  memset(buf, 0xbe, sizeof buf);

  r = PBEncodeField(buf, sizeof buf, (uint32_t)UINT32_MAX << 3 | PB_TAGTYPE_VARINT, (uint64_t)0x8877665544332211);
  assert(r == 15);
  assert(!memcmp(buf, (const uint8_t[]){0xf8, 0xff, 0xff, 0xff, 0x0f, 0x91, 0xc4, 0xcc, 0xa1, 0xd4, 0xca, 0xd9, 0xbb, 0x88, 0x01}, 15));

  /* varint * Lowest two-byte key/value */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, sizeof buf, (uint32_t)16 << 3 | PB_TAGTYPE_VARINT, (uint64_t)128);
  assert(r == 4);
  assert(!memcmp(buf, (const uint8_t[]){0x80, 0x01, 0x80, 0x01}, 4));

  /* varint * out of bounds */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, 7, (uint32_t)UINT32_MAX << 3 | PB_TAGTYPE_VARINT << 29, (uint64_t)0x8877665544332211);
  assert(r == 15);
  assert(!memcmp(buf, (const uint8_t[]){0xf8, 0xff, 0xff, 0xff, 0x0f, 0x91, 0xc4, 0xbe, 0xbe, 0xbe, 0xbe, 0xbe, 0xbe, 0xbe, 0xbe}, 15));

  /* bytes * explicit empty */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, sizeof buf, (uint32_t)2 << 3 | PB_TAGTYPE_BYTES, (size_t)0, (const unsigned char*)NULL);
  assert(r == 2);
  assert(!memcmp(buf, (const uint8_t[]){0x12, 0x00}, 2));

  /* bytes * clipped copy */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, 2, (uint32_t)2 << 3 | PB_TAGTYPE_BYTES, (size_t)1, (const unsigned char[]){0xaa});
  assert(r == 3);
  assert(!memcmp(buf, (const uint8_t[]){0x12, 0x01, 0xbe}, 3));

  /* bytes * quad null bytes */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, sizeof buf, (uint32_t)2 << 3 | PB_TAGTYPE_BYTES, (size_t)4, (const unsigned char[]){0x00, 0x00, 0x00, 0x00});
  assert(r == 6);
  assert(!memcmp(buf, (const uint8_t[]){0x12, 0x04, 0x00, 0x00, 0x00, 0x00}, 6));

  /* bytes * 128 bytes */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, sizeof buf, (uint32_t)2 << 3 | PB_TAGTYPE_BYTES, (size_t)128, (const unsigned char[]){
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
    0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f});
  assert(r == 131);
  assert(!memcmp(buf, (const uint8_t[]){0x12, 0x80, 0x01,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
    0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
    0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
    0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
    0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f}, 131));

  /* fixed32 * explicit zero */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, sizeof buf, (uint32_t)2 << 3 | PB_TAGTYPE_FIXED32, (uint32_t)0);
  assert(r == 5);
  assert(!memcmp(buf, (const uint8_t[]){0x15, 0x00, 0x00, 0x00, 0x00}, 5));

  /* fixed32 * little endian */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, sizeof buf, (uint32_t)2 << 3 | PB_TAGTYPE_FIXED32, (uint32_t)0x44332211);
  assert(r == 5);
  assert(!memcmp(buf, (const uint8_t[]){0x15, 0x11, 0x22, 0x33, 0x44}, 5));

  /* fixed64 * explicit zero */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, sizeof buf, (uint32_t)2 << 3 | PB_TAGTYPE_FIXED64, (uint64_t)0);
  assert(r == 9);
  assert(!memcmp(buf, (const uint8_t[]){0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, 9));

  /* fixed64 * null buffer */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(NULL, 0, (uint32_t)2 << 3 | PB_TAGTYPE_FIXED64, (uint64_t)0);
  assert(r == 9);
  assert(!memcmp(buf, (const uint8_t[]){0xbe, 0xbe, 0xbe, 0xbe, 0xbe, 0xbe, 0xbe, 0xbe, 0xbe}, 9));

  /* fixed64 * little endian */
  memset(buf, 0xbe, sizeof buf);
  r = PBEncodeField(buf, sizeof buf, (uint32_t)2 << 3 | PB_TAGTYPE_FIXED64, (uint64_t)0x8877665544332211);
  assert(r == 9);
  assert(!memcmp(buf, (const uint8_t[]){0x11, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88}, 9));

  return 1;
}

static int Usage_PBDecodeVarint(void) {
  uint8_t r;
  uint64_t v;
  const char *msg = "";

  v = 0, msg = "Ignore bits beyond maxbits";
  r = PBDecodeVarint((const uint8_t*)"\x7e", 1, &v);
  if(r != 1 || v != 0) goto err;

  v = 0, msg = "Only 2 low-order input bits examined";
  r = PBDecodeVarint((const uint8_t*)"\x7f", 2, &v);
  if(r != 1 || v != 3) goto err;

  v = 0, msg = "Stop at 1st byte due to continue bit clear";
  r = PBDecodeVarint((const uint8_t*)"\x7f\x00\x00\x00\x00\x00\x00\x00\x00\x00", 16, &v);
  if(r != 1 || v != 127) goto err;

  v = 0, msg = "Stop at 1st byte due to continue bit clear";
  r = PBDecodeVarint((const uint8_t*)"\x7f\x00\x00\x00\x00\x00\x00\x00\x00\x00", 64, &v);
  if(r != 1 || v != 127) goto err;

  v = 0, msg = "Continue till 2nd byte due to continue bit set";
  r = PBDecodeVarint((const uint8_t*)"\x80\x01\x00\x00\x00\x00\x00\x00\x00\x00", 64, &v);
  if(r != 2 || v != 128) goto err;

  v = 0, msg = "10th byte continue bit being set is invalid. Note, Partial output was still made.";
  r = PBDecodeVarint((const uint8_t*)"\x81\x80\x80\x80\x80\x80\x80\x80\x80\x8e", 64, &v);
  if(r != 0 || v != 1) goto err;

  v = 0, msg = "Wide varint can also be interpreted";
  r = PBDecodeVarint((const uint8_t*)"\x81\x80\x80\x80\x80\x80\x80\x80\x80\x00", 64, &v);
  if(r != 10 || v != 1) goto err;

  v = 0, msg = "Wide varint can also be interpreted, if enough input bytes are allowed";
  r = PBDecodeVarint((const uint8_t*)"\x81\x80\x80\x80\x80\x80\x80\x80\x80\x00", 7, &v);
  if(r != 0 || v != 1) goto err;

  v = 0, msg = "Largest value";
  r = PBDecodeVarint((const uint8_t*)"\xff\xff\xff\xff\xff\xff\xff\xff\xff\x01", 64, &v);
  if(r != 10 || v != UINT64_MAX) goto err;

  return 1;
err:
  DBG_PRINTF("r:%d, v:0x%016" PRIx64 ", msg:\42%s\42\n", r, (uint64_t)v, msg);
  return 0;
}

static int Usage_PBEncodeMsg(void) {
  uint8_t msg[256];

  /* pw_valid == false */
  for(size_t len, s = 0; s != sizeof msg; s++) {
    memset(msg, 0xbe, sizeof msg);
    len = PBEncodeMsg_DeviceConfiguration(msg, sizeof msg, false);
    assert(len == 3);
    assert(!memcmp(msg, (const uint8_t[]){0x00, 0x08, 0x02}, s < 3 ? s : 3));
  }

  /* pw_valid == true */
  for(size_t len, s = 0; s != sizeof msg; s++) {
    memset(msg, 0xbe, sizeof msg);
    len = PBEncodeMsg_DeviceConfiguration(msg, sizeof msg, true);
    assert(len == 138);
    assert(!memcmp(msg, (const uint8_t[]){
      0x00, 0x08, 0x02, 0x18, 0x01, 0x21, 0x64, 0x65, 0x76, 0x69, 0x63, 0x65, 0x30,
      0x32, 0x29, 0x70, 0xb3, 0xd5, 0x7e, 0xf0, 0x00, 0x51, 0x2f, 0x32, 0x10, 0x81,
      0xff, 0x80, 0xde, 0x5e, 0x8f, 0x5c, 0x8e, 0x50, 0x84, 0x32, 0x24, 0xff, 0x29,
      0x2c, 0x42, 0x3d, 0x77, 0x2a, 0x01, 0x26, 0x42, 0x10, 0x9c, 0x1e, 0xda, 0xe8,
      0x57, 0x2c, 0xa0, 0x7f, 0x5f, 0x7e, 0x7b, 0x11, 0x3c, 0xd4, 0xf1, 0x50, 0x4a,
      0x10, 0x77, 0x9b, 0x7f, 0xfc, 0xe1, 0x0c, 0xd2, 0xa4, 0x9d, 0x05, 0xb5, 0xf5,
      0x8e, 0xea, 0xa1, 0x7b, 0x50, 0x00, 0x58, 0x01, 0x60, 0x03, 0x68, 0x05, 0x70,
      0x09, 0x78, 0x01, 0x80, 0x01, 0x01, 0x88, 0x01, 0x01, 0x90, 0x01, 0x01, 0x98,
      0x01, 0xe0, 0xa8, 0x01, 0xa0, 0x01, 0x01, 0xa8, 0x01, 0x01, 0xb0, 0x01, 0xcf,
      0x0f, 0xb8, 0x01, 0xdd, 0x22, 0xc0, 0x01, 0xc8, 0x01, 0xc8, 0x01, 0x64, 0xd0,
      0x01, 0x64, 0xd8, 0x01, 0x64, 0xe0, 0x01, 0x64}, s < 138 ? s : 138));
  }

  /* pw_valid == false */
  for(size_t len, s = 0; s != sizeof msg; s++) {
    memset(msg, 0xbe, sizeof msg);
    len = PBEncodeMsg_DeviceSensors(msg, sizeof msg, true);
    assert(len == 34);
    assert(!memcmp(msg, (const uint8_t[]){
      0x01, 0x08, 0x02, 0x10, 0xe4, 0x01, 0x18, 0xdd, 0x22, 0x20, 0x80, 0xf1,
      0x04, 0x28, 0xf4, 0x03, 0x30, 0x64, 0x38, 0xc8, 0x01, 0x40, 0x0e, 0x48,
      0x10, 0x50, 0xb6, 0x0f, 0x58, 0x01, 0x60, 0x02, 0x68, 0x03}, s < 34 ? s : 34));
  }

  return 0;
}

static int Usage_PBDecodeMsg(void) {
  const uint8_t emptymsg[] = {0};
  const uint8_t badvermsg[] = {0x01, 0xff, 0xaa};
  const uint8_t validmsg[] = {0x00, 0x29, 0x64, 0x65, 0x76, 0x69, 0x63, 0x65, 0x30, 0x32, 0x31, 0x70, 0xb3, 0xd5, 0x7e, 0xf0, 0x00, 0x51, 0x2f, 0x3a, 0x10, 0x81, 0xff, 0x80, 0xde, 0x5e, 0x8f, 0x5c, 0x8e, 0x50, 0x84, 0x32, 0x24, 0xff, 0x29, 0x2c, 0x42, 0x45, 0x77, 0x2a, 0x01, 0x26, 0x08, 0x01, 0x19, 0xa0, 0xb1, 0xc2, 0xd3, 0xe4, 0xf5, 0xa6, 0xb7, 0x20, 0x80, 0x01, 0x58, 0x00, 0x52, 0x10, 0x77, 0x9b, 0x7f, 0xfc, 0xe1, 0x0c, 0xd2, 0xa4, 0x9d, 0x05, 0xb5, 0xf5, 0x8e, 0xea, 0xa1, 0x7b, 0x4a, 0x10, 0x9c, 0x1e, 0xda, 0xe8, 0x57, 0x2c, 0xa0, 0x7f, 0x5f, 0x7e, 0x7b, 0x11, 0x3c, 0xd4, 0xf1, 0x50};

  /* No message, complain how can't recognize msg format. */
  printf("\nmain()::nomsg[0] is %p sizeof %zu\n", NULL, (size_t)0);
  PBDecodeMsg(NULL, 0);

  /* Empty message, as of yet all fields being implicit is too exotic. */
  printf("\nmain()::emptymsg[] is %p sizeof %zu\n", emptymsg, sizeof emptymsg);
  PBDecodeMsg(emptymsg, sizeof(emptymsg));

  /* Wrong version message */
  printf("\nmain()::badvermsg[] is %p sizeof %zu\n", badvermsg, sizeof badvermsg);
  PBDecodeMsg(badvermsg, sizeof(badvermsg));

  /* Valid message, should describe each field. */
  printf("\nmain()::validmsg[] is %p sizeof %zu\n", validmsg, sizeof validmsg);
  PBDecodeMsg(validmsg, sizeof(validmsg));
}

int main(void) {
  Usage_PBEncodeSInt();
  Usage_PBEncodeField();
  Usage_PBDecodeVarint();
  Usage_PBEncodeMsg();
  Usage_PBDecodeMsg();
  return EXIT_SUCCESS;
}
#endif
