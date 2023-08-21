/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __HARDWARE_H
#define __HARDWARE_H
#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32l0xx_hal.h"
#include "stm32l071xx.h"
#include "LoRaMac.h"
#include <stdbool.h>
#include <assert.h>

#ifdef DEBUG
#include "SEGGER_RTT.h"
#endif

/* Exported types ------------------------------------------------------------*/
typedef enum {
  PROCESSOR_BLOCKING = 0,
  DMA_NONBLOCK
} FTM_Mode;

typedef  void (*pFunction)(void);

enum LEDBlinkPattern {
  BlinkPattern_G,
  BlinkPattern_GG,
  BlinkPattern_GGG,
  BlinkPattern_R,
  BlinkPattern_RG,
  BlinkPattern_RRR,
  BlinkPattern_B
};

enum MsgType {
  NONE,
  SCHEDULED,
  EVENT,
};

enum WakeUpReason {
  WAKEUP_LRW_NONE,
  WAKEUP_LRW_SCHEDMSG,
  WAKEUP_LRW_DUTYCYCLE,
  WAKEUP_BSEC_SAMPLE,
};

struct WakeUpHandler {
  enum WakeUpReason reason;
  /* Seconds */
  uint32_t schedmsg_due;
  uint32_t dutycycle_due;
  uint32_t bsec_due;
};

/* Exported constants --------------------------------------------------------*/
#define VREFINT_CAL_ADDR     ((uint16_t*) 0x1FF80078U) // 2 Byte at this address is VRefInt_cal @3.0V/25 deg.C
#define TEMPSENSOR_CAL1_ADDR ((uint16_t*) 0x1FF8007AU) /* Internal temperature sensor, address of parameter TS_CAL1: On STM32L0, temperature sensor ADC raw data acquired at temperature  30 DegC (tolerance: +-5 DegC), Vref+ = 3.0 V (tolerance: +-10 mV). */
#define TEMPSENSOR_CAL2_ADDR ((uint16_t*) 0x1FF8007EU) /* Internal temperature sensor, address of parameter TS_CAL2: On STM32L0, temperature sensor ADC raw data acquired at temperature 130 DegC (tolerance: +-5 DegC), Vref+ = 3.0 V (tolerance: +-10 mV). */
#define TEMPSENSOR_CAL1_TEMP (30U)                       /* Internal temperature sensor, temperature at which temperature sensor has been calibrated in production for data into TEMPSENSOR_CAL1_ADDR (tolerance: +-5 DegC) (unit: DegC). */
#define TEMPSENSOR_CAL2_TEMP (130U)                      /* Internal temperature sensor, temperature at which temperature sensor has been calibrated in production for data into TEMPSENSOR_CAL2_ADDR (tolerance: +-5 DegC) (unit: DegC). */

/* Bitmask for LPTIM LED task */
#define LEDBLINK_BUTTON_DISABLE 0x0U
#define LEDBLINK_BUTTON_ENABLE  0x1U
#define LEDBLINK_COLOR_GREEN    0x2U
#define LEDBLINK_COLOR_RED      0x4U

/* EEPROM Layout */
#define EEPROM_BOOTMODE           (DATA_EEPROM_BASE)
#define EEPROM_BOOTMODE_END       (DATA_EEPROM_BASE + 0x4)
#define EEPROM_UNUSED0            (DATA_EEPROM_BASE + 0x4)
#define EEPROM_UNUSED0_END        (DATA_EEPROM_BASE + 0x8)
#define EEPROM_PW                 (DATA_EEPROM_BASE + 0x8)
#define EEPROM_PW_END             (DATA_EEPROM_BASE + 0xc)
#define EEPROM_PW_COMPLEMENT      (DATA_EEPROM_BASE + 0xc)
#define EEPROM_PW_COMPLEMENT_END  (DATA_EEPROM_BASE + 0x10)
#define EEPROM_LORA               (DATA_EEPROM_BASE + 0x10)       // start flash adress to store lorawan context
#define EEPROM_LORA_END           (DATA_EEPROM_BASE + 0x1000)
#define EEPROM_APP                (DATA_EEPROM_BASE + 0x1000)
#define EEPROM_APP_END            (DATA_EEPROM_BASE + 0x1400)
#define EEPROM_LOG                (DATA_EEPROM_BASE + 0x1400)

#define EEPROM_LOG_REBOTS         (DATA_EEPROM_BASE + 0x1400)
#define EEPROM_LOG_EVENTS         (DATA_EEPROM_BASE + 0x1404)
#define EEPROM_LOG_SENDED         (DATA_EEPROM_BASE + 0x1408)
#define EEPROM_LOG_VOLTYR         (DATA_EEPROM_BASE + 0x140c)

#define EEPROM_LOG_END            (DATA_EEPROM_BASE + 0x1800)
static_assert(sizeof(LoRaMacNvmData_t) < EEPROM_LORA_END - EEPROM_LORA, "LoRaMac-node overstepping EEPROM boundaries.");

/* Bootloader BOOTMODES */
#define BOOTMODE_MAINFW           ((uint32_t)0x0)
#define BOOTMODE_WAITNFC_MASK     ((uint32_t)0x1) /* Bootldr hangs around for longer */
#define BOOTMODE_PASSOK_MASK      ((uint32_t)0x2) /* Bootldr is privileged from get go */
#define BOOTMODE_KEEPNFC_MASK     ((uint32_t)0x4) /* Bootldr doesn't reset ST25DV IC */

#if defined(STA)
#define LRW_B0_TRIGGER_EVENT             (0x01U)
#elif defined(STX)
#define LRW_B0_TRIGGER_MOTION            (0x01U)
#define LRW_B0_TRIGGER_LIGHT_HIGH        (0x02U)
#define LRW_B0_TRIGGER_LIGHT_LOW         (0x03U)
#define LRW_B0_TRIGGER_TEMPERATURE_HIGH  (0x04U)
#define LRW_B0_TRIGGER_TEMPERATURE_LOW   (0x05U)
#define LRW_B0_TRIGGER_HUMIDITY_HIGH     (0x06U)
#define LRW_B0_TRIGGER_HUMIDITY_LOW      (0x07U)
#define LRW_B0_TRIGGER_REED_SWITCH       (0x08U)
#endif

/* External variables --------------------------------------------------------*/
extern uint8_t detectedGesture; // Currently detected gesture
extern struct WakeUpHandler wuh;
extern bool hwSlept;
extern volatile int adcConvDone;

/* Exported macros -----------------------------------------------------------*/
#undef DEBUG_PRINTF
#undef DEBUG_MSG
#ifdef DEBUG
#define DBG_PRINTF(...)               SEGGER_RTT_printf(0, __VA_ARGS__)
#define DEBUG_PRINTF(fmt, args...)    SEGGER_RTT_printf(0, fmt, args)
#define DEBUG_MSG(str)                SEGGER_RTT_WriteString(0, str)
#else
#define DBG_PRINTF(...)               ((void)0)
#define DEBUG_PRINTF(fmt, args...)    ((void)0)
#define DEBUG_MSG(str)                ((void)0)
#endif

/* Exported functions ------------------------------------------------------- */
void getBatteryVoltageAndTemperature(float *voltage, float *temperature);
void enqueueToSend(enum MsgType msg_type, uint8_t trigger_type);
void hal_deinit();

void HW_GPIO_PostInit(void);
void HW_ReadEEPROM(const void *addr, void *buf, size_t size);
void HW_WriteEEPROM(void *addr, const void *buf, size_t size);
void HW_ChangePW(uint32_t password);
void HW_EnterStandbyMode();
void HW_EnterStopMode();
void HW_ResetEEPROM(void *addr, size_t size);
void HW_EraseEEPROM(uint32_t address);
void HW_ExitStopMode();
void HW_ProgramEEPROM(uint32_t address, uint32_t data);
uint32_t HW_RTCGetSTime(void);
uint32_t HW_RTCGetMsTime(void);
int64_t HW_RTCGetNsTime(void);
void HW_RTCWUTSet(uint32_t seconds);
void Breakpoint(void);

void PrepareWakeup(enum WakeUpReason reason, uint32_t duration);
uint32_t I2C_Scan(void);
uint32_t LEDBlink(enum LEDBlinkPattern pattern);
void LEDBlinkSync(uint8_t times, uint16_t led);

extern uint32_t RtcGetTimeSecond();

#ifdef __cplusplus
}
#endif
#endif /* __HARDWARE_H */
