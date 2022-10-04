/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  ** This notice applies to any and all portions of this file
  * that are not between comment pairs USER CODE BEGIN and
  * USER CODE END. Other portions of this file, whether
  * inserted by the user or by software development tools
  * are owned by their respective copyright owners.
  *
  * COPYRIGHT(c) 2018 STMicroelectronics
  *
  * Redistribution and use in source and binary forms, with or without modification,
  * are permitted provided that the following conditions are met:
  *   1. Redistributions of source code must retain the above copyright notice,
  *      this list of conditions and the following disclaimer.
  *   2. Redistributions in binary form must reproduce the above copyright notice,
  *      this list of conditions and the following disclaimer in the documentation
  *      and/or other materials provided with the distribution.
  *   3. Neither the name of STMicroelectronics nor the names of its contributors
  *      may be used to endorse or promote products derived from this software
  *      without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32l0xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#ifdef __cplusplus
extern "C" {
#endif

#include "stm32l0xx_hal.h"

#ifdef __cplusplus
}
#endif
/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define Button0_Pin GPIO_PIN_0
#define Button0_GPIO_Port GPIOA
#define Button0_EXTI_IRQn EXTI0_1_IRQn
#define NFC_Int_Pin GPIO_PIN_1
#define NFC_Int_GPIO_Port GPIOA
#define NFC_Int_EXTI_IRQn EXTI0_1_IRQn
#define RF_Switch_Pin GPIO_PIN_2
#define RF_Switch_GPIO_Port GPIOA
#define TEMP_Int_Pin GPIO_PIN_3
#define TEMP_Int_GPIO_Port GPIOA
#define TEMP_Int_EXTI_IRQn EXTI2_3_IRQn
#define SX126x_SPI_NSS_Pin GPIO_PIN_4
#define SX126x_SPI_NSS_GPIO_Port GPIOA
#define SX126x_SPI_SCK_Pin GPIO_PIN_5
#define SX126x_SPI_SCK_GPIO_Port GPIOA
#define SX126x_SPI_MISO_Pin GPIO_PIN_6
#define SX126x_SPI_MISO_GPIO_Port GPIOA
#define SX126x_SPI_MOSI_Pin GPIO_PIN_7
#define SX126x_SPI_MOSI_GPIO_Port GPIOA
#define LED_1_Pin GPIO_PIN_0
#define LED_1_GPIO_Port GPIOB
#define LED_2_Pin GPIO_PIN_1
#define LED_2_GPIO_Port GPIOB
#define DC_Conv_Mode_Pin GPIO_PIN_8
#define DC_Conv_Mode_GPIO_Port GPIOA
#define Reed_Switch_Pin GPIO_PIN_9
#define Reed_Switch_GPIO_Port GPIOA
#define Reed_Switch_EXTI_IRQn EXTI4_15_IRQn
#define LIGHT_Int_Pin GPIO_PIN_10
#define LIGHT_Int_GPIO_Port GPIOA
#define LIGHT_Int_EXTI_IRQn EXTI4_15_IRQn
#define SX126x_Busy_Pin GPIO_PIN_11
#define SX126x_Busy_GPIO_Port GPIOA
#define SX126x_DIO3_Pin GPIO_PIN_12
#define SX126x_DIO3_GPIO_Port GPIOA
#define SWDIO_STLink_Pin GPIO_PIN_13
#define SWDIO_STLink_GPIO_Port GPIOA
#define SWCLK_STLink_Pin GPIO_PIN_14
#define SWCLK_STLink_GPIO_Port GPIOA
#define SX126x_Reset_Pin GPIO_PIN_4
#define SX126x_Reset_GPIO_Port GPIOB
#define SX126x_DIO1_Pin GPIO_PIN_5
#define SX126x_DIO1_GPIO_Port GPIOB
#define SX126x_DIO1_EXTI_IRQn EXTI4_15_IRQn
/* USER CODE BEGIN Private defines */
#define MSG_FORMAT_VERSION 1
#define FIRMWARE_VERSION 10 // divide by 10 to get actual version

#define USE_ATECC608A

#define NFC
#define LORAWAN
//#define EEDBGLOG

/* Password
 * --------
 * Firmware Upload, LoRa Config R/W, etc.
 */
#define ST25DV_PASSWORD  (0x78563412U)

/* Device Family
 * -------------
 * STA: Button
 * STX: Reed Switch + HDC2080 (Humidity, Temperature) + SFH7776 (Luminance) + BMA400 (Accelerometer)
 * STE: BME680 (Temperature, Humidity, Pressure, Gas Resistance)
 */
//#define STA
#define STX
//#define STE

/* Operation Mode
 * --------------
 * SIMPLE_TWO_GESTURE_MODE: Remove tap gesture latency by disabling double tap. LED patters remapped.
 */
#define SIMPLE_TWO_GESTURE_MODE

#ifdef STX /* Multi Sensor */
#define HDC2080 /* Temperature, Humidity */
#define BMA400 /* Acceleration (X/Y/Z Acis) */
#define SFH7776 /* Luminance */
#endif

#ifdef STE /* Environment Sensor */
#define BME680 /* Temperature, Humidity, Pressure */
#define BSEC /* AQI (Air Quality Index), VOC (Volatile Organic Compounds), CO2 */
#endif

#ifdef STA /* Button */
#define ACTION_SENSOR /* Button */
#endif
/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
