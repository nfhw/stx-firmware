#ifndef PINNAMES_H
#define PINNAMES_H

#ifdef __cplusplus
extern "C" {
#endif

#include "main.h"

typedef enum {
  pButton0            = Button0_Pin          | 0x10000U,
  pNFC_Int            = NFC_Int_Pin          | 0x00000U,
  pRF_Switch          = RF_Switch_Pin        | 0x00000U,
  pTemp_Int           = TEMP_Int_Pin         | 0x00000U,
  pSX126x_SPI_NSS     = SX126x_SPI_NSS_Pin   | 0x00000U,
  pSX126x_SPI_SCK     = SX126x_SPI_SCK_Pin   | 0x00000U,
  pSX126x_SPI_MISO    = SX126x_SPI_MISO_Pin  | 0x00000U,
  pSX126x_SPI_MOSI    = SX126x_SPI_MOSI_Pin  | 0x00000U,
  pLED_1              = LED_1_Pin            | 0x00000U,
  pLED_2              = LED_2_Pin            | 0x00000U,
  pSX126x_Busy        = SX126x_Busy_Pin      | 0x00000U,
  pSX126x_DIO1        = SX126x_DIO1_Pin      | 0x10000U,
  pSX126x_DIO3        = SX126x_DIO3_Pin      | 0x00000U,
  pSX126x_Reset       = SX126x_Reset_Pin     | 0x10000U,
  pSWDIO_STLink       = SWDIO_STLink_Pin     | 0x00000U,
  pSWCLK_STLink       = SWCLK_STLink_Pin     | 0x00000U,
  pDC_Conv_Mode       = DC_Conv_Mode_Pin     | 0x00000U,
  pLight_Int          = LIGHT_Int_Pin        | 0x00000U,

  // Not connected
  NC = (int)0xFFFFFFFF
} PinName;


#ifdef __cplusplus
}
#endif

#endif
