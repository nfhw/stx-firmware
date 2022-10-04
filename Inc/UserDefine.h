/*

  __  __ _       _
 |  \/  (_)     (_)
 | \  / |_ _ __  _ _ __ ___   ___  _   _ ___  ___
 | |\/| | | '_ \| | '_ ` _ \ / _ \| | | / __|/ _ \
 | |  | | | | | | | | | | | | (_) | |_| \__ \  __/
 |_|  |_|_|_| |_|_|_| |_| |_|\___/ \__,_|___/\___|


Description       : User Define for loraMac Layer.


License           : Revised BSD License, see LICENSE.TXT file include in the project

Maintainer        : Fabien Holin (SEMTECH)
*/
#ifndef USERDEFINE_H
#define USERDEFINE_H
#define SX126x_BOARD 1
#include "PinNames.h"

/********************************************************************************/
/*                         Application     dependant                            */
/********************************************************************************/
#define DEBUG_TRACE    0      // set to 1 to activate debug traces
#define LOW_POWER_MODE 0      // set to 1 to activate sleep mode , set to 0 to replace by wait functions (easier in debug mode)
#define DEBUG_TRACE_ENABLE 0 // Set to 1 to activate DebugTrace

#define LOW_SPEED_CLK  LSE    // Low Speed External Clock based on XTAL

#ifdef SX126x_BOARD
/*SX126w BOARD specific */
#define LORA_SPI_MOSI             pSX126x_SPI_MOSI
#define LORA_SPI_MISO             pSX126x_SPI_MISO
#define LORA_SPI_SCLK             pSX126x_SPI_SCK
#define LORA_CS                   pSX126x_SPI_NSS
#define LORA_RESET                pSX126x_Reset
#define TX_RX_IT                  pSX126x_DIO1
//#define RX_TIMEOUT_IT   D14 // @TODO: Not required for 126x
#define LORA_BUSY                 pSX126x_Busy
// We use no crystal but RC Oscillator, so error is very high
#define CRYSTAL_ERROR             70 // Crystal error of the MCU to fine adjust the rx window for lorawan ( ex: set 3² for a crystal error = 0.3%)
#define BOARD_DELAY_RX_SETTING_MS 7 // Time to configure board in rx mode
#define PA_BOOST_CONNECTED        0

/*SX1276 BOARD specific */
#else
#define LORA_SPI_MOSI       D11
#define LORA_SPI_MISO       D12
#define LORA_SPI_SCLK       D13
#define LORA_CS             D10
#define LORA_RESET          A0
#define TX_RX_IT            D2     // Interrupt TX/RX Done
#define CRYSTAL_ERROR              20 // Crystal error of the MCU to fine adjust the rx window for lorawan ( ex: set 3
#endif
#define RX_TIMEOUT_IT       D3     // Interrupt RX TIME OUT
#define FLASH_UPDATE_PERIOD 32      // The Lorawan context is stored in memory with a period equal to FLASH_UPDATE_PERIOD packets transmitted

#define USER_NUMBER_OF_RETRANSMISSION   1// Only used in case of user defined darate distribution strategy
#define USER_DR_DISTRIBUTION_PARAMETERS 0x00000100  // Only used in case of user defined darate distribution strategy refered to doc that explain this value

#endif

