#include "main.h"         /* Button0_GPIO_Port */
#include "hardware.h"     /* DBG_PRINTF */
#include "protobuf.h"     /* PBEncodeMsg */
#include "task_mgr.h"     /* tasks_ticks */
#include "nfc.h"          /* MB_FCTCODE */
#include <stdbool.h>      /* true */
#include <string.h>       /* memcmp */
#include "PinNames.h"     /* pButton0 */

static struct task* buttonPendingSinglePress = NULL;

/* NAME
 *        ButtonTask_SinglePress - Finalize single press gesture, if not cancelled.
 *
 * DESCRIPTION
 *        Invoked by ISR vector at 0x0000_0074 ala LPTIM1.
 *
 *        Scheduled 1500ms after a single press release. Meant to be cancelled if
 *        gesture turns out to be a double press, within the alloted window.
 */
static void ButtonTask_SinglePress(void* unused) {
  /* Definite Single Press. */
  LEDBlink(BlinkPattern_G);
  detectedGesture = 1, enqueueToSend(EVENT, 0);

  buttonPendingSinglePress = NULL;
  DBG_PRINTF("SCHEDULE EXECUTED,                          TS %10u, LPTIM %10u, GESTURE Single Press\n", HAL_GetTick(), tasks_ticks);
}


/* NAME
 *        ButtonISR - Handles Main Button on PA0 Pin
 *
 * DESCRIPTION
 *        Invoked by ISR vector at 0x0000_0054 ala EXTI0_1.
 *
 *    SIMPLE_TWO_GESTURE_MODE
 *        Defining this macro disables the double press gesture. A positive
 *        consequence is that a single press action can happen right away.
 *
 * NOTES
 *        Notice "probably". It means that condition isn't a single press yet,
 *        as it might actually be a double or hold gesture. The consequence for
 *        single press goes into `ButtonTask_SinglePress`.
 *
 *    SIMPLE_TWO_GESTURE_MODE
 *        Caution, long press becomes paired to a different LED blink pattern.
 */
void ButtonISR() {
  struct task t;

  GPIO_PinState currEdge = HAL_GPIO_ReadPin(Button0_GPIO_Port, Button0_Pin);
  uint32_t hold, gap, now = HW_RTCGetMsTime();
  static uint32_t lastFall = 0;
  static uint32_t lastRise = 0;
  static uint8_t  lastEdge = 0;
  const char *debug_msg = "";

  hold = currEdge == GPIO_PIN_RESET ? now - lastRise : lastFall - now;
  gap  = currEdge == GPIO_PIN_SET   ? now - lastFall : lastRise - now;

  /* Debounce */
  if(currEdge == lastEdge || now - lastRise <= 100 || now - lastFall <= 100) {
    debug_msg = ", DEBOUNCE";
    goto exit;
  }

  lastRise = currEdge == GPIO_PIN_SET   ? now : lastRise;
  lastFall = currEdge == GPIO_PIN_RESET ? now : lastFall;

  /*
   *  Gesture Detection
   */

#ifdef SIMPLE_TWO_GESTURE_MODE
  /* Definite Single Press */
 if(currEdge == GPIO_PIN_RESET && hold <= 1500) {
    debug_msg = ", GESTURE Single Press";
    LEDBlink(BlinkPattern_G);
    detectedGesture = 1, enqueueToSend(EVENT, 0);

  /* Definite Long Press */
  } else if(currEdge == GPIO_PIN_RESET && 2001 <= hold && hold <= 8000) {
    debug_msg = ", GESTURE Long Press";
    LEDBlink(BlinkPattern_R);
    detectedGesture = 3, enqueueToSend(EVENT, 0);

  /* Definite Undefined Press \/('_')\/ */
  } else {
    debug_msg = ", GESTURE Undefined Press";
  }
#else
  /* Probably Single Press. */
  if(currEdge == GPIO_PIN_RESET && buttonPendingSinglePress == NULL && hold <= 1500) {
    debug_msg = ", SCHEDULE Single Press";
    t.when = tasks_ticks + 15;
    t.arg = NULL;
    t.cb = &ButtonTask_SinglePress;
    buttonPendingSinglePress = tasks_add(t);

  /* Probably Double Press. Not a Single Press. */
  } else if(currEdge == GPIO_PIN_SET && buttonPendingSinglePress != NULL) {
    debug_msg = ", SCHEDULE CANCELLED";
    tasks_del(buttonPendingSinglePress);

  /* Definite Double Press. */
  } else if(currEdge == GPIO_PIN_RESET && buttonPendingSinglePress != NULL && hold <= 1500) {
    debug_msg = ", GESTURE Double Press";
    buttonPendingSinglePress = NULL;
    LEDBlink(BlinkPattern_GG);
    detectedGesture = 2, enqueueToSend(EVENT, 0);

  /* Definite Long Press */
  } else if(currEdge == GPIO_PIN_RESET && buttonPendingSinglePress == NULL && 2001 <= hold && hold <= 8000) {
    debug_msg = ", GESTURE Long Press";
    LEDBlink(BlinkPattern_GGG);
    detectedGesture = 3, enqueueToSend(EVENT, 0);

  /* Definite Undefined Press \/('_')\/ */
  } else {
    debug_msg = ", GESTURE Undefined Press";
    buttonPendingSinglePress = NULL;
  }
#endif

exit:
  DBG_PRINTF("EDGE %u->%u, HOLD %10u, GAP %10u, TS %10u, LPTIM %10u%s\n", lastEdge, currEdge, hold, gap, now, tasks_ticks, debug_msg);
  lastEdge = currEdge;
  return;
}

#if defined(STX)
void ReedSwitchISR() {
  struct task t;

  GPIO_PinState currEdge = HAL_GPIO_ReadPin(Reed_Switch_GPIO_Port, Reed_Switch_Pin);
  uint32_t hold, gap, now = HW_RTCGetMsTime();
  static uint32_t lastFall = 0;
  static uint32_t lastRise = 0;
  static uint8_t  lastEdge = 0;
  const char *debug_msg = "";

  hold = currEdge == GPIO_PIN_RESET ? now - lastRise : lastFall - now;
  gap  = currEdge == GPIO_PIN_SET   ? now - lastFall : lastRise - now;

  /* Debounce */
  if(currEdge == lastEdge || now - lastRise <= 100 || now - lastFall <= 100) {
    debug_msg = ", DEBOUNCE";
    goto exit;
  }

  lastRise = currEdge == GPIO_PIN_SET   ? now : lastRise;
  lastFall = currEdge == GPIO_PIN_RESET ? now : lastFall;

  /* Single Press */
  if(currEdge == GPIO_PIN_RESET && hold <= 1000) {
    debug_msg = ", SCHEDULE Press";
    LEDBlink(BlinkPattern_G);
    detectedGesture = 1, enqueueToSend(EVENT, LRW_B0_TRIGGER_REED_SWITCH);
  } else {
    debug_msg = ", GESTURE Undefined Press";
  }

exit:
  DBG_PRINTF("EDGE %u->%u, HOLD %10u, GAP %10u, TS %10u, LPTIM %10u%s\n", lastEdge, currEdge, hold, gap, now, tasks_ticks, debug_msg);
  lastEdge = currEdge;
  return;

}
#endif

static void DBG_PrintBuffer(const char* pre, const uint8_t buf[], uint16_t len, const char* post) {
  DBG_PRINTF("%s0x", pre);
  if(len) do {
    DBG_PRINTF("%02x", buf[--len]);
  } while(len);
  DBG_PRINTF("%s", post);
}

/* NAME
 *        NFCISR - interrupt subroutine for ST25DV04K-IE GPO pin
 *
 * DESCRIPTION
 *        Handles received and replied msgs via mailbox. NFCTAG is never used.
 *        Formats are STm FTM demo protocol and Google protobuf.
 *
 *    Firmware upload
 *        Reset from mainfw to bootldr happens just after mainfw receives
 *        a firmware update message.
 *
 *        Transparent transition from mainfw to bootloader requires:
 *
 *        1. blocking phone from further writes to ST25DV,
 *        2. retaining the first message from ST25DV mailbox,
 *        3. retaining the valid password session.
 *
 *        The (1) is accomplished by having mainfw always start by reading only
 *        1st byte from mailbox, as only an entire readout clears
 *        `ST25DV_DYN_MB_CTRL.RF_PUT_MSG` bit. Then as MCU resets, the ST25DV
 *        is kept powered on during the transition, persisting the block. Since
 *        ST25DV still retains the message, the (2) is accomplished by bootldr
 *        initializing the ST25DV code carefully, so that mailbox isn't reset,
 *        thereafter being able to readout the message directly. Last, but not
 *        least, before mainfw transitions, it informs via EEPROM, that phone
 *        was privileged (3), and is attempting to update firmware.
 *
 *        Consequences are:
 *
 *        - mainfw always reads only 1st byte, decide action, then readout then
 *          entire mailbox.
 *        - bootldr must check EEPROM, to retain password session, prolong
 *          runtime to 120 seconds and possibly branch ST25DV init code.
 *
 * TODO
 *        Scrutinize pw invalidation after device is put to sleep.
 *        In theory, if clock doesn't tick, than device could sleep
 *        for days, and still hold a privileged session.
 *        Bootldr doesn't sleep, thus a non-issue there.
 *
 * BUGS
 *        In case no NFC commands are received beyond password timeout, and
 *        the device is awake for 49 days, the 32-bit millisecond timer wraps
 *        and privileged actions are accepted within the 2 minute window.
 *
 *        Bug kept, as window of opportunity is 0.00002%, and clock
 *        doesn't tick when asleep.
 *
 *        In case mailbox contains 1-byte message, with pw session active,
 *        on one occasion its possible to dismiss valid fwupload command.
 *
 *        1. size:1 fw:mainfw  code:not-fwupload pw:active
 *        2. size:X fw:mainfw  code:fwupload     pw:active
 *
 *        On other occasion, bootldr first msg differs from
 *        msg that actually triggered the bootldr startup.
 *
 *        1. size:1 fw:mainfw  code:fwupload pw:active
 *        2. size:N fw:bootldr code:any      pw:active
 *
 *        Bug kept, trash in, trash out, yet nothing evil happens.
 *
 *        ST25DV app sends presentpw MB_RESPONSE in lieu MB_COMMAND.
 *        And STSW-ST25DV001 fw replies MB_RESPONSE yet as well.
 *
 *        Bug kept, to retain fwupload compatibility with ST25DV app.
 *
 * EXAMPLE
 *    Firmware upload
 *        BOOTED bootldr RTT@0x20000410
 *        BOOTED mainfw RTT@0x20000410
 *        NFC IRQ IT_STS:0x10 MB_CTRL:0x01 ret:0x0 err:0x0, Interrupt
 *        NFC IRQ IT_STS:0x02 MB_CTRL:0x01 ret:0x0 err:0x0, Interrupt (repeat 70)
 *        NFC IRQ IT_STS:0x22 MB_CTRL:0x85 ret:0x0 err:0x0, Interrupt
 *        NFC <RX 0x785634120400000108, Password Message
 *        NFC >TX 0x0000000108, Password Message
 *        NFC IRQ IT_STS:0x02 MB_CTRL:0x43 ret:0x0 err:0x0, Interrupt (repeat 2)
 *        NFC IRQ IT_STS:0x42 MB_CTRL:0x41 ret:0x0 err:0x0, Interrupt
 *        NFC IRQ IT_STS:0x02 MB_CTRL:0x41 ret:0x0 err:0x0, Interrupt
 *        NFC IRQ IT_STS:0x22 MB_CTRL:0x85 ret:0x0 err:0x0, Interrupt
 *        NFC <RX 0x04, Firmware Update Message
 *        BOOTED bootldr RTT@0x20000410
 *        NFC IRQ IT_STS:0x02 MB_CTRL:0x85 ret:0x0 err:0x0, Interrupt
 *        NFC <RX 0x00BFF120005000EC010071000068000001000004, Firmware Upload Message
 *        NFC IRQ IT_STS:0x00 MB_CTRL:0x00 ret:0x1 err:0x4, Interrupt
 *        NFC IRQ IT_STS:0x22 MB_CTRL:0x85 ret:0x0 err:0x0, Interrupt
 *        NFC <RX 0x044903D0032B00EC020071000068000001000004, Firmware Upload Message
 *        ...
 *
 * SEE ALSO
 *        NFC comms doc:
 *          /MESSAGE_FORMAT_NFC.md
 *        Bootldr commit log:
 *          664ec8186463d2e7f5d8676ce9745a5a89fdbd50 at /hw/stm32-update-bootloader
 */
void NFCISR(void) {
  /* NFC State */
  uint32_t r;
  struct NFC_State nfc;
  /* Password state */
  static bool pw_valid = false;
  static uint32_t pw_timestamp;

  nfc_activity = HAL_GetTick();

  /* Write default password, if no password preset */
  if(~*(uint32_t*)EEPROM_PW != *(uint32_t*)EEPROM_PW_COMPLEMENT) {
    HW_ChangePW(ST25DV_PASSWORD);
  }

  /* Timout privileged session */
  if(pw_valid && (HW_RTCGetMsTime() < pw_timestamp || HW_RTCGetMsTime() >= pw_timestamp + NFC_PWTIMEOUT)) pw_valid = false;

  /* Read consecutive 4 bytes from st25dv chip via I2C:
   * 0) interrupt state   1) mailbox state
   * 2) mailbox length    3) mailbox 1st byte
   *
   * Describing the cause of interrupt, whether mailbox needs to be read,
   * and peek at first byte, in case its fw upload, precluding further readout.
   * */
  if(NFC_ReadReg(ST25DV_ADDR_DATA_I2C, ST25DV_ITSTS_DYN_REG, (void*)&nfc, 4)) return;
  DBG_PRINTF("NFC IRQ IT_STS:0x%02x MB_CTRL:0x%02x MB_LEN:0x%02x, Interrupt\n", nfc.it_sts, nfc.mb_ctrl, nfc.mb_len);

  /* Mailbox must have incoming data (put by RF) atleast 2 bytes */
  if(~nfc.it_sts & ST25DV_ITSTS_DYN_RFPUTMSG_MASK || !nfc.mb_len) return;

  /* FW update triggers reboot to bootloader */
  if(pw_valid && nfc.mb[MB_FCTCODE] == MB_R2HFIRMWAREUPDATE) {
    DBG_PrintBuffer("NFC <RX ", nfc.mb, 1, ", Firmware Update Message\n");

    /* Tell bootloader to listen NFC for 2 minutes and not require password */
    HW_EraseEEPROM(EEPROM_BOOTMODE);
    HW_ProgramEEPROM(EEPROM_BOOTMODE, BOOTMODE_WAITNFC_MASK | BOOTMODE_PASSOK_MASK | BOOTMODE_KEEPNFC_MASK);


    /* Reboot, with mailbox blocking due partial read, thus retain ST25DV state across boot */
    HAL_NVIC_SystemReset();
  }

  /* Read Mailbox */
  if((r = NFC_ReadReg(ST25DV_ADDR_DATA_I2C, ST25DV_MAILBOX_RAM_REG + 1, nfc.mb + 1, nfc.mb_len))) return;

  /* Parse frame */
  switch(nfc.mb[MB_FCTCODE]) {
  case MB_R2HGETCONFIG:
  case MB_R2HGETSENSOR: {
    const bool is_conf = nfc.mb[MB_FCTCODE] == MB_R2HGETCONFIG && (nfc.mb[MB_LENGTH] == 0 || nfc.mb[MB_DATA] == 0);
    DBG_PrintBuffer("NFC <RX ", nfc.mb, nfc.mb_len + 1, is_conf ? ", Ask Configure Message\n" : ", Ask Sensor Message\n");

    /* Verify message size and header. */
    if(nfc.mb_len + 1 < MB_DATA) break;
    if(nfc.mb[MB_LENGTH] > 1) break;
    if(memcmp(nfc.mb + MB_CMDRESP, (uint8_t[3]){MB_COMMAND, MB_NOERROR, MB_NOTCHAINED}, 3)) break;

    /* Encode protobuf and store size */
    nfc.mb[MB_LENGTH] = (is_conf ? PBEncodeMsg_DeviceConfiguration : PBEncodeMsg_DeviceSensors)(nfc.mb + MB_DATA, sizeof nfc.mb - MB_DATA, pw_valid);
    nfc.mb[MB_CMDRESP] = MB_RESPONSE;
    assert(nfc.mb[MB_LENGTH] <= sizeof nfc.mb - MB_DATA);

    /* Send it out */
    if(NFCTAG_OK == NFC_WriteReg(ST25DV_ADDR_DATA_I2C, ST25DV_MAILBOX_RAM_REG, nfc.mb, nfc.mb[MB_LENGTH] + MB_DATA))
      DBG_PrintBuffer("NFC >TX ", nfc.mb, nfc.mb[MB_LENGTH] + MB_DATA, is_conf ? ", Ask Configure Message\n" : ", Ask Sensor Message\n");
    break;
  }
  case MB_R2HSETCONFIG:
    DBG_PrintBuffer("NFC <RX ", nfc.mb, nfc.mb_len + 1, ", Set Configure Message\n");
    PBDecodeMsg(nfc.mb + MB_DATA, nfc.mb_len + 1 - MB_DATA);

    /* Answer ok*/
    const uint8_t response[5] = {MB_R2HSETCONFIG, MB_RESPONSE, pw_valid ? MB_NOERROR : MB_BADREQUEST, MB_NOTCHAINED, 0x00};
    if(NFCTAG_OK == NFC_WriteReg(ST25DV_ADDR_DATA_I2C, ST25DV_MAILBOX_RAM_REG, response, sizeof response))
      DBG_PrintBuffer("NFC >TX ", response, sizeof response, ", Set Configure Message\n");

    break;
  case MB_R2HPRESENTPASSWORD: {
    DBG_PrintBuffer("NFC <RX ", nfc.mb, nfc.mb_len + 1, ", Password Message\n");

    /* Verify message size, header and password. */
    if(nfc.mb_len + 1 != 9) break;
    if(nfc.mb[1] == MB_RESPONSE) nfc.mb[1] = MB_COMMAND; /* Compatibility with ST25DV App */
    if(memcmp(nfc.mb, (uint8_t[5]){MB_R2HPRESENTPASSWORD, MB_COMMAND, MB_NOERROR, MB_NOTCHAINED, 0x04}, 5)) break;
    pw_valid = !memcmp((uint32_t*)EEPROM_PW, nfc.mb + MB_DATA, 4);

    /* Answer ok if password is good, informing of elevated privileges */
    const uint8_t response[5] = {MB_R2HPRESENTPASSWORD, MB_RESPONSE, pw_valid ? MB_NOERROR : MB_BADREQUEST, MB_NOTCHAINED, 0x00};
    if(NFCTAG_OK == NFC_WriteReg(ST25DV_ADDR_DATA_I2C, ST25DV_MAILBOX_RAM_REG, response, sizeof response))
      DBG_PrintBuffer("NFC >TX ", response, sizeof response, ", Password Message\n");

    /* Grant privileged session for time limited period */
    pw_timestamp = HW_RTCGetMsTime();
    break;
  }
  case MB_R2HCHANGEPASSWORD: {
    DBG_PrintBuffer("NFC <RX ", nfc.mb, nfc.mb_len + 1, ", Change Password Message\n");

    /* Verify message size, header and we're privileged. */
    if(nfc.mb_len + 1 != 9) break;
    if(memcmp(nfc.mb, (uint8_t[5]){MB_R2HCHANGEPASSWORD, MB_COMMAND, MB_NOERROR, MB_NOTCHAINED, 0x04}, 5)) break;

    /* Answer ok if privileged */
    const uint8_t response[5] = {MB_R2HCHANGEPASSWORD, MB_RESPONSE, pw_valid ? MB_NOERROR : MB_BADREQUEST, MB_NOTCHAINED, 0x00};
    if(NFCTAG_OK == NFC_WriteReg(ST25DV_ADDR_DATA_I2C, ST25DV_MAILBOX_RAM_REG, response, sizeof response))
      DBG_PrintBuffer("NFC >TX ", response, sizeof response, ", Change Password Message\n");

    /* Change password in EEPROM */
    if(!pw_valid) break;
    uint32_t new_pw;
    memcpy(&new_pw, nfc.mb + MB_DATA, sizeof new_pw);
    HW_ChangePW(new_pw);

    break;
  }
  case MB_R2HFACTORYRESET: {
    DBG_PrintBuffer("NFC <RX ", nfc.mb, nfc.mb_len + 1, ", Factory Reset Message\n");

    /* Verify message size, header. */
    if(nfc.mb_len + 1 != 5) break;
    if(memcmp(nfc.mb, (uint8_t[5]){MB_R2HFACTORYRESET, MB_COMMAND, MB_NOERROR, MB_NOTCHAINED, 0x00}, 5)) break;

    /* Clear the EEPROM, 6 KiB, 6144 B, 1536 words */
    for(size_t i = 0; i < 1536; i++) {
      HW_EraseEEPROM(DATA_EEPROM_BASE + i * 4);
    }

    /* Answer ok. */
    const uint8_t response[5] = {MB_R2HFACTORYRESET, MB_RESPONSE, MB_NOERROR, MB_NOTCHAINED, 0x00};
    if(NFCTAG_OK == NFC_WriteReg(ST25DV_ADDR_DATA_I2C, ST25DV_MAILBOX_RAM_REG, response, sizeof response))
      DBG_PrintBuffer("NFC >TX ", response, sizeof response, ", Factory Reset Message\n");

    for(uint32_t t = HAL_GetTick() + 30000; HAL_GetTick() < t && ~nfc.it_sts & ST25DV_ITSTS_DYN_RFGETMSG_MASK;) {
      NFC_ReadReg(ST25DV_ADDR_DATA_I2C, ST25DV_ITSTS_DYN_REG, &nfc, 1);
      HAL_Delay(100);
    }

    /* Reset Firmware */
    HAL_NVIC_SystemReset();
  }
  default:
    DBG_PrintBuffer("NFC <RX ", nfc.mb, nfc.mb_len + 1, ", Undefined Message\n");
    break;
  }
}
