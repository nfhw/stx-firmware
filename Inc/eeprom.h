/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __EEPROM_H
#define __EEPROM_H
#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "LoRaMac.h"
#include "sensors.h"

/* Exported types ------------------------------------------------------------*/
/*
 * DESCRIPTION
 *    Nvm holds state, why duplicate it?
 *        a. LoRaMac-node may be busy at the time of NFC event, so need to stash
 *           data and defer to main ctx to apply on Nvm. This lets us stash it.
 *        b. Changing region requires invalidating Nvm. This allows us to restore
 *           Nvm with user configs.
 *
 *    Nvm holds state in EEPROM, why duplicate it?
 *        a. Nvm is 3rd party data structure and may change.
 *        b. Protobuf enables fw updates without losing device configs.
 *
 *    LoRaWAN 1.0.x & 1.1.x renaming
 *        AppKey:  NWK_KEY         # Network root key                         # FOR 1.0.x DEVICES IT IS THE LORAWAN_APP_KEY
 *        AppSKey: APP_S_KEY       # Application session key
 *        NwkSKey: F_NWK_S_INT_KEY # Forwarding Network session integrity key # NWK_S_KEY FOR 1.0.x DEVICES
 *        N/A:     S_NWK_S_INT_KEY # Serving Network session integrity key    # NOT USED FOR 1.0.x DEVICES. MUST BE THE SAME AS LORAWAN_F_NWK_S_INT_KEY
 *        N/A:     NWK_S_ENC_KEY   # Network session encryption key           # NOT USED FOR 1.0.x DEVICES. MUST BE THE SAME AS LORAWAN_F_NWK_S_INT_KEY
 */
struct DeviceConfig {
  struct {
    unsigned any     :1;
    unsigned lrw     :1;
    unsigned bma400  :1;
    unsigned hdc2080 :1;
    unsigned sfh7776 :1;
    unsigned resched :1;
  } changed;

  /*******************************************/
  /*               LoRaMac-node              */
  /*******************************************/
  bool                    isOtaa;            // rwr-  5:     bool  (TTN) Activation Method    // Nvm.MacGroup2.NetworkActivation
  uint8_t                 devEui[8];         // rwr-  6:  char[8]  (TTN) Device EUI           // Nvm.SecureElement.DevEui
  uint8_t                 appEui[8];         // rwr-  7:  char[8]  (TTN) Application EUI      // Nvm.SecureElement.JoinEui
  uint8_t                 appKey[16];        // rw--  8: char[16]  (TTN) App Key              // Nvm.SecureElement.KeyList[APP_KEY].KeyValue
  uint32_t                devAddr;           // rwr-  9: uint32_t  (TTN) Device Address       // Nvm.MacGroup2.DevAddr
  uint8_t                 nwkSKey[16];       // rw-- 10: char[16]  (TTN) Network Session Key  // Nvm.SecureElement.KeyList[F_NWK_S_INT_KEY].KeyValue
  uint8_t                 appSKey[16];       // rw-- 11: char[16]  (TTN) App Session Key      // Nvm.SecureElement.KeyList[APP_S_KEY].KeyValue
  LoRaMacRegion_t         region;            // rwr- 13:  uint8_t  LoRa Frequency Plan        // Nvm.MacGroup2.Region = LORAMAC_REGION_EU868
  uint8_t                 txPort;            // rwr- 14:  uint8_t  LoRa Port                  // N/A
  uint8_t                 txPower;           // rwr- 15:  uint8_t  LoRa Transmit Power        // Nvm.MacGroup1.ChannelsTxPower
  uint8_t                 sf;                // rwr- 16:  uint8_t  LoRa Spreading Factor      // Nvm.MacGroup1.ChannelsDatarate
  uint8_t                 bw;                // rwr- 17:  uint8_t  LoRa Bandwidth             // Nvm.MacGroup1.ChannelsDatarate
  bool                    confirmedMsgs;     // rwr- 18:     bool  LoRa Confirmed Messages    // N/A
  bool                    adaptiveDatarate;  // rwr- 19:     bool  LoRa Adaptive Data Rate    // Nvm.MacGroup2.AdrCtrlOn
  bool                    dutyCycle;         // rwr- 20:     bool  LoRa Respect Duty Cycle    // Nvm.MacGroup2.DutyCycleOn

                                             // rwr- 12:     bool  LoRa Join status           // Nvm.MacGroup2.NetworkActivation

  /*******************************************/
  /*              Send Strategy              */
  /*******************************************/
  uint32_t                sendInterval;            // rw-- 21: uint32_t  Send interval of LoRa Messages
  enum Send_Trigger       sendTrigger;             // rw-- 22: uint32_t  Send Trigger
  enum Send_Strategy      sendStrategy;            // rw-- 23: uint32_t  Send Strategy

#if defined(STX)
  /*******************************************/
  /*             STX Multi Sensor            */
  /*******************************************/
  enum HDC2080_Threshold  hdc2080_mode;            // rw-- 24:  int32_t  Send LoRa Message on humidity upper threshold
                                                   // rw-- 25:  int32_t  Send LoRa Message on humidity lower threshold
                                                   // rw-- 26:  int32_t  Send LoRa Message on temperature upper threshold
                                                   // rw-- 27:  int32_t  Send LoRa Message on temperature lower threshold
  int32_t                 hdc2080_threshold;       // case humidity:    n / 1000 = 5 %rH
                                                   // case temperature: n /  100 = -22.23 C
  uint32_t                bma400_threshold;        // rw-- 30: uint32_t  Send LoRa Message on axis acceleration above threshold
  uint16_t                bma400_config;           // rw-- 31: uint16_t  Send LoRa Message on axis acceleration configuration
  uint16_t                sfh7776_threshold_upper; // rw-- 28: uint16_t  Send LoRa Message on luminance upper threshold
  uint16_t                sfh7776_threshold_lower; // rw-- 29: uint16_t  Send LoRa Message on luminance lower threshold
  struct {
    unsigned bma400  :1;
    unsigned sfh7776 :1;
    unsigned hdc2080 :1;
  } useSensor;

#elif defined(STA)
  /*******************************************/
  /*            STA Action Button            */
  /*******************************************/
  uint8_t                 singleCount;
  uint8_t                 doubleCount;
  uint8_t                 longCount;
#endif
};


/* Exported constants --------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
extern struct DeviceConfig DevCfg;

/* Exported macros -----------------------------------------------------------*/
#define DEVCFG_SET(d, v) \
  ((d) != (v) && ((d) = (v), DevCfg.changed.any = true, 1))
#define DEVCFG_MEMCPY(d, v, s) \
  (memcmp((d), (v), (s)) && (memcpy((d), (v), (s)), DevCfg.changed.any = true, 1))

/* Exported functions ------------------------------------------------------- */
void EEPROM_Save(void);
void EEPROM_Load(void);
uint32_t EEPROM_CRC(const uint8_t *buf, size_t size);


#ifdef __cplusplus
}
#endif
#endif /* __EEPROM_H */
