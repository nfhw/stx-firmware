/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * <h2><center>&copy; Copyright (c) 2021 n-fuse GmbH.
  * All rights reserved.</center></h2>
  *
  * This software component is licensed by ST under BSD 3-Clause license,
  * the "License"; You may not use this file except in compliance with the
  * License. You may obtain a copy of the License at:
  *                        opensource.org/licenses/BSD-3-Clause
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "adc.h"
#include "dma.h"
#include "i2c.h"
#include "lptim.h"
#include "rtc.h"
#include "spi.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "boards/rtc-board.h"
#include "system/spi.h"
#include "cryptoauthlib.h"
#include "atca_devtypes.h"
#include "common/LmHandler/LmHandler.h"
#include "lrw.h"
#include "eeprom.h"
#include "task_mgr.h"
#include "sensors.h"
#include "protobuf.h"
#include "isr.h"
#include "nfc.h"
#include "hardware.h" // this must to be the last include, so we can overwrite previous macros with the same name.
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */
/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define FileId 4
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */

#ifdef USE_ATECC608A
ATCAIfaceCfg *gCfg = &cfg_ateccx08a_i2c_default;
ATCA_STATUS ATECC_status;
#endif

static unsigned joinTrials;

/* Button content
 * -------------- */
uint8_t detectedGesture = 0; // Currently detected gesture

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
/* USER CODE BEGIN PFP */
static void Sleep(void);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_ADC_Init();
  MX_I2C1_Init();
  MX_LPTIM1_Init();
  MX_RTC_Init();
  MX_SPI1_Init();
  /* USER CODE BEGIN 2 */
  HW_GPIO_PostInit();
  RtcInit();

  // TODO: Optimize to enable this only when we are using the RF Chip. Relevant?
  // XXX: Must Enable RF_Switch prior to I2C Scan, in case of I2C1 Bus Lockup
  HAL_GPIO_WritePin(RF_Switch_GPIO_Port, RF_Switch_Pin, GPIO_PIN_SET);

  DEBUG_PRINTF("BOOTED mainfw RTT@0x%08x\n", &_SEGGER_RTT);
  I2C_Scan();

  // EEPROM Testing: Clear EEPROM (Nvm, DevCfg, Password).
  // HW_ResetEEPROM((void*)DATA_EEPROM_BASE, DATA_EEPROM_BANK2_END + 1 - DATA_EEPROM_BASE);

  EEPROM_Load();

#ifdef LORAWAN
  // TODO: Optimize to enable this only when we are using the RF Chip
  HAL_GPIO_WritePin(DC_Conv_Mode_GPIO_Port, DC_Conv_Mode_Pin, GPIO_PIN_SET);

  // RTC Testing: Delay and timestamp
  // uint32_t t1 = mcu.RtcGetTimeMs();
  // DBG_PRINTF("Time 1...%d\n", t1);
  // HAL_Delay(1700);
  // uint32_t t2 = mcu.RtcGetTimeMs();
  // DBG_PRINTF("Time 2...%d\n", t2);
  // uint32_t tt = t2 - t1;
  // DBG_PRINTF("TEST RTC Time diff...%d\n", tt);
  // while(1) {};

  LRW_Init();

  // LED Testing: Blink Red, then Green, with toggle interval of 3 seconds
  // HAL_GPIO_WritePin(LED_2_GPIO_Port, LED_2_Pin, GPIO_PIN_RESET);
  // HAL_GPIO_WritePin(LED_1_GPIO_Port, LED_1_Pin, GPIO_PIN_RESET);
  // while(1) {
  //   HAL_GPIO_WritePin(LED_2_GPIO_Port, LED_2_Pin, GPIO_PIN_SET); HAL_Delay(3000); HAL_GPIO_WritePin(LED_2_GPIO_Port, LED_2_Pin, GPIO_PIN_RESET); HAL_Delay(3000);
  //   HAL_GPIO_WritePin(LED_1_GPIO_Port, LED_1_Pin, GPIO_PIN_SET); HAL_Delay(3000); HAL_GPIO_WritePin(LED_1_GPIO_Port, LED_1_Pin, GPIO_PIN_RESET); HAL_Delay(3000);
  // };

  // Start the timer for the scheduler
  HAL_LPTIM_Counter_Start_IT(&hlptim1, TIMER_COUNT);

  // LoRa Testing: Force the device to join
  // Remove in #PRODUCTION. Helps developer test LoRaWAN Joining.
  // LRW_Join();

  // Start WUT only if joined (24h heartbeat)
  HAL_RTCEx_DeactivateWakeUpTimer(&hrtc);
  HAL_NVIC_SetPriority(RTC_IRQn, 3, 0);

  if(LRW_IsJoined())
    PrepareWakeup(WAKEUP_LRW_SCHEDMSG, DevCfg.sendInterval);

#endif
  // EEPROM Testing: Sensor values
  // SensorConfigurations.temperatureData = 100;
  // mcu.StoreContext(&SensorConfigurations, EEPROM_SENSOR, sizeof SensorConfigurations);
  // HAL_Delay(100);
  // mcu.RestoreContext((uint8_t*)&SensorConfigurations, EEPROM_SENSOR, sizeof SensorConfigurations);
  // DEBUG_PRINTF("TEST EEPROM SensorConfigurations.temperatureData: %d\n", SensorConfigurations.temperatureData);
#ifdef NFC
  NFC_Init();
#endif

#ifdef USE_ATECC608A
/* Establish I2C connection to ATECC608A */
ATECC_status = atcab_init(gCfg);
if (ATECC_status != ATCA_SUCCESS ) {
  DBG_PRINTF("ATECC608a configuration failed: %x\n", ATECC_status);
}

// Reading the serial number
uint8_t serialnum[ATCA_SERIAL_NUM_SIZE];
// while(1) {
ATECC_status = atcab_read_serial_number(serialnum);
if (ATECC_status != ATCA_SUCCESS) {
  DBG_PRINTF("ATECC608A could not read serial number: %x\n", ATECC_status);
} else {
  DBG_PRINTF("ATECC608A serial number: %d:%d:%d:%d:%d:%d:%d:%d:%d \n", serialnum[0],serialnum[1],serialnum[2],serialnum[3],serialnum[4],serialnum[5],serialnum[6],serialnum[7],serialnum[8]);
}
// }

#endif

#ifdef BMA400
  /* BMA400 persists across MCU reset, either power-cycle or explicitly reset to disable it. */
  // BMA400_Init(DevCfg.bma400_config, DevCfg.bma400_threshold);

  // Sensor Testing: BMA400 (Acceleration)
  // for(int i = 0; i < 5; i++) {
  //  BMA400_Read();
  //  DEBUG_PRINTF("TEST %d   BMA400 X:%5d Y:%5d Z:%5d IRQ:0x%04x\n", i, bma400.fix_x, bma400.fix_y, bma400.fix_z, bma400.status);
  //  HAL_Delay(100);
  // }
  // BMA400_Reset();
  // BMA400_ForeverTest();
#endif

#ifdef SFH7776
  /* SFH7776 persists across MCU reset, either power-cycle or explicitly reset to disable it. */
  // SFH7776_Init(DevCfg.sfh7776_threshold_upper, DevCfg.sfh7776_threshold_lower);

  // Sensor Testing: SFH7776 (Luminance)
  // for(int i = 0; i < 5; i++) {
  //  SFH7776_Read();
  //  DEBUG_PRINTF("TEST %d   SFH7776 ALS_VIS:0x%04x ALS_IR:0x%04x lux:%5d\n", i, sfh7776.als_vis, sfh7776.als_ir, sfh7776.lux);
  //   HAL_Delay(400);
  // }
  // SFH7776_Reset();
  // SFH7776_ForeverTest();
#endif

#ifdef HDC2080
  /* HDC2080 persists across MCU reset, either power-cycle or explicitly reset to disable it. */
  // HDC2080_Init(DevCfg.hdc2080_mode, DevCfg.hdc2080_threshold);

  // Sensor Testing: HDC2080 (Humidity & Temperature)
  // for(int i = 0; i < 5; i++) {
  //  HDC2080_Read();
  //  DEBUG_PRINTF("TEST %d   HDC2080 TEMP:%5d 0x%04x HUMID:%5d 0x%04x\n", i, hdc2080.fix_temp, hdc2080.raw_temp, hdc2080.humid, hdc2080.raw_humid);
  //  HAL_Delay(1000);
  // }
  // HDC2080_Reset();
  // HDC2080_ForeverTest();
#endif

#ifdef BME680
#ifdef BSEC
  BSEC_Init(BSEC_SAMPLE_RATE_ULP);
  BSEC_Read();
  // Sensor Testing: BSEC
  // BSEC_ForeverTest();
#else
  BME680_Init();
  // Sensor Testing: BME680
  // for (uint8_t i = 1; i < 5; i++) {
  //   BME680_ReadOld();
  //   HAL_Delay(1000);
  // }
#endif /* BSEC */
#endif /* BME680 */

  // Button Testing: Read input pin
  // while(1) {
  //   int buttonValue = HAL_GPIO_ReadPin(Button0_GPIO_Port, Button0_Pin);
  //   DEBUG_PRINTF("TEST BTN %d\n", buttonValue);
  //   HAL_Delay(1000);
  // }

#ifdef EEDBGLOG
  {
    uint32_t reboots = *(volatile uint32_t*)EEPROM_LOG_REBOTS;
    HW_EraseEEPROM(EEPROM_LOG_REBOTS);
    HW_ProgramEEPROM(EEPROM_LOG_REBOTS, reboots + 1);
  }
#endif

  // Feedback that a boot or reboot has happened
  LEDBlink(BlinkPattern_B);

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
    /*
     * Handle NFC events
     */
    if(DevCfg.changed.any) {
#ifdef STX
      if(DevCfg.changed.bma400) {
        if(DevCfg.useSensor.bma400) {
          BMA400_Init(DevCfg.bma400_config, DevCfg.bma400_threshold);
          DEBUG_MSG("SEN BMA400  IRQ ON\n");
        } else {
          BMA400_Init(DevCfg.bma400_config = 0xf, DevCfg.bma400_threshold = 3907);
          DEBUG_MSG("SEN BMA400  IRQ OFF\n");
        }
      }
      if(DevCfg.changed.sfh7776) {
        if(DevCfg.useSensor.sfh7776) {
          SFH7776_Init(DevCfg.sfh7776_threshold_upper, DevCfg.sfh7776_threshold_lower);
          DEBUG_MSG("SEN SFH7776 IRQ ON\n");
        } else {
          SFH7776_Init(DevCfg.sfh7776_threshold_upper = UINT16_MAX, DevCfg.sfh7776_threshold_lower = 0);
          DEBUG_MSG("SEN SFH7776 IRQ OFF\n");
        }
      }
      if(DevCfg.changed.hdc2080) {
        if(DevCfg.useSensor.hdc2080) {
          HDC2080_Init(DevCfg.hdc2080_mode, DevCfg.hdc2080_threshold);
          DEBUG_MSG("SEN HDC2080 IRQ ON\n");
        } else {
          HDC2080_Init(DevCfg.hdc2080_mode = HDC2080_TEMPERATURE_HIGH, DevCfg.hdc2080_threshold = 12499);
          DEBUG_MSG("SEN HDC2080 IRQ OFF\n");
        }
      }
#endif
      if(DevCfg.changed.lrw) {
        LRW_FromDevCfg();
      }
      if(DevCfg.changed.lrw || DevCfg.changed.resched) {
        /* Disable scheduled messages if we're not joined. */
        PrepareWakeup(WAKEUP_LRW_SCHEDMSG, LRW_IsJoined() ? DevCfg.sendInterval : 0);
      }

      EEPROM_Save();
      memset(&DevCfg.changed, 0, sizeof DevCfg.changed);
    }

    if(!LRW_IsJoined() && memcmp((char[16]){0}, DevCfg.appKey, 16)) {
      DEBUG_MSG("LRW JOINING...\n");
      LRW_Join();
      if(!DutyCycleWaitTime) joinTrials++;

    /* Send queued messages, if joined */
    } else if(!LRW_IsBusy() && !tasks_has_pending()) {
      LRW_Send();
    }

    /* The Heart of LoRaWAN, performs the actual send/recv. cryptography, state handling and nvm store */
    while(LRW_IsBusy()) {
      LRW_Process();
      HAL_Delay(100);
    }

    if(!DutyCycleWaitTime) {
      if(!LRW_IsJoined()) {
        DEBUG_MSG("LRW NOT JOINED\n");
        if(joinTrials == 5) {
          joinTrials = 0;
          DEBUG_MSG("GIVING UP JOINING\n");
          LEDBlink(BlinkPattern_RRR);
          /* Wait for blink here, so we sleep rather than start another 5 tries */
          while(tasks_has_pending() == -1) {};
        }
      } else {
        if(joinTrials > 0) {
          joinTrials = 0;
          DEBUG_PRINTF("LRW JOINED %d\n", HW_RTCGetMsTime());
          LEDBlink(BlinkPattern_RG);

          /* Enable RTC WUT (24h heartbeat) */
          PrepareWakeup(WAKEUP_LRW_SCHEDMSG, DevCfg.sendInterval);
        }
      }
    }

#ifdef BSEC
    BSEC_Read();
#endif

    /* Go to sleep once LoRaWAN is idle and there's no tasks on LED blinks & button gestures. */
    Sleep();
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
  RCC_PeriphCLKInitTypeDef PeriphClkInit = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Configure LSE Drive Capability
  */
  HAL_PWR_EnableBkUpAccess();
  __HAL_RCC_LSEDRIVE_CONFIG(RCC_LSEDRIVE_LOW);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_LSE|RCC_OSCILLATORTYPE_MSI;
  RCC_OscInitStruct.LSEState = RCC_LSE_ON;
  RCC_OscInitStruct.MSIState = RCC_MSI_ON;
  RCC_OscInitStruct.MSICalibrationValue = 0;
  RCC_OscInitStruct.MSIClockRange = RCC_MSIRANGE_5;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_MSI;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
  {
    Error_Handler();
  }
  PeriphClkInit.PeriphClockSelection = RCC_PERIPHCLK_I2C1|RCC_PERIPHCLK_RTC
                              |RCC_PERIPHCLK_LPTIM1;
  PeriphClkInit.I2c1ClockSelection = RCC_I2C1CLKSOURCE_PCLK1;
  PeriphClkInit.RTCClockSelection = RCC_RTCCLKSOURCE_LSE;
  PeriphClkInit.LptimClockSelection = RCC_LPTIM1CLKSOURCE_LSE;

  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */

extern Gpio_t *GpioIrq[16];

/* NAME
 *        HAL_GPIO_EXTI_Callback - Handles
 *
 * NOTES
 *        Humorously the ISR acronym below happens to mean two different things:
 *        * Interrupt Sub-Routine      - Code triggered on interrupt event
 *        * Interrupt Status Register  - Cause of Interrupt
 */
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin) {
  uint8_t triggerType;
  switch(GPIO_Pin) {

  /* Button press/release or acceleration sensor */
  case Button0_Pin: {
#ifdef STA
    DEBUG_MSG("IRQ Button Pin\n");

    /* Potential Refactor: Relocate to HW_EnterStopMode()? See HAL_PWR_EnterSTOPMode() notes */
    __HAL_PWR_CLEAR_FLAG(PWR_FLAG_WU);

    /* Discard if LoRaWAN connection not established */
    if(!LRW_IsJoined()) {
      DEBUG_MSG("LRW WARN  UNJOINED, Ignore Event!\n");
      break;
    }

    /* LoRaWAN is busy, don't accept blinks and thus button presses */
    if(LRW_IsBusy())
      break;

    ButtonISR();
#endif
#ifdef STX
    triggerType = LRW_B0_TRIGGER_MOTION;
    BMA400_Read();
    DEBUG_PRINTF("SEN BMA400  IRQ trigger:%u X:%5d Y:%5d Z:%5d rX:%5d rY:%5d rZ:%5d IRQ:0x%04x\n",
          triggerType, bma400.fix_x, bma400.fix_y, bma400.fix_z,
          bma400.fix_x_ref, bma400.fix_y_ref, bma400.fix_z_ref, bma400.status);
    /* Discard if LoRaWAN connection not established */
    if(!LRW_IsJoined()) {
      DEBUG_MSG("LRW WARN  UNJOINED, Ignore Event!\n");
      break;
    }
    if(!DevCfg.useSensor.bma400) {
      DEBUG_MSG("SEN BMA400  UNUSED, Ignore Event!\n");
      break;
    }
    enqueueToSend(EVENT, triggerType);
#endif
    break;
  }

  /* SX126x LoRaWAN RX/TX Done */
  case SX126x_DIO1_Pin: {
    GpioIrq[5]->IrqHandler(GpioIrq[5]->Context);
    break;
  }

  /* ST25DV NFC Mailbox read/written by phone */
  case NFC_Int_Pin: {
    HW_ExitStopMode();
    NFCISR();
    break;
  }

  /* Temperature and humidity sensor */
  case TEMP_Int_Pin: {
#ifdef STX
    HDC2080_Read();
    triggerType =
      hdc2080.status & 0x40 ? LRW_B0_TRIGGER_TEMPERATURE_HIGH :
      hdc2080.status & 0x20 ? LRW_B0_TRIGGER_TEMPERATURE_LOW :
      hdc2080.status & 0x10 ? LRW_B0_TRIGGER_HUMIDITY_HIGH : LRW_B0_TRIGGER_HUMIDITY_LOW;
    DEBUG_PRINTF("SEN HDC2080 IRQ trigger:%u CONFIG:0x%02x\n", triggerType, hdc2080.status);
    /* Discard if LoRaWAN connection not established */
    if(!LRW_IsJoined()) {
      DEBUG_MSG("LRW WARN  UNJOINED, Ignore Event!\n");
      break;
    }
    if(!DevCfg.useSensor.hdc2080) {
      DEBUG_MSG("SEN HDC2080 UNUSED, Ignore Event!\n");
      break;
    }
    enqueueToSend(EVENT, triggerType);
#endif
    break;
  }

  /* Reed switch aka magnet sensor */
  case Reed_Switch_Pin: {
#ifdef STX
    DEBUG_PRINTF("SEN Reed Switch IRQ trigger:%u\n", LRW_B0_TRIGGER_REED_SWITCH);
    /* Discard if LoRaWAN connection not established */
    if(!LRW_IsJoined()) {
      DEBUG_MSG("LRW WARN  UNJOINED, Ignore Event!\n");
      break;
    }
    /* LoRaWAN is busy, don't accept blinks and thus button presses */
    if(LRW_IsBusy())
      break;
    ReedSwitchISR();
#endif
    break;
  }

  /* Light sensor */
  case LIGHT_Int_Pin: {
#ifdef STX
    SFH7776_Read();
    triggerType = sfh7776.als_vis < sfh7776.als_vis_tl ? LRW_B0_TRIGGER_LIGHT_LOW : LRW_B0_TRIGGER_LIGHT_HIGH;
    DEBUG_PRINTF("SEN SFH7776 IRQ trigger:%d ALS_VIS:0x%04x ALS_IR:0x%04x lux:%5d\n", triggerType, sfh7776.als_vis, sfh7776.als_ir, sfh7776.lux);
    /* Discard if LoRaWAN connection not established */
    if(!LRW_IsJoined()) {
      DEBUG_MSG("LRW WARN  UNJOINED, Ignore Event!\n");
      break;
    }
    if(!DevCfg.useSensor.sfh7776) {
      DEBUG_MSG("SEN SHF7776 UNUSED, Ignore Event!\n");
      break;
    }
    enqueueToSend(EVENT, triggerType);
#endif
    break;
  }
  default:
    DEBUG_MSG("IRQ Unhandled\n");
  }
}

/* Wake-up timer (RTC) implementation */
void HAL_RTCEx_WakeUpTimerEventCallback(RTC_HandleTypeDef *hrtc) {
  uint32_t now = HW_RTCGetSTime();

  DEBUG_PRINTF("RTC WAKEUP now:%d reason:%d\n", now, wuh.reason);

  if(wuh.dutycycle_due && wuh.dutycycle_due <= now) {
    PrepareWakeup(WAKEUP_LRW_DUTYCYCLE, 0);
  }
  if(wuh.schedmsg_due && wuh.schedmsg_due <= now) {
    PrepareWakeup(WAKEUP_LRW_SCHEDMSG, DevCfg.sendInterval);
    enqueueToSend(SCHEDULED, 0);
  }
  if(wuh.bsec_due && wuh.bsec_due <= now) {
    PrepareWakeup(WAKEUP_BSEC_SAMPLE, 0);
  }
}

static void Sleep(void) {
  HAL_Delay(100);

  /* Finish up LED blinks & button gestures */
  if(tasks_has_pending())
    return;

  /* Sleep if NFC had no activity for last 2 seconds */
  if(NFC_HasActivity())
    return;

  /* Sleep if LRW is idle, joined, it's queue is empty or duty cycle restricted */
  if(LRW_IsBusy())
    return;
  if(DutyCycleWaitTime < 1000 && joinTrials)
    return;
  if(DutyCycleWaitTime < 1000 && LRW_IsJoined() && LRW_HasQueue())
    return;

#ifdef BSEC
  { /* Sleep if BSEC sample is scheduled */
    int64_t seconds = (bme680.bsec.next_call - HW_RTCGetNsTime()) / 1000 / 1000 / 1000;
    if(seconds > 0)
      PrepareWakeup(WAKEUP_BSEC_SAMPLE, seconds);
    if(!wuh.bsec_due)
      return;
  }
#endif

  /* If duty cycle restricted, schedule a wake up */
  if(DutyCycleWaitTime > 1000)
    PrepareWakeup(WAKEUP_LRW_DUTYCYCLE, DutyCycleWaitTime / 1000);

  /* All good? Ok then, lets sleep. */
  HW_EnterStopMode();
}


/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  DBG_PRINTF("ERROR OCCURRED\n");
  HAL_Delay(10000);
  DBG_PRINTF("REBOOTING NOW...\n");
  NVIC_SystemReset();
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
