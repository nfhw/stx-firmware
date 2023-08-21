#include "adc.h"
#include "dma.h"
#include "gpio.h"
#include "hardware.h"
#include "i2c.h"
#include "lptim.h"
#include "main.h"
#include "nfc.h"
#include "rtc.h"
#include "spi.h"
#include "radio.h"
#include "sx126x.h"
#include "st25dv.h"
#include "task_mgr.h"
#include "eeprom.h"
#include <assert.h>
#include <inttypes.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>

extern ADC_HandleTypeDef hadc;
extern LPTIM_HandleTypeDef hlptim1;
struct WakeUpHandler wuh;
volatile int adcConvDone = 0;
bool hwSlept;

/* NAME
 *        PrepareWakeup - Schedules RTC WUT to soonest event
 *
 * DESCRIPTION
 *        The duration is in seconds.
 */
void PrepareWakeup(enum WakeUpReason reason, uint32_t duration) {
  uint32_t now = HW_RTCGetSTime();
  uint32_t due = 0;

  /* Apply settings */
  switch(reason) {
  case WAKEUP_LRW_NONE:      wuh.dutycycle_due = wuh.schedmsg_due = wuh.bsec_due = 0;  break;
  case WAKEUP_LRW_DUTYCYCLE: wuh.dutycycle_due = duration ? now + duration : 0;        break;
  case WAKEUP_LRW_SCHEDMSG:  wuh.schedmsg_due  = duration ? now + duration : 0;        break;
  case WAKEUP_BSEC_SAMPLE:   wuh.bsec_due      = duration ? now + duration : 0;        break;
  }

  /* Fix overdue dues */
  if(wuh.dutycycle_due && wuh.dutycycle_due < now) wuh.dutycycle_due = now;
  if(wuh.schedmsg_due  && wuh.schedmsg_due  < now) wuh.schedmsg_due  = now;
  if(wuh.bsec_due      && wuh.bsec_due      < now) wuh.bsec_due      = now;

  /* Conclude wakeup timer state */
  wuh.reason = WAKEUP_LRW_NONE;
  if(wuh.dutycycle_due) {
    due = wuh.dutycycle_due;
    wuh.reason = WAKEUP_LRW_DUTYCYCLE;
  }
  if(wuh.schedmsg_due && (!due || wuh.schedmsg_due < due)) {
    due = wuh.schedmsg_due;
    wuh.reason = WAKEUP_LRW_SCHEDMSG;
  }
  if(wuh.bsec_due && (!due || wuh.bsec_due < due)) {
    due = wuh.bsec_due;
    wuh.reason = WAKEUP_BSEC_SAMPLE;
  }

  if(due) {
    HW_RTCWUTSet(due - now);
  } else {
    HAL_RTCEx_DeactivateWakeUpTimer(&hrtc);
  }
}

uint32_t I2C_Scan(void) {
  uint32_t device_count = 0;

  DEBUG_MSG("Scanning I2C bus:\n");
  for(uint8_t k = 1; k < 128; k++) {
    HAL_StatusTypeDef result = HAL_I2C_IsDeviceReady(&hi2c1, k << 1, 2, 2);
    if (result == HAL_OK) {
      DEBUG_PRINTF("0x%02x\n", k << 1); // Received an ACK at that address
      device_count++;
    } else {
      DEBUG_MSG("."); // No ACK received at that address
    }
  }
  DEBUG_MSG("\n");
  return device_count;
}

/*
 * RETURN VALUE
 *        Millivolts, e.g. 3263, 3293 is 3.263V and 3.293V respectively.
 */
void getBatteryVoltageAndTemperature(float *voltage, float *temperature) {
  // ADC self calibration, has to be done before any ADC Start/Enable
  while (HAL_ADCEx_Calibration_Start(&hadc, ADC_SINGLE_ENDED) != HAL_OK);

  // values for calculation of actually VDDA-supply and reference voltage
  const uint16_t VREFINT_CAL  = *VREFINT_CAL_ADDR;
  const uint16_t TEMP30_CAL   = *TEMPSENSOR_CAL1_ADDR;
  const uint16_t TEMP130_CAL  = *TEMPSENSOR_CAL2_ADDR;
  const uint16_t TEMP30       = TEMPSENSOR_CAL1_TEMP;
  const uint16_t TEMP130      = TEMPSENSOR_CAL2_TEMP;
  const float    FACTORY_VOLT = 3.0;

  // Start ADC with DMA support
  volatile uint16_t adc_value[2] = { 0, 0 };
  HAL_ADC_Start_DMA(&hadc, (uint32_t*) adc_value, 2);

  // Wait for ADC-DMA to finish (note the volatile global)
  for(adcConvDone = 0; !adcConvDone;);

  HAL_ADC_Stop_DMA(&hadc);

  // Calculate
  float vdda = (FACTORY_VOLT * VREFINT_CAL) / adc_value[0];
  float temp = (float)adc_value[1] * ((float)vdda / FACTORY_VOLT) - (float)TEMP30_CAL;
  temp *= TEMP130     - TEMP30;
  temp /= TEMP130_CAL - TEMP30_CAL;
  temp += 30;

  *voltage = vdda;
  *temperature = temp;
}

void HAL_I2C_MemRxCpltCallback(I2C_HandleTypeDef *hi2c) {
  // I2C DMA Complete transfer callback
  HAL_GPIO_WritePin(LED_1_GPIO_Port, LED_1_Pin, GPIO_PIN_RESET);
}

void LEDBlinkSync(uint8_t times, uint16_t led) {
  uint16_t ledPin = LED_1_Pin;
  if (led == LED_2_Pin) {
    ledPin = LED_2_Pin;
  }
  times = 2 * times;
  for (int i = 0; i < times; i++) {
    HAL_GPIO_TogglePin(LED_1_GPIO_Port, ledPin);
    HAL_Delay(1000);
  }
}

void LEDBlinkTask(void* info) {
  uint8_t allowButton = (uint32_t) info >> 0 & 0x1;
  uint8_t useGreenColor = (uint32_t) info >> 1 & 0x1;
  uint8_t useRedColor = (uint32_t) info >> 2 & 0x1;

#if defined(STA)
  if (allowButton) {
    SET_BIT(EXTI->IMR, EXTI_IMR_IM0);
  } else {
    CLEAR_BIT(EXTI->IMR, EXTI_IMR_IM0);
  }
#endif

  HAL_GPIO_WritePin(LED_1_GPIO_Port, LED_1_Pin, useGreenColor ? GPIO_PIN_SET : GPIO_PIN_RESET);
  HAL_GPIO_WritePin(LED_2_GPIO_Port, LED_2_Pin, useRedColor ? GPIO_PIN_SET : GPIO_PIN_RESET);
}

/* Perform given blink pattern asynchronously to main execution hereafter.
 *
 * Heed:
 *   LED, LPTIM, Button are all tied together. LPTIM IRQs performs scheduled tasks.
 *   While tasks perform the LED charade, button events are disabled,
 *   to prevent input overlay and therefore ambiguity.
 *   Thus Performing blinks while Button is masked by LEDBlink, is undefined behaviour.
 */
uint32_t LEDBlink(enum LEDBlinkPattern pattern) {
  return;
  struct task t;
  uint32_t when = tasks_ticks + 1;
  t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_GREEN);
  t.when = when;
  t.cb = &LEDBlinkTask;

  /* 1x Green Blinks 1s, Total 1s. */
  switch(pattern) {
  case BlinkPattern_G: {
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_ENABLE;
    t.when = when + 10;
    tasks_add(t);
    break;
  }

  /* 2x Green Blinks 1s, with 1s gap. Total 3s. */
  case BlinkPattern_GG: {
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_DISABLE;
    t.when = when + 10;
    tasks_add(t);
    t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_GREEN);
    t.when = when + 20;
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_ENABLE;
    t.when = when + 30;
    tasks_add(t);
    break;
  }

  /* 3x Green Blinks 1s, with 1s gap. Total 5s. */
  case BlinkPattern_GGG: {
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_DISABLE;
    t.when = when + 10;
    tasks_add(t);
    t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_GREEN);
    t.when = when + 20;
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_DISABLE;
    t.when = when + 30;
    tasks_add(t);
    t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_GREEN);
    t.when = when + 40;
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_ENABLE;
    t.when = when + 50;
    tasks_add(t);
    break;
  }

  /* 1x Red Blinks 1s, Total 1s. */
  case BlinkPattern_R: {
    t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_RED);
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_ENABLE;
    t.when = when + 10;
    tasks_add(t);
    break;
  }

  /* 1x Red Blink 1s, 1s gap, 1x Green Blink 1s. Total 3s. */
  case BlinkPattern_RG: {
    t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_RED);
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_DISABLE;
    t.when = when + 10;
    tasks_add(t);
    t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_GREEN);
    t.when = when + 20;
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_ENABLE;
    t.when = when + 30;
    tasks_add(t);
    break;
  }

  /* 3x Red Blinks 1s, with 1s gap. Total 5s. */
  case BlinkPattern_RRR: {
    t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_RED);
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_DISABLE;
    t.when = when + 10;
    tasks_add(t);
    t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_RED);
    t.when = when + 20;
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_DISABLE;
    t.when = when + 30;
    tasks_add(t);
    t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_RED);
    t.when = when + 40;
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_ENABLE;
    t.when = when + 50;
    tasks_add(t);
    break;
  }
  /* 1x Orange Blinks 1s. Total 1s. */
  case BlinkPattern_B: {
    t.arg = (void*) (LEDBLINK_BUTTON_DISABLE | LEDBLINK_COLOR_RED | LEDBLINK_COLOR_GREEN);
    tasks_add(t);
    t.arg = (void*) LEDBLINK_BUTTON_ENABLE;
    t.when = when + 10;
    tasks_add(t);
    break;
  }
  }
  return t.when;
}

void hal_deinit() {
  GPIO_InitTypeDef GPIO_InitStruct = {0};
  GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;

  /* Save power by turning off:
   * - LED Lights (PB0, PB1)
   * - SPI SX126x LoRa IC (PB4, PB5, PA4, PA11, PA12)  (TODO: PA5, PA6, PA7; Can we? It's SPI itself though)
   * - RF Switch (XXX: I'm not sure what this is)
   * Must power to wakeup by:
   * - NFC
   * - Main Button (sta)
   * - Reed Switch (stx)
   */
  GPIO_InitStruct.Pin = SX126x_Busy_Pin | SX126x_SPI_NSS_Pin | SX126x_DIO3_Pin | RF_Switch_Pin;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
  static_assert(
      GPIOA == SX126x_Busy_GPIO_Port &&
      GPIOA == SX126x_SPI_NSS_GPIO_Port &&
      GPIOA == SX126x_DIO3_GPIO_Port &&
      GPIOA == RF_Switch_GPIO_Port, "GPIOA Pinout power optimization invalidated.");

  GPIO_InitStruct.Pin = SX126x_DIO1_Pin | SX126x_Reset_Pin | LED_1_Pin | LED_2_Pin;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
  static_assert(
      GPIOB == SX126x_DIO1_GPIO_Port &&
      GPIOB == SX126x_Reset_GPIO_Port &&
      GPIOB == LED_1_GPIO_Port &&
      GPIOB == LED_2_GPIO_Port, "GPIOB Pinout power optimization invalidated.");

  // Cannot set this to floating as it needs to stay low to disable VCC_RF
//  GPIO_InitStruct.Pin = DC_Conv_Mode_Pin;
//  GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
//  GPIO_InitStruct.Pull = GPIO_NOPULL;
//  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
//  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  // Put all GPIOs in analog mode to save power
//  GPIO_InitStruct.Pin = GPIO_PIN_All;
//  GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
//  GPIO_InitStruct.Pull = GPIO_NOPULL;
//  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
//  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
//  __HAL_RCC_GPIOA_CLK_DISABLE();
//  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
//  //__HAL_RCC_GPIOB_CLK_DISABLE(); // Don't disable clock for Button's GPIO as we can't wake up otherweise
//
//  // Only activate button GPIO
//  GPIO_InitStruct.Pin = Button0_Pin;
//  GPIO_InitStruct.Mode = GPIO_MODE_IT_RISING_FALLING;
//  GPIO_InitStruct.Pull = GPIO_PULLDOWN;
//  HAL_GPIO_Init(Button0_GPIO_Port, &GPIO_InitStruct);
//  HAL_ADC_Stop_IT(&hadc);
//  HAL_LPTIM_Counter_Stop_IT(&hlptim1);

}

void hal_reinit() {
  /* GPIO Ports Clock Enable */
  MX_GPIO_Init();
  HW_GPIO_PostInit();
}

/* NAME
 *        HW_GPIO_PostInit - The sta is built with stx configuration. That means some unnecessary pins are configured.
 */
void HW_GPIO_PostInit(void) {

  GPIO_InitTypeDef GPIO_InitStruct = {0};
  GPIO_InitStruct.Mode = GPIO_MODE_ANALOG;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;

#ifdef STA
  GPIO_InitStruct.Pin |= Reed_Switch_Pin;
#endif
#ifndef SFH7776
  GPIO_InitStruct.Pin |= LIGHT_Int_Pin;
#endif
#ifndef HDC2080
  GPIO_InitStruct.Pin |= TEMP_Int_Pin;
#endif

  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

  static_assert(
      GPIOA == Reed_Switch_GPIO_Port &&
      GPIOA == LIGHT_Int_GPIO_Port &&
      GPIOA == TEMP_Int_GPIO_Port, "GPIOA Pinout power optimization invalidated.");
}

#if 0
void HW_EnterStandbyMode() {
  DBG_PRINTF("GOING TO STANDBY! %d\n", RtcGetTimeSecond());

  HAL_GPIO_WritePin(DC_Conv_Mode_GPIO_Port, DC_Conv_Mode_Pin, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(RF_Switch_GPIO_Port, RF_Switch_Pin, GPIO_PIN_RESET);
  hal_deinit();

  HAL_NVIC_SetPriority(EXTI4_15_IRQn, 1, 1);
  HAL_NVIC_EnableIRQ(EXTI4_15_IRQn);

  // SET INTERRUPT FOR USER_BTN
  HAL_NVIC_SetPriority(EXTI0_1_IRQn, 1, 1);
  HAL_NVIC_EnableIRQ(EXTI0_1_IRQn);

  HAL_PWREx_EnableUltraLowPower();
  HAL_PWREx_EnableFastWakeUp();

//  __HAL_RCC_PWR_CLK_ENABLE(); // Enable power control clock
//  HAL_PWR_DisableWakeUpPin(PWR_WAKEUP_PIN1);
//  __HAL_PWR_CLEAR_FLAG(PWR_FLAG_WU); // TODO PWR_FLAG_SB ?
  HAL_PWR_EnableWakeUpPin(PWR_WAKEUP_PIN1);
  HAL_PWR_EnterSTANDBYMode();

  hal_reinit(); // TODO: Is this even needed?
  //main(); // TODO: Is this even needed?
}
#endif

void HW_EnterStopMode() {

  // TODO: Remove in #PRODUCTION. Helps development, as Stop Mode disconnects GDB.
  // return;

  HAL_ADC_DeInit(&hadc);
  //HAL_LPTIM_Counter_Stop_IT(&hlptim1);
  //HAL_LPTIM_MspDeInit(&hlptim1);


  /* Sleep 1ms so RTT Logs reach the Host */
  //DBG_PRINTF("GOING TO STOP! RTC:%d SysTick:%d\n", HW_RTCGetSTime(), HAL_GetTick());
  HAL_Delay(100);

  HAL_GPIO_WritePin(DC_Conv_Mode_GPIO_Port, DC_Conv_Mode_Pin, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(RF_Switch_GPIO_Port, RF_Switch_Pin, GPIO_PIN_RESET);

  hal_deinit();
  HAL_PWREx_EnableUltraLowPower();
  HAL_PWREx_EnableFastWakeUp();

  __HAL_RCC_PWR_CLK_ENABLE(); // Enable power control clock

  hwSlept = true;
  HAL_PWR_EnterSTOPMode(PWR_LOWPOWERREGULATOR_ON, PWR_STOPENTRY_WFI); // | PWR_CR_CWUF
  HW_ExitStopMode();
}

void HW_ExitStopMode() {
  if(!hwSlept)
    return;
  hwSlept = false;

  HAL_NVIC_ClearPendingIRQ(EXTI4_15_IRQn);
  HAL_NVIC_ClearPendingIRQ(EXTI0_1_IRQn);
  HAL_ADC_Init(&hadc);

  hal_reinit();

  //DBG_PRINTF("WAKE UP! RTC:%d SysTick:%d\n", HW_RTCGetSTime(), HAL_GetTick());

  HAL_GPIO_WritePin(DC_Conv_Mode_GPIO_Port, DC_Conv_Mode_Pin, GPIO_PIN_SET);
  HAL_GPIO_WritePin(RF_Switch_GPIO_Port, RF_Switch_Pin, GPIO_PIN_SET);


  // Re-enable mailbox volatile register. ST25DV likely loses power during Stop Mode.
  //ST25DV_SetMBEN_Dyn(&St25Dv_Obj);

  //HAL_LPTIM_Counter_Start_IT(&hlptim1, TIMER_COUNT);
}

void HW_EraseEEPROM(uint32_t address) {
  HAL_FLASHEx_DATAEEPROM_Unlock();
  if (HAL_FLASHEx_DATAEEPROM_Erase(address) != HAL_OK) {
    DBG_PRINTF("ERROR ERASING EEPROM: 0x%02X!\n", address);
  }
  HAL_FLASHEx_DATAEEPROM_Lock();
}

void HW_ProgramEEPROM(uint32_t address, uint32_t data) {
  HAL_FLASHEx_DATAEEPROM_Unlock();
  if (HAL_FLASHEx_DATAEEPROM_Program(FLASH_TYPEPROGRAMDATA_WORD, address, data)
      != HAL_OK) {
    DBG_PRINTF("ERROR PROGRAMMING EEPROM: 0x%02X!\n", address);
  }
  HAL_FLASHEx_DATAEEPROM_Lock();
}

void HW_ResetEEPROM(void *addr, size_t size) {
  HAL_FLASHEx_DATAEEPROM_Unlock();
  // (size + 3) / 4 is a method of rounding up integer division
  for(size_t i = 0; i < (size + 3) / 4; i++) {
    if (HAL_FLASHEx_DATAEEPROM_Erase((uint32_t)addr + i * 4) != HAL_OK) {
      DBG_PRINTF("ERROR CLEARING EEPROM: 0x%02X!\n", addr);
      Breakpoint();
    }
  }
  HAL_FLASHEx_DATAEEPROM_Lock();

}

void HW_WriteEEPROM(void *addr, const void *buf, size_t size) {
  assert_param(IS_FLASH_DATA_ADDRESS(addr));
  assert_param(IS_FLASH_DATA_ADDRESS(addr + size));
  if(HAL_FLASHEx_DATAEEPROM_Unlock()) goto err;

  /* Store to initial non-word address */
  if((uintptr_t)addr % 4) {
    size_t off = (uintptr_t)addr % 4, len = 4 - off > size ? size : 4 - off;
    uint32_t *prev = (uint32_t*)((uintptr_t)addr >> 2 << 2), word = *prev;
    memcpy((char*)&word + off, buf, len);
    if(HAL_FLASHEx_DATAEEPROM_Program(FLASH_TYPEPROGRAMDATA_WORD, (uint32_t)prev, word)) goto err;
    addr = prev + 1, buf = (char*)buf + len, size -= len;
  }

  assert((uintptr_t)addr % 4 == 0);

  /* Store to word aligned addresses */
  for(size_t i = 0; i * 4 < size; i++) {
    uint32_t word;
    memcpy(&word, (char*)buf + i * 4, i * 4 + 4 > size ? (word = ((uint32_t*)addr)[i], size % 4) : 4);
    if(HAL_FLASHEx_DATAEEPROM_Program(FLASH_TYPEPROGRAMDATA_WORD, (uint32_t)addr + i * 4, word)) goto err;
  }

  if(HAL_FLASHEx_DATAEEPROM_Lock()) goto err;

  return;
err:
  DBG_PRINTF("EEPROM <WR ERR %p buf:%p size:%zu err:%" PRIx32 "\n", addr, buf, size, HAL_FLASH_GetError());
}

void HW_ReadEEPROM(const void *addr, void *buf, size_t size) {
  assert_param(IS_FLASH_DATA_ADDRESS(addr));
  assert_param(IS_FLASH_DATA_ADDRESS(addr + size));
  memcpy(buf, addr, size);
}

/* NAME
 *        HW_ChangePW - Changes saved password
 * NOTES
 *        Note, password in ST25DV App is hexadecimal, whose leftmost 2 digits
 *        are LSB of NFC message. Thus password:
 *
 *            12345678 is 0x78563412 passed as argument.
 */
void HW_ChangePW(uint32_t password) {
  HW_EraseEEPROM(EEPROM_PW);
  HW_EraseEEPROM(EEPROM_PW_COMPLEMENT);
  HW_ProgramEEPROM(EEPROM_PW,             password);
  HW_ProgramEEPROM(EEPROM_PW_COMPLEMENT, ~password);
}

/* NAME
 *        HW_RTCGetMsTime - millisecond time wraps ~49 days with 256 Hz fidelity.
 *
 * DESCRIPTION
 *        RTC sub-second register default frequency is 256 Hz. The .SubSeconds
 *        is a downcounter, e.g. 255 is 0 ms and 254 is aprox 3 ms further.
 *
 *               ms = (.SecondFraction - .SubSeconds) * 1000 / (.SecondFraction + 1)
 *
 *        Cortex System Timer (SysTick 1000 Hz) is stopped in STOP MODE,
 *        whereas RTC keeps ticking. SysTick powers HAL_Delay.
 *
 * NOTES
 *        The timestamp should only be used for distance calculations, not as
 *        calendar time.  The time_t type and value is implementation-defined
 *        by linked libc, and we're using it in a freestanding environment.
 *
 *        | ISO C              | HAL                 | Notes                          |
 *        |--------------------+---------------------+--------------------------------|
 *        | .tm_sec[0, 60]     | .Seconds[0, 59]     |                                |
 *        | .tm_min[0, 59]     | .Minutes[0, 59]     |                                |
 *        | .tm_hour[0, 23]    | .Hours[0, 23 or 12] |                                |
 *        | .tm_wday[0, 6]     | .WeekDay[1, 7]      | See RTC_WeekDay_Definitions    |
 *        | .tm_mday[1, 31]    | .Date[1, 31]        |                                |
 *        | .tm_mon[0, 11]     | .Month[1, 12]       | See RTC_Month_Date_Definitions |
 *        | .tm_year[1970 + x] | .Year[0, 99]        |                                |
 */
uint32_t HW_RTCGetMsTime(void) {
  RTC_TimeTypeDef ts;
  RTC_DateTypeDef ds;
  struct tm timeinfo;
  time_t seconds;

  HAL_RTC_GetTime(&hrtc, &ts, FORMAT_BIN);
  HAL_RTC_GetDate(&hrtc, &ds, FORMAT_BIN);
  timeinfo.tm_sec  = ts.Seconds;
  timeinfo.tm_min  = ts.Minutes;
  timeinfo.tm_hour = ts.Hours;
  timeinfo.tm_mday = ds.Date;
  timeinfo.tm_mon  = ds.Month - 1;
  timeinfo.tm_year = ds.Year + 70;
  seconds = mktime(&timeinfo);
  return seconds * 1000 + (ts.SecondFraction - ts.SubSeconds) * 1000 / (ts.SecondFraction + 1);
}

/* NAME
 *        HW_RTCGetNsTime - nanosecond time wraps 100 years (RTC defined).
 *
 * SEE ALSO
 *        HW_RTC_GetMsTime
 */
int64_t HW_RTCGetNsTime(void) {
  RTC_TimeTypeDef ts;
  RTC_DateTypeDef ds;
  struct tm timeinfo;
  time_t seconds;
  int64_t ns;

  HAL_RTC_GetTime(&hrtc, &ts, FORMAT_BIN);
  HAL_RTC_GetDate(&hrtc, &ds, FORMAT_BIN);
  timeinfo.tm_sec  = ts.Seconds;
  timeinfo.tm_min  = ts.Minutes;
  timeinfo.tm_hour = ts.Hours;
  timeinfo.tm_mday = ds.Date;
  timeinfo.tm_mon  = ds.Month - 1;
  timeinfo.tm_year = ds.Year + 70;
  seconds = mktime(&timeinfo);
  ns = (int64_t)seconds * 1000 * 1000 * 1000 + (uint64_t)(ts.SecondFraction - ts.SubSeconds) * 1000 * 1000 * 1000 / (ts.SecondFraction + 1);
  return ns;
}

/* NAME
 *        HW_RTCGetSTime - seconds time wraps 100 years (RTC defined).
 *
 * SEE ALSO
 *        HW_RTC_GetMsTime
 */
uint32_t HW_RTCGetSTime(void) {
  RTC_TimeTypeDef ts;
  RTC_DateTypeDef ds;
  struct tm timeinfo;
  time_t seconds;

  HAL_RTC_GetTime(&hrtc, &ts, FORMAT_BIN);
  HAL_RTC_GetDate(&hrtc, &ds, FORMAT_BIN);
  timeinfo.tm_hour = ts.Hours;
  timeinfo.tm_min  = ts.Minutes;
  timeinfo.tm_sec  = ts.Seconds;
  timeinfo.tm_mday = ds.Date;
  timeinfo.tm_mon  = ds.Month - 1;
  timeinfo.tm_year = ds.Year + 70;
  seconds = mktime(&timeinfo);
  return seconds;
}

void HW_RTCWUTSet(uint32_t seconds) {
  seconds = seconds ? seconds : 1;
  HAL_RTCEx_SetWakeUpTimer_IT(&hrtc, seconds - 1, seconds - 1 <= UINT16_MAX ?
      RTC_WAKEUPCLOCK_CK_SPRE_16BITS : RTC_WAKEUPCLOCK_CK_SPRE_17BITS);
}

void Breakpoint(void) {
  asm("nop");
  // asm("bkpt 0x44");
}

void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef* hadc) {
    /* When ADC-DMA transfer is complete, i.e. VREFINT and TEMPSENSOR */
    adcConvDone = 1;
}
