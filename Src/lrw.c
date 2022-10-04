/* Includes ------------------------------------------------------------------*/
#include "lrw.h"
#include "protobuf.h"                    // PBENUM_BW_125
#include "hardware.h"                    // DEBUG_MSG
#include "eeprom.h"                      // DevCfg
#include "sensors.h"                     // bma400 sfh7776 hdc2080
#include "LoRaMac-node/common/NvmDataMgmt.h"          // NvmDataMgmtEvent
#include "LoRaMac-node/mac/region/RegionEU868.h"      // EU868_MIN_TX_POWER
#include "LoRaMac-node/mac/region/RegionUS915.h"      // US915_MIN_TX_POWER
#include "LoRaMac-node/common/Commissioning.h"        // OVER_THE_AIR_ACTIVATION
#include "LoRaMac-node/common/LmHandlerMsgDisplay.h"  // Display*
#include "LoRaMac-node/boards/sx126x-board.h"         // SX126x
#include "LoRaMac-node/mac/LoRaMacTest.h"             // LoRaMacTestSetDutyCycleOn
#include <string.h>  // memcpy memcmp

#include "common/LmHandler/LmHandler.h"  // LmHandlerCallbacks_t
#include "boards/board.h"                // BoardGetRandomSeed


/* External variables --------------------------------------------------------*/
/* Private typedef -----------------------------------------------------------*/
/* Private defines -----------------------------------------------------------*/
/* Private macros ------------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
static void OnMacProcessNotify(void);
static void OnNvmDataChange(LmHandlerNvmContextStates_t state, uint16_t size);
static void OnMacMcpsRequest(LoRaMacStatus_t status, McpsReq_t *mcpsReq, TimerTime_t nextTxIn);
static void OnMacMlmeRequest(LoRaMacStatus_t status, MlmeReq_t *mlmeReq, TimerTime_t nextTxIn);

static void McpsConfirm(McpsConfirm_t *mcpsConfirm);
static void McpsIndication(McpsIndication_t *mcpsIndication);
static void MlmeConfirm(MlmeConfirm_t *mlmeConfirm);
static void MlmeIndication(MlmeIndication_t *mlmeIndication);

static void LRW_SaveNvm(uint16_t notifyFlags);

/* Global variables ----------------------------------------------------------*/
static bool IsUplinkTxPending = false;
TimerTime_t DutyCycleWaitTime = 0;
static LoRaMacPrimitives_t LoRaMacPrimitives = {
  .MacMcpsConfirm = McpsConfirm,
  .MacMcpsIndication = McpsIndication,
  .MacMlmeConfirm = MlmeConfirm,
  .MacMlmeIndication = MlmeIndication,
};
static LoRaMacCallback_t LoRaMacCallbacks = {
  .GetBatteryLevel = NULL,
  .GetTemperatureLevel = NULL,
  .NvmDataChange = LRW_SaveNvm,
  .MacProcessNotify = OnMacProcessNotify,
};
static CommissioningParams_t CommissioningParams = {
  .IsOtaaActivation = OVER_THE_AIR_ACTIVATION,
  .DevEui = {0},   // Automatically filled from secure-element
  .JoinEui = {0},  // Automatically filled from secure-element
  .SePin = {0},    // Automatically filled from secure-element
  .NetworkId = LORAWAN_NETWORK_ID,
  .DevAddr = LORAWAN_DEVICE_ADDRESS,
};
static LmHandlerJoinParams_t JoinParams = {
  .CommissioningParams = &CommissioningParams,
  .Datarate = DR_0,
  .Status = LORAMAC_HANDLER_ERROR,
};
static LmHandlerTxParams_t TxParams = {
  .CommissioningParams = &CommissioningParams,
  .MsgType = LORAMAC_HANDLER_UNCONFIRMED_MSG,
  .AckReceived = 0,
  .Datarate = DR_0,
  .UplinkCounter = 0,
  .AppData = {
    .Port = 0,
    .BufferSize = 0,
    .Buffer = NULL,
  },
  .TxPower = TX_POWER_0,
  .Channel = 0,
};
static LmHandlerRxParams_t RxParams = {
  .CommissioningParams = &CommissioningParams,
  .Rssi = 0,
  .Snr = 0,
  .DownlinkCounter = 0,
  .RxSlot = -1,
};
LoRaMacNvmData_t *pNvm;

/* Public functions ----------------------------------------------------------*/
/* DESCRIPTION
 *        Takes spreading factor and bandwidth as interpreted by protobuf, and
 *        spits out a datarate.
 *
 * RETURN VALUE
 *        LoRaMAC-node region specific datarate.
 */
uint8_t LRW_ToDatarate(uint8_t sf, uint8_t bw) {
  LoRaMacRegion_t region = pNvm->MacGroup2.Region;
  return
      /* US915 */
      region == LORAMAC_REGION_US915 && bw == PBENUM_BW_500 /* sf =  8 */ ? DR_4 : // Max Payload: 242
      region == LORAMAC_REGION_US915 && bw == PBENUM_BW_125 && sf <= 7    ? DR_3 : // Max Payload: 242
      region == LORAMAC_REGION_US915 && bw == PBENUM_BW_125 && sf == 8    ? DR_2 : // Max Payload: 125
      region == LORAMAC_REGION_US915 && bw == PBENUM_BW_125 && sf == 9    ? DR_1 : // Max Payload:  53
      region == LORAMAC_REGION_US915 && bw == PBENUM_BW_125 && sf >= 10   ? DR_0 : // Max Payload:  11
      /* EU868 */
      region == LORAMAC_REGION_EU868 && bw == PBENUM_BW_250 /* sf =  7 */ ? DR_6 : // Max Payload: 242
      region == LORAMAC_REGION_EU868 && bw == PBENUM_BW_125 && sf <= 7    ? DR_5 : // Max Payload: 242
      region == LORAMAC_REGION_EU868 && bw == PBENUM_BW_125 && sf == 8    ? DR_4 : // Max Payload: 242
      region == LORAMAC_REGION_EU868 && bw == PBENUM_BW_125 && sf == 9    ? DR_3 : // Max Payload: 115
      region == LORAMAC_REGION_EU868 && bw == PBENUM_BW_125 && sf == 10   ? DR_2 : // Max Payload:  51
      region == LORAMAC_REGION_EU868 && bw == PBENUM_BW_125 && sf == 11   ? DR_1 : // Max Payload:  51
      region == LORAMAC_REGION_EU868 && bw == PBENUM_BW_125 && sf == 12   ? DR_0 : // Max Payload:  51
      /* Default */
      (DBG_PRINTF("LRW ERR Bad Value!\n"), DR_0);
}

/* DESCRIPTION
 *        Takes Radio physical dBm:       14 dBm
 *        Returns LoRaMac-node enum tx power: TX_POWER_0
 */
uint8_t LRW_ToTxPower(uint8_t dbm) {
  LoRaMacRegion_t region = pNvm->MacGroup2.Region;
  dbm =
    /* EU868 */
    region == LORAMAC_REGION_EU868 && dbm >= 14 ?  14 : // TX_POWER_0  EU868_MAX_TX_POWER EU868_DEFAULT_TX_POWER EU868_DEFAULT_MAX_EIRP
    region == LORAMAC_REGION_EU868 && dbm <=  0 ?   0 : // TX_POWER_7  EU868_MIN_TX_POWER
    region == LORAMAC_REGION_EU868              ? dbm :
    /* US915 */
    region == LORAMAC_REGION_US915 && dbm >= 30 ?  30 : // TX_POWER_0  US915_MAX_TX_POWER US915_DEFAULT_TX_POWER US915_DEFAULT_MAX_EIRP
    region == LORAMAC_REGION_US915 && dbm <=  2 ?   2 : // TX_POWER_14 US915_MIN_TX_POWER
    region == LORAMAC_REGION_US915              ? dbm :
    (DBG_PRINTF("LRW ERR Bad Value!\n"), 2);

  // round up modulo 2
  dbm = (dbm / 2 + dbm % 2) * 2;

  return
    region == LORAMAC_REGION_EU868 ? (    EU868_MIN_TX_POWER * 2 - dbm) / 2 :
    region == LORAMAC_REGION_US915 ? (2 + US915_MIN_TX_POWER * 2 - dbm) / 2 :
    (DBG_PRINTF("LRW ERR Bad Value!\n"), TX_POWER_0);
}

/* DESCRIPTION
 *        Takes LoRaMac-node enum tx power: TX_POWER_0
 *        Returns Radio physical dBm:       14 dBm
 *
 *    Formula
 *        int RegionCommonComputeTxPower(int txPowerIndex = 0, float maxEirp = 16, float antennaGain = 2):
 *            return floor(maxEirp - txPowerIndex * 2U - antennaGain);
 */
uint8_t LRW_FromTxPower(uint8_t txp) {
  LoRaMacRegion_t region = pNvm->MacGroup2.Region;

  return
      region == LORAMAC_REGION_EU868 ? 14 - txp * 2 :
      region == LORAMAC_REGION_US915 ? 30 - txp * 2 :
      (DBG_PRINTF("LRW ERR Bad Value!"), 2);
}


/* DESCRIPTION
 *    Init
 *        DevCfg = STATIC HARDCODED DEFAULTS;
 *        if(EEPROM)
 *          DevCfg = EEPROM;
 *        EEPROM = DevCfg;
 *
 *        Nvm = RUNTIME HARDCODED DEFAULTS;
 *        if(NVM)
 *          Nvm = NVM;
 *
 *        if(Nvm != DevCfg) NVM = Nvm = DevCfg;
 *    Set (NFC)
 *        if(Nvm != DevCfg) NVM = Nvm = EEPROM = DevCfg;
 *    Set (LRW)
 *        if(Nvm != DevCfg) EEPROM = DevCfg = NVM = Nvm;
 *
 *    Remarks
 *        DevCfg in EEPROM may be abridged (e.g. due fw update). Thus we write
 *        EEPROM even if we had just loaded it.
 *
 *        LoRaMac-node may desync Nvm from DevCfg (e.g. nwkSKey/appSKey due
 *        JoinAccept; sf/bw/txPower due ADR). We fix DevCfg once Nvm is being
 *        written to EEPROM.
 *
 *        DevCfg must be in sync, otherwise NFC may undo LRW changes.
 *        As such synchronization is bidirectional.
 *
 *    Terminology
 *        MCPS (MAC Common Part Sublayer)
 *            Actual data rx/tx.
 *        MLME (MAC Layer Management Entity)
 *            Initiating a JoinRequest.
 *        MIB (Mac Information Base)
 *            Setting/Getting DevEui.
 *        MIC (Message Integrity Check)
 *            Four bytes within packet after payload.
 *
 *        LoRaMac-node     End-User
 *        ------------     --------
 *        Indication   --> Response
 *        Confirm      <-- Request
 *
 * SEE ALSO
 *    https://stackforce.github.io/LoRaMac-doc/LoRaMac-doc-v4.5.2/index.html
 *        Basic overview of LoRaMac-node architecture.
 *    LmHandlerInit
 *        Example function being paralleled.
 */

void LRW_Init(void) {
  MibRequestConfirm_t mibReq;
  size_t nvmBytes;

  // Plug SX1261 Pins
  SX126x.Spi.Mosi.pin = PA_7;
  SX126x.Spi.Mosi.pinIndex = 0x0080;
  SX126x.Spi.Mosi.port = GPIOA;
  SX126x.Spi.Miso.pin = PA_6;
  SX126x.Spi.Miso.pinIndex = 0x0040;
  SX126x.Spi.Miso.port = GPIOA;
  SX126x.Spi.Sclk.pin = PA_5;
  SX126x.Spi.Sclk.pinIndex = 0x0020;
  SX126x.Spi.Sclk.port = GPIOA;
  SX126x.Spi.Nss.pin = PA_4;
  SX126x.Spi.Nss.pinIndex = 0x0010;
  SX126x.Spi.Nss.port = GPIOA;
  SX126x.DIO1.pin = PB_5;
  SX126x.DIO1.pinIndex = 0x0020;
  SX126x.DIO1.port = GPIOB;
  SX126x.DIO3.pin = PA_12;
  SX126x.DIO3.pinIndex = 0x1000;
  SX126x.DIO3.port = GPIOA;
  SX126x.Reset.pin = PB_4;
  SX126x.Reset.pinIndex = 0x0010;
  SX126x.Reset.port = GPIOB;
  SX126x.BUSY.pin = PA_11;
  SX126x.BUSY.pinIndex = 0x0800;
  SX126x.BUSY.port = GPIOA;
  SX126x.BUSY.pull = PIN_PULL_UP;

  IsUplinkTxPending = false;

  if(LoRaMacInitialization(&LoRaMacPrimitives, &LoRaMacCallbacks, DevCfg.region) != LORAMAC_STATUS_OK)
    DBG_PRINTF("LRW Init Failed! %d\n", __LINE__);

  // We simply need raw access to Nvm to function properly.
  mibReq.Type = MIB_NVM_CTXS;
  LoRaMacMibGetRequestConfirm(&mibReq);
  pNvm = mibReq.Param.Contexts;

  if((nvmBytes = NvmDataMgmtRestore())) {
    OnNvmDataChange(LORAMAC_HANDLER_NVM_RESTORE, nvmBytes);
  }

  LRW_FromDevCfg();

  // Read secure-element DEV_EUI, JOIN_EUI and SE_PIN values.
  mibReq.Type = MIB_DEV_EUI;
  LoRaMacMibGetRequestConfirm(&mibReq);
  memcpy(CommissioningParams.DevEui, mibReq.Param.DevEui, 8);

  mibReq.Type = MIB_JOIN_EUI;
  LoRaMacMibGetRequestConfirm(&mibReq);
  memcpy1(CommissioningParams.JoinEui, mibReq.Param.JoinEui, 8);

  mibReq.Type = MIB_SE_PIN;
  LoRaMacMibGetRequestConfirm(&mibReq);
  memcpy(CommissioningParams.SePin, mibReq.Param.SePin, 4);

  mibReq.Type = MIB_PUBLIC_NETWORK;
  mibReq.Param.EnablePublicNetwork = true;
  LoRaMacMibSetRequestConfirm(&mibReq);

  // Set system maximum tolerated rx error in milliseconds
  mibReq.Type = MIB_SYSTEM_MAX_RX_ERROR;
  mibReq.Param.SystemMaxRxError = 100;
  LoRaMacMibSetRequestConfirm(&mibReq);

  LoRaMacStart();
}

/*
 * SEE ALSO
 *    LmHandlerJoinRequest
 *        Example function being paralleled.
 */
void LRW_Join(void) {
  MlmeReq_t mlmeReq;

  mlmeReq.Type = MLME_JOIN;
  mlmeReq.Req.Join.Datarate = LRW_ToDatarate(DevCfg.sf, DevCfg.bw);
  mlmeReq.Req.Join.NetworkActivation = DevCfg.isOtaa ? ACTIVATION_TYPE_OTAA : ACTIVATION_TYPE_ABP;
  CommissioningParams.IsOtaaActivation = DevCfg.isOtaa;

  // Starts the join procedure
  OnMacMlmeRequest(LoRaMacMlmeRequest(&mlmeReq), &mlmeReq, mlmeReq.ReqReturn.DutyCycleWaitTime);
  DutyCycleWaitTime = mlmeReq.ReqReturn.DutyCycleWaitTime;
}

bool LRW_IsJoined(void) {
  MibRequestConfirm_t mibReq = {.Type = MIB_NETWORK_ACTIVATION};

  return LoRaMacMibGetRequestConfirm(&mibReq) != LORAMAC_STATUS_OK ||
      mibReq.Param.NetworkActivation == ACTIVATION_TYPE_NONE ? false : true;
}

/*
 * SEE ALSO
 *    LmHandlerSend
 *        Example function being paralleled.
 */
void LRW_TX(LmHandlerAppData_t *appData) {
  McpsReq_t mcpsReq;
  LoRaMacTxInfo_t txInfo;

  if(!LRW_IsJoined()) {
    DEBUG_MSG("LRW ERR Can't send if not joined.\n");
  }

  TxParams.MsgType = DevCfg.confirmedMsgs ? LORAMAC_HANDLER_CONFIRMED_MSG : LORAMAC_HANDLER_UNCONFIRMED_MSG;
  mcpsReq.Type = DevCfg.confirmedMsgs ? MCPS_CONFIRMED : MCPS_UNCONFIRMED;
  mcpsReq.Req.Unconfirmed.Datarate = LRW_ToDatarate(DevCfg.sf, DevCfg.bw);
  if(LoRaMacQueryTxPossible(appData->BufferSize, &txInfo) != LORAMAC_STATUS_OK) {
    // Send empty frame in order to flush MAC commands
    mcpsReq.Type = MCPS_UNCONFIRMED;
    mcpsReq.Req.Unconfirmed.fBuffer = NULL;
    mcpsReq.Req.Unconfirmed.fBufferSize = 0;
  } else {
    mcpsReq.Req.Unconfirmed.fPort = appData->Port;
    mcpsReq.Req.Unconfirmed.fBufferSize = appData->BufferSize;
    mcpsReq.Req.Unconfirmed.fBuffer = appData->Buffer;
  }

  TxParams.AppData = *appData;
  TxParams.Datarate = LRW_ToDatarate(DevCfg.sf, DevCfg.bw);

  LoRaMacStatus_t status = LoRaMacMcpsRequest(&mcpsReq);
  OnMacMcpsRequest(status, &mcpsReq, mcpsReq.ReqReturn.DutyCycleWaitTime);
  DutyCycleWaitTime = mcpsReq.ReqReturn.DutyCycleWaitTime;

  if(status == LORAMAC_STATUS_OK) {
    IsUplinkTxPending = false;
  }

#ifdef EEDBGLOG
  {
    uint32_t sended = *(volatile uint32_t*)EEPROM_LOG_SENDED;
    HW_EraseEEPROM(EEPROM_LOG_SENDED);
    HW_ProgramEEPROM(EEPROM_LOG_SENDED, sended + 1);
  }
#endif
}

static volatile uint8_t IsMacProcessPending = 0;
static volatile uint8_t IsTxFramePending = 0;
struct LRW_Handle lrw = {0};

/* NAME
 *        LRW_Process - Process the LoRaMac events
 */
void LRW_Process(void) {
  size_t nvmBytes;

  // Process Radio IRQ
  Radio.IrqProcess && (Radio.IrqProcess(), 0);

  // Processes the LoRaMac events
  LoRaMacProcess();

  // Save Nvm changes to EEPROM
  (nvmBytes = NvmDataMgmtStore()) && (OnNvmDataChange(LORAMAC_HANDLER_NVM_STORE, nvmBytes), 0);
}

static void LRW_SaveNvm(uint16_t notifyFlags) {
  NvmDataMgmtEvent(notifyFlags);
  if(!DevCfg.changed.lrw) {
    LRW_ToDevCfg();
    EEPROM_Save();
  }
}

/* DESCRIPTION
 *        In response to NFC changes.
 */
void LRW_FromDevCfg(void) {
  MibRequestConfirm_t mibReq;
  uint8_t dr = LRW_ToDatarate(DevCfg.sf, DevCfg.bw);
  uint8_t txp = LRW_ToTxPower(DevCfg.txPower);
  bool rejoin = false;

  /* Region
   * ------
   * LoRaMacInitialization is the only way of changing region.
   * And it resets much of Nvm to defaults. Thus this must happen first.
   * And state recovered from DevCfg.
   */
  if(DevCfg.region != pNvm->MacGroup2.Region) {
    if(LoRaMacInitialization(&LoRaMacPrimitives, &LoRaMacCallbacks, DevCfg.region) != LORAMAC_STATUS_OK)
      DBG_PRINTF("LRW Init Failed! %d\n", __LINE__);
  }

  /* Device Extended Unique Identifier
   * ---------------------------------
   * Identifes this device to the application.
   */
  mibReq.Type = MIB_DEV_EUI;
  LoRaMacMibGetRequestConfirm(&mibReq);
  if(!memcmp(DevCfg.devEui, (uint8_t[sizeof DevCfg.devEui]){0}, sizeof DevCfg.devEui)) {
    BoardGetUniqueId(DevCfg.devEui);
  }
  if(memcmp(mibReq.Param.DevEui, DevCfg.devEui, sizeof DevCfg.devEui)) {
    mibReq.Param.DevEui = DevCfg.devEui;
    LoRaMacMibSetRequestConfirm(&mibReq);
    rejoin = true;
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }

  /* Application Extended Unique Identifier
   * --------------------------------------
   * Identifies the Internet application to connect to.
   */
  mibReq.Type = MIB_JOIN_EUI;
  LoRaMacMibGetRequestConfirm(&mibReq);
  if(memcmp(mibReq.Param.JoinEui, DevCfg.appEui, sizeof DevCfg.appEui)) {
    mibReq.Param.JoinEui = DevCfg.appEui;
    LoRaMacMibSetRequestConfirm(&mibReq);
    rejoin = true;
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }

  /* Application Key
   * ---------------
   * Password used to encrypt data between app and device.
   */
  /* LORAWAN_APP_KEY was renamed to LORAWAN_NWK_KEY, see se-identify.h */
  if(memcmp(pNvm->SecureElement.KeyList[NWK_KEY].KeyValue, DevCfg.appKey, sizeof DevCfg.appKey)) {
    mibReq.Type = MIB_NWK_KEY;
    mibReq.Param.NwkKey = DevCfg.appKey;
    LoRaMacMibSetRequestConfirm(&mibReq);
    rejoin = true;
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }

  /* APB or OTAA
   * -----------
   * LoRaMacMibSetRequestConfirm can only set APB or Unjoined OTAA. So if Joined AND OTAA, do nothing.
   *
   * | Current | Setting | Becomes |
   * |---------|---------|---------|
   * | OTAA    | APB     | APB     | APB is always joined.
   * | OTAA    | OTAA    | OTAA    | OTAA means OTAA after JoinAccept. Meaning we do nothing.
   * | APB     | OTAA    | NONE    | NONE means OTAA prior JoinAccept. Meaning we unjoin the device.
   * | APB     | APB     | APB     |
   */
  mibReq.Type = MIB_NETWORK_ACTIVATION;
  LoRaMacMibGetRequestConfirm(&mibReq);
  if(DevCfg.isOtaa != (mibReq.Param.NetworkActivation != ACTIVATION_TYPE_ABP) || rejoin) {
    if(!DevCfg.isOtaa) {
      mibReq.Type = MIB_ABP_LORAWAN_VERSION;
      mibReq.Param.AbpLrWanVersion.Value = ABP_ACTIVATION_LRWAN_VERSION;
      LoRaMacMibSetRequestConfirm(&mibReq);

      mibReq.Type = MIB_NET_ID;
      mibReq.Param.NetID = LORAWAN_NETWORK_ID;
      LoRaMacMibSetRequestConfirm(&mibReq);
    }
    mibReq.Type = MIB_NETWORK_ACTIVATION;
    mibReq.Param.NetworkActivation = DevCfg.isOtaa ? ACTIVATION_TYPE_NONE : ACTIVATION_TYPE_ABP;
    LoRaMacMibSetRequestConfirm(&mibReq);
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }

  /* Datarate from SF and BW
   * -----------------------
   * Affects air time, and thus payload size and duty cycle.
   */
  mibReq.Type = MIB_CHANNELS_DATARATE;
  LoRaMacMibGetRequestConfirm(&mibReq);
  if(mibReq.Param.ChannelsDatarate != dr) {
    mibReq.Type = MIB_CHANNELS_DEFAULT_DATARATE;
    mibReq.Param.ChannelsDefaultDatarate = dr;
    LoRaMacMibSetRequestConfirm(&mibReq);

    mibReq.Type = MIB_CHANNELS_DATARATE;
    mibReq.Param.ChannelsDatarate = dr;
    LoRaMacMibSetRequestConfirm(&mibReq);
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }

  /* Transmit Power
   * --------------
   * Trades signal strength for power efficiency.
   */
  mibReq.Type = MIB_CHANNELS_TX_POWER;
  LoRaMacMibGetRequestConfirm(&mibReq);
  if(mibReq.Param.ChannelsTxPower != txp) {
    mibReq.Type = MIB_CHANNELS_DEFAULT_TX_POWER;
    mibReq.Param.ChannelsDefaultTxPower = txp;
    LoRaMacMibSetRequestConfirm(&mibReq);

    mibReq.Type = MIB_CHANNELS_TX_POWER;
    mibReq.Param.ChannelsTxPower = txp;
    LoRaMacMibSetRequestConfirm(&mibReq);
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }

  /* Device Address
   * --------------
   */
  mibReq.Type = MIB_DEV_ADDR;
  LoRaMacMibGetRequestConfirm(&mibReq);
  if(mibReq.Param.DevAddr != DevCfg.devAddr) {
    mibReq.Param.DevAddr = DevCfg.devAddr;
    LoRaMacMibSetRequestConfirm(&mibReq);
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }

  /* Network Session Key
   * -------------------
   * Encrypts network data, available to TheThingsNetwork.
   */
  /* LORAWAN_NWK_S_KEY was renamed to LORAWAN_F_NWK_S_INT_KEY, see se-identity.h */
  if(memcmp(pNvm->SecureElement.KeyList[F_NWK_S_INT_KEY].KeyValue, DevCfg.nwkSKey, sizeof DevCfg.nwkSKey)) {
    mibReq.Type = MIB_F_NWK_S_INT_KEY;
    mibReq.Param.FNwkSIntKey = DevCfg.nwkSKey;
    LoRaMacMibSetRequestConfirm(&mibReq);
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }
  if(memcmp(pNvm->SecureElement.KeyList[S_NWK_S_INT_KEY].KeyValue, DevCfg.nwkSKey, sizeof DevCfg.nwkSKey)) {
    mibReq.Type = MIB_S_NWK_S_INT_KEY;
    mibReq.Param.SNwkSIntKey = DevCfg.nwkSKey;
    LoRaMacMibSetRequestConfirm(&mibReq);
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }
  if(memcmp(pNvm->SecureElement.KeyList[NWK_S_ENC_KEY].KeyValue, DevCfg.nwkSKey, sizeof DevCfg.nwkSKey)) {
    mibReq.Type = MIB_NWK_S_ENC_KEY;
    mibReq.Param.NwkSEncKey = DevCfg.nwkSKey;
    LoRaMacMibSetRequestConfirm(&mibReq);
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }

  /* Application Session Key
   * -----------------------
   * Encrypts our data, available to Application.
   */
  if(memcmp(pNvm->SecureElement.KeyList[APP_S_KEY].KeyValue, DevCfg.appSKey, sizeof DevCfg.appSKey)) {
    mibReq.Type = MIB_APP_S_KEY;
    mibReq.Param.AppSKey = DevCfg.appSKey;
    LoRaMacMibSetRequestConfirm(&mibReq);
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }

  /* Respect Regional Duty Cycle
   * ---------------------------
   */
  if(!!DevCfg.dutyCycle != !!pNvm->MacGroup2.DutyCycleOn) {
    LoRaMacTestSetDutyCycleOn(DevCfg.dutyCycle);
  }

  /* Adaptive Datarate
   * -----------------
   */
  mibReq.Type = MIB_ADR;
  LoRaMacMibGetRequestConfirm(&mibReq);
  if(!!mibReq.Param.AdrEnable != !!DevCfg.adaptiveDatarate) {
    mibReq.Param.AdrEnable = DevCfg.adaptiveDatarate;
    LoRaMacMibSetRequestConfirm(&mibReq);
    // NOTE: Invoke LoRaMacProcess() to save changes to EEPROM.
  }

}

/* DESCRIPTION
 *        In response to LRW changes.
 */
void LRW_ToDevCfg(void) {
  MibRequestConfirm_t mibReq;
  GetPhyParams_t getPhy;
  int8_t datarate;

  mibReq.Type = MIB_CHANNELS_DEFAULT_DATARATE;
  LoRaMacMibGetRequestConfirm(&mibReq);
  datarate = mibReq.Param.ChannelsDefaultDatarate;

  mibReq.Type = MIB_NETWORK_ACTIVATION;
  LoRaMacMibGetRequestConfirm(&mibReq);
  DevCfg.isOtaa = mibReq.Param.NetworkActivation != ACTIVATION_TYPE_ABP;

  mibReq.Type = MIB_DEV_EUI;
  LoRaMacMibGetRequestConfirm(&mibReq);
  memcpy(DevCfg.devEui, mibReq.Param.DevEui, sizeof DevCfg.devEui);

  mibReq.Type = MIB_JOIN_EUI;
  LoRaMacMibGetRequestConfirm(&mibReq);
  memcpy(DevCfg.appEui, mibReq.Param.JoinEui, sizeof DevCfg.appEui);

  memcpy(DevCfg.appKey, pNvm->SecureElement.KeyList[NWK_KEY].KeyValue, sizeof DevCfg.appKey);

  mibReq.Type = MIB_DEV_ADDR;
  LoRaMacMibGetRequestConfirm(&mibReq);
  DevCfg.devAddr = mibReq.Param.DevAddr;

  memcpy(DevCfg.nwkSKey, pNvm->SecureElement.KeyList[F_NWK_S_INT_KEY].KeyValue, sizeof DevCfg.nwkSKey);

  memcpy(DevCfg.appSKey, pNvm->SecureElement.KeyList[APP_S_KEY].KeyValue, sizeof DevCfg.appSKey);

  mibReq.Type = MIB_CHANNELS_DEFAULT_TX_POWER;
  LoRaMacMibGetRequestConfirm(&mibReq);
  DevCfg.txPower = LRW_FromTxPower(mibReq.Param.ChannelsDefaultTxPower);

  getPhy.Attribute = PHY_SF_FROM_DR;
  getPhy.Datarate = datarate;
  DevCfg.sf = RegionGetPhyParam(DevCfg.region, &getPhy).Value;

  getPhy.Attribute = PHY_BW_FROM_DR;
  getPhy.Datarate = datarate;
  DevCfg.bw = RegionGetPhyParam(DevCfg.region, &getPhy).Value + 1;

  mibReq.Type = MIB_ADR;
  LoRaMacMibGetRequestConfirm(&mibReq);
  DevCfg.adaptiveDatarate = mibReq.Param.AdrEnable;

  DevCfg.dutyCycle = pNvm->MacGroup2.DutyCycleOn;
}

bool LRW_IsBusy(void) {
  return LoRaMacIsBusy();
}

/*
 *=============================================================================
 * LORAMAC CALLBACKS
 *=============================================================================
 */

static void OnMacProcessNotify(void) {
  // IsMacProcessPending = 1;
}

static void OnNvmDataChange(LmHandlerNvmContextStates_t state, uint16_t size) {
    DisplayNvmDataChange(state, size);
}

static void OnMacMcpsRequest(LoRaMacStatus_t status, McpsReq_t *mcpsReq, TimerTime_t nextTxIn) {
    DisplayMacMcpsRequestUpdate(status, mcpsReq, nextTxIn);
}

static void OnMacMlmeRequest(LoRaMacStatus_t status, MlmeReq_t *mlmeReq, TimerTime_t nextTxIn) {
    DisplayMacMlmeRequestUpdate(status, mlmeReq, nextTxIn);
}

static void OnJoinRequest(LmHandlerJoinParams_t *params) {
  DisplayJoinRequestUpdate(params);
}

static void OnTxData(LmHandlerTxParams_t *params) {
  DisplayTxUpdate(params);
}

static void OnRxData(LmHandlerAppData_t* appData, LmHandlerRxParams_t* params) {
  DisplayRxUpdate(appData, params);
  switch(appData->Port) {
  case LORAWAN_APP_PORT:
    break;
  default:
    break;
  }
}


/*
 *=============================================================================
 * LORAMAC NOTIFICATIONS HANDLING
 *=============================================================================
 */

static void McpsConfirm(McpsConfirm_t *mcpsConfirm) {
  TxParams.IsMcpsConfirm = 1;
  TxParams.Status = mcpsConfirm->Status;
  TxParams.Datarate = mcpsConfirm->Datarate;
  TxParams.UplinkCounter = mcpsConfirm->UpLinkCounter;
  TxParams.TxPower = mcpsConfirm->TxPower;
  TxParams.Channel = mcpsConfirm->Channel;
  TxParams.AckReceived = mcpsConfirm->AckReceived;

  DBG_PRINTF("LRW MCPS TxTimeOnAir:   %d\n", mcpsConfirm->TxTimeOnAir);
  DBG_PRINTF("LRW MCPS NbTrans:       %d\n", mcpsConfirm->NbTrans);
  DBG_PRINTF("LRW MCPS AckReceived:   %d\n", mcpsConfirm->AckReceived);
  DBG_PRINTF("LRW MCPS UpLinkCounter: %d\n", mcpsConfirm->UpLinkCounter);
  DBG_PRINTF("LRW MCPS Channel:       %d\n", mcpsConfirm->Channel);

  /* Unschedule retransmissions */
  if(mcpsConfirm->AckReceived) {
    lrw.retrans_left = 0;
    lrw.queue[lrw.retrans_index].msg_type = 0;
  }

  OnTxData(&TxParams);
}

static void McpsIndication(McpsIndication_t *mcpsIndication) {
  LmHandlerAppData_t appData;

  RxParams.IsMcpsIndication = 1;
  RxParams.Status = mcpsIndication->Status;

  if(RxParams.Status != LORAMAC_EVENT_INFO_STATUS_OK)
    return;

  RxParams.Datarate = mcpsIndication->RxDatarate;
  RxParams.Rssi = mcpsIndication->Rssi;
  RxParams.Snr = mcpsIndication->Snr;
  RxParams.DownlinkCounter = mcpsIndication->DownLinkCounter;
  RxParams.RxSlot = mcpsIndication->RxSlot;

  appData.Port = mcpsIndication->Port;
  appData.BufferSize = mcpsIndication->BufferSize;
  appData.Buffer = mcpsIndication->Buffer;

  OnRxData(&appData, &RxParams);

  if(mcpsIndication->FramePending == true || mcpsIndication->ResponseTimeout > 0) {
    IsUplinkTxPending = true;
  }
}

static void MlmeConfirm(MlmeConfirm_t *mlmeConfirm) {
  TxParams.IsMcpsConfirm = 0;
  TxParams.Status = mlmeConfirm->Status;
  OnTxData(&TxParams);

  switch(mlmeConfirm->MlmeRequest) {
  case MLME_JOIN: {
    MibRequestConfirm_t mibReq;

    mibReq.Type = MIB_DEV_ADDR;
    LoRaMacMibGetRequestConfirm(&mibReq);
    JoinParams.CommissioningParams->DevAddr = mibReq.Param.DevAddr;

    mibReq.Type = MIB_CHANNELS_DATARATE;
    LoRaMacMibGetRequestConfirm(&mibReq);
    JoinParams.Datarate = mibReq.Param.ChannelsDatarate;

    if(mlmeConfirm->Status == LORAMAC_EVENT_INFO_STATUS_OK) {
      // Status is OK, node has joined the network
      JoinParams.Status = LORAMAC_HANDLER_SUCCESS;
    } else {
      // Join was not successful. Try to join again
      JoinParams.Status = LORAMAC_HANDLER_ERROR;
    }
    // Notify upper layer
    OnJoinRequest(&JoinParams);
  }
  case MLME_LINK_CHECK: break;
  case MLME_DEVICE_TIME: break;
  case MLME_BEACON_ACQUISITION: break;
  case MLME_PING_SLOT_INFO: break;
  default: break;
  }
}

static void MlmeIndication(MlmeIndication_t *mlmeIndication) {
  RxParams.IsMcpsIndication = 0;
  RxParams.Status = mlmeIndication->Status;
  if(RxParams.Status != LORAMAC_EVENT_INFO_STATUS_BEACON_LOCKED)
    OnRxData(NULL, &RxParams);

  switch(mlmeIndication->MlmeIndication) {
  case MLME_SCHEDULE_UPLINK: IsUplinkTxPending = true; break;
  case MLME_BEACON_LOST: break;
  case MLME_BEACON: break;
  default: break;
  }
}

////////////////////////////////////////////////////

int32_t LRW_HasQueue(void) {
  for(size_t i = 0; i < LRW_QUEUE_LEN; i++) {
    if(lrw.queue[i].msg_type)
      return 1;
  }
  return 0;
}

/*
 * NAME
 *        enqueueToSend - Ask *main* ctx to make LoRa msg to send. Preclude sleep.
 *
 * NOTES
 *    Locking regards
 *        Either *irq* or *main* context may invoke `enqueueToSend`, no locking
 *        element needed as only *main* can pop, and *irq* only push.
 *        main:           Can't read once .msg_type is cleared.
 *        enqueueToSend:  Can't write once .msg_type is set.
 */
void enqueueToSend(enum MsgType msg_type, uint8_t trigger_type) {
  size_t i = 0;

  /* Queue only if we're joined */
  if(!LRW_IsJoined()) {
    DEBUG_MSG("LRW ERR UNJOINED, Ignore Event!\n");
    return;
  }

  /* Pick an empty buffer to use */
  while(lrw.queue[i].msg_type && ++i < LRW_QUEUE_LEN);

  /* It appears there's no empty buffer */
  if(i >= LRW_QUEUE_LEN) {
    DEBUG_MSG("LRW ERR Queue full!\n");
    return;
  }
  uint8_t *msg = lrw.queue[i].msg;

  uint32_t volts = getBatteryVoltage();

  /* Compose a message */
  switch(msg_type) {
  case SCHEDULED: {
#if defined(STA)
    { /* Battery Voltage */
      uint32_t v = volts / 10;
      v = v < 201 ? 201 : v;
      v = v > 327 ? 327 : v;
      msg[1] = (v - 200) & 0x7f;
    }
    lrw.queue[i].len = 2;
    msg[0] = 0;
    break;
#elif defined(STE)
    memset(msg, 0, 10);
    { /* Battery Voltage */
      uint32_t v = volts / 10;
      v = v < 201 ? 201 : v;
      v = v > 327 ? 327 : v;
      msg[1] = (v - 200) & 0x7f;
    }
    { /* BME680 Temperature */
      int16_t v = bme680.data.temperature;
      v = v >  8500 ?  8500 : v;
      v = v < -4000 ? -4000 : v;
      v = (v + 4000) * (uint32_t)511 / 12500;
      msg[2] = v >>  0 << 0 & 0xff;
      msg[3] = v >>  8 << 7 & 0x80;
    }
    { /* BME680 Humidity */
      uint8_t v = bme680.data.humidity > 127000 ? 127 : bme680.data.humidity / 1000;
      msg[3] |= (v & 0x7f);
    }
    { /* BME680 Pressure */
      uint32_t v = bme680.data.pressure;
      v = v <  30000 ?  30000 : v;
      v = v > 110000 ? 110000 : v;
      v = (bme680.data.pressure - 30000) * (uint64_t)65535 / 80000;
      msg[4] = v >>  0 << 0 & 0xff;
      msg[5] = v >>  8 << 0 & 0xff;
    }
#if defined(BSEC)
    { /* BSEC IAQ Accuracy */
      msg[0] |= bme680.bsec.acc & 0x03;
    }
    { /* BSEC IAQ */
      uint16_t v =
          bme680.bsec.iaq < 0 ? 0x1ff :
          bme680.bsec.iaq > 510 ? 0x1fe :
          roundf(bme680.bsec.iaq);
      msg[6] = v >>  0 << 0 & 0xff;
      msg[1] |= v >>  8 << 7 & 0x80;
    }
    { /* BSEC VOC */
      uint16_t v = BSEC_float(bme680.bsec.voc);
      msg[7] = v >>  0 << 0 & 0xff;
      msg[9] |= v >>  8 << 0 & 0x0f;
      msg[0] |= v >> 12 << 5 & 0x20;
    }
    { /* BSEC CO2 */
      uint16_t v =
          bme680.bsec.co2 < 0 ? 0 :
          bme680.bsec.co2 > 32767 ? 32767 :
          bme680.bsec.co2;
      msg[8] = v >>  0 << 0 & 0xff;
      msg[9] |= v >>  8 << 4 & 0xf0;
      msg[0] |= v >> 12 << 2 & 0x1c;
    }
    lrw.queue[i].len = 10;
#else
    { /* BME680: Temperature, Humidity, Pressure, Air Quality Index */
      BME680_Read();
      unsigned u9_temp =
          bme680.data.temperature >=  8500 ? 511 :
          bme680.data.temperature <= -4000 ? 0 :
          (int32_t)(bme680.data.temperature  +  4000) * 512 / 12500;
      unsigned u7_humid =
          bme680.data.humidity / 1000 >= 100 ? 100 :
          bme680.data.humidity / 1000 <= 0   ? 0 :
          bme680.data.humidity / 1000;
      unsigned u16_pressure =
          bme680.data.pressure <=  30000 ? 0 :
          bme680.data.pressure >= 110000 ? UINT16_MAX :
          (uint64_t)(bme680.data.pressure - 30000) * 65536 / 80000;
      msg[2] = u9_temp;
      msg[3] = u9_temp >> 8 << 7 | u7_humid;
      msg[4] = u16_pressure;
      msg[5] = u16_pressure >> 8;
    }
    lrw.queue[i].len = 6;
    msg[0] = 0;
#endif
    break;
#elif defined(STX)
    /* Explicit fall-through */
#else
    static_assert(0, "Missing Device Family");
#endif
  }
  case EVENT: {
#ifdef STA
    { /* Battery Voltage */
      uint32_t v = volts / 10;
      v = v < 201 ? 201 : v;
      v = v > 327 ? 327 : v;
      msg[1] = (v - 200) & 0x7f;
    }
    { /* Gesture Event */
      uint8_t gest_cnt, gest;
      switch(detectedGesture) {
      case 1: gest = 0x00, DevCfg.changed.any = true, gest_cnt = DevCfg.singleCount++; break;
      case 2: gest = 0x10, DevCfg.changed.any = true, gest_cnt = DevCfg.doubleCount++; break;
      case 3: gest = 0x20, DevCfg.changed.any = true, gest_cnt = DevCfg.longCount++; break;
      default: DBG_PRINTF("LRW ERR Unknown gesture %u\n", detectedGesture);
      }
      msg[0] = gest | LRW_B0_TRIGGER_EVENT;
      msg[2] = gest_cnt;
    }
    lrw.queue[i].len = 3;
#endif
#ifdef STX
    { /* Battery Voltage */
      uint32_t v = volts / 10;
      v = v < 201 ? 201 : v;
      v = v > 327 ? 327 : v;
      msg[1] = (v - 200) & 0x7f;
    }
    { /* BMA400: Acceleration (X/Y/Z Axis) */
      BMA400_Read();
      msg[2] = bma400.raw_x;
      msg[3] = bma400.raw_y;
      msg[4] = bma400.raw_z;
      msg[5] = bma400.raw_x_ref;
      msg[6] = bma400.raw_y_ref;
      msg[7] = bma400.raw_z_ref;
    }
    { /* HDC2080: Temperature, Humidity */
      HDC2080_Read();
      msg[8] = hdc2080.raw_temp >> 7 & 0xff;
      msg[9] = (hdc2080.raw_temp >> 8 & 0x80) | hdc2080.humid % 100;
    }
    { /* SFH7776: Luminance */
      SFH7776_Read();
      msg[10] = sfh7776.lux;
      msg[11] = sfh7776.lux >> 8 & 0x3f;
    }
    msg[0] = lrw.queue[i].trigger_type & 0xf;
    lrw.queue[i].len = 12;
#endif
#ifdef STE
    DEBUG_MSG("LRW ERR STE Event\n");
    // STE can't have events.
    assert(0);
#endif
    break;
  }
  default: {
    DEBUG_MSG("LRW ERR None Event\n");
    return;
  }
  }

  /* Queue request for sending message */
#if defined(STX)
  lrw.queue[i].trigger_type = trigger_type;
#endif
  lrw.queue[i].msg_type = msg_type;

#ifdef EEDBGLOG
  {
    uint32_t events = *(volatile uint32_t*)EEPROM_LOG_EVENTS;
    HW_EraseEEPROM(EEPROM_LOG_EVENTS);
    HW_ProgramEEPROM(EEPROM_LOG_EVENTS, events + 1);
    if(events % 73 == 0) {
      uint32_t *d146 = (uint32_t*)EEPROM_LOG_VOLTYR + events / 146;
      uint32_t bak = *d146;
      bak = events % 146 == 0 ? (bak & 0xFFFF0000) | volts :
                                (bak & 0x0000FFFF) | volts << 16;
      HW_EraseEEPROM((uint32_t)d146);
      HW_ProgramEEPROM((uint32_t)d146, bak);
    }
  }
#endif
}

/* NAME
 *        LRW_Send - Prepare LoRa msg to *main* ctx to send.
 *
 * NOTES
 *    Single message processing
 *        We don't actually send the LoRaWAN payload, rather we queue it, and
 *        the `Lp.LoraWanProcess` in main while loop handles actual dispatch.
 *        So we may only process one message, and must be called each iteration
 *        if multiple messages are queued!
 *
 *        assert(LpState == LWPSTATE_IDLE);
 *
 *    Interrupt context
 *        Don't use. There are many sensor readouts that rely on HAL_Delay.
 *        Even battery voltage on sta buttons. Also the above reason.
 *
 *    Automatic storage duration
 *        Make sure the SendPayload can take buffer from stack, currently it
 *        can as it copies it to an internal buffer.
 */
void LRW_Send(void) {
  size_t i = 0;
  LmHandlerAppData_t appData;

  /* Pick a queued message, if there is any */
  while(!lrw.queue[i].msg_type && ++i < LRW_QUEUE_LEN);

  /* Pick ongoing message instead */
  i = lrw.retrans_left ? lrw.retrans_index : i;

  /* It appears there's none */
  if(i >= LRW_QUEUE_LEN) {
    return;
  }

  /* If using confirmed messages, schedule retransmissions */
  if(!lrw.retrans_left && DevCfg.confirmedMsgs) {
    lrw.retrans_left = 3;
    lrw.retrans_index = i;
  }

  DBG_PRINTF("LRW >TX retrans_left:%d [%u] 0x", lrw.retrans_left, lrw.queue[i].len);
  for(size_t j = lrw.queue[i].len; j;) {
    DBG_PRINTF("%02x", lrw.queue[i].msg[--j]);
  }
  DBG_PRINTF("\n");

  /* Schedule LoRaWAN driver to send the message */
  appData.Buffer = lrw.queue[i].msg;
  appData.BufferSize = lrw.queue[i].len;
  appData.Port = DevCfg.txPort;
  LRW_TX(&appData);

  /* Duty cycle restricted, try again later */
  if(DutyCycleWaitTime) {
    return;
  }

  /* Free the queued item */
  if(lrw.retrans_left) {
    lrw.retrans_left--;
  }
  if(!lrw.retrans_left) {
    lrw.queue[i].msg_type = 0;
  }
}
