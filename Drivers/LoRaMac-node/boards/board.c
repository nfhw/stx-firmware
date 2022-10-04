/*!
 * \file      board.c
 *
 * \brief     Target board general functions implementation
 *
 * \copyright Revised BSD License, see section \ref LICENSE.
 *
 * \code
 *                ______                              _
 *               / _____)             _              | |
 *              ( (____  _____ ____ _| |_ _____  ____| |__
 *               \____ \| ___ |    (_   _) ___ |/ ___)  _ \
 *               _____) ) ____| | | || |_| ____( (___| | | |
 *              (______/|_____)_|_|_| \__)_____)\____)_| |_|
 *              (C)2013-2017 Semtech
 *
 * \endcode
 *
 * \author    Miguel Luis ( Semtech )
 *
 * \author    Gregory Cristian ( Semtech )
 */
#include <string.h>
#include <assert.h>
#include "stm32l0xx.h"
#include "utilities.h"
#include "gpio.h"
#include "spi.h"
#include "i2c.h"
#include "system/timer.h"
#include "sysIrqHandlers.h"
#include "board-config.h"
#include "lpm-board.h"
#include "rtc-board.h"

#if defined( SX1261MBXBAS ) || defined( SX1262MBXCAS ) || defined( SX1262MBXDAS )
    #include "sx126x-board.h"
#endif
#include "board.h"

/*!
 * Unique Devices IDs register set ( STM32L0xxx )
 */
#define         ID1                                 ( 0x1FF80050 )
#define         ID2                                 ( 0x1FF80054 )
#define         ID3                                 ( 0x1FF80064 )

void BoardCriticalSectionBegin( uint32_t *mask )
{
    *mask = __get_PRIMASK( );
    __disable_irq( );
}

void BoardCriticalSectionEnd( uint32_t *mask )
{
    __set_PRIMASK( *mask );
}

void BoardResetMcu( void )
{
    CRITICAL_SECTION_BEGIN( );

    //Restart system
    NVIC_SystemReset( );
}

void BoardDeInitMcu( void )
{
#if defined( SX1261MBXBAS ) || defined( SX1262MBXCAS ) || defined( SX1262MBXDAS )
    SpiDeInit( &SX126x.Spi );
    SX126xIoDeInit( );
#endif
}

uint32_t BoardGetRandomSeed( void )
{
    return ( ( *( uint32_t* )ID1 ) ^ ( *( uint32_t* )ID2 ) ^ ( *( uint32_t* )ID3 ) );
}

/* NAME
 *        GetUniqueId - value to use for (TTN) Device EUI.
 *
 * NOTES
 *        STM32L0x1 has 12 byte Unique Device ID (rm0377/28.2#page=833)
 *        in Factory Option Bytes (rm0377/Table3#page=54).
 *        But since the ID must be 8 bytes, we need to get creative.
 */
void BoardGetUniqueId(uint8_t *DevEui) {
  uint32_t w0 = HAL_GetUIDw0();
  uint32_t w1 = HAL_GetUIDw1();
  uint32_t w2 = HAL_GetUIDw2();

  // Assumptions
  assert((w0 & 0x00FF0000) == 0x00470000); // workaroundable
  assert((w0 & 0x0000F0F0) == 0x00003030); // important
  assert((w1 & 0xF0F0F0F0) == 0x30303030); // important
  assert((w1 >>  0 & 0x0F) < 9); // important
  assert((w1 >>  8 & 0x0F) < 9); // important
  assert((w1 >> 16 & 0x0F) < 9); // important
  assert((w1 >> 24 & 0x0F) < 9); // important
  assert((w0 >>  0 & 0x0F) < 9); // important
  assert((w0 >>  8 & 0x0F) < 9); // important
  assert((w2 & 0xFF00FF00) == 0x00000000); // workaroundable

  /* Known variables
   * ---------------
   */
  // ceil: 0xf423f == 999999 (20-bits, 2.5 bytes)
  uint32_t lotnr =
    (w1 >>  0 & 0x0F) *      1 +
    (w1 >>  8 & 0x0F) *     10 +
    (w1 >> 16 & 0x0F) *    100 +
    (w1 >> 24 & 0x0F) *   1000 +
    (w0 >>  0 & 0x0F) *  10000 +
    (w0 >>  8 & 0x0F) * 100000;
  uint8_t wafnr = w0 >> 24 & 0xFF;
  uint16_t uuid =
    ((w2 & 0x000000FF) >> 0 & 0x00FF) |
    ((w2 & 0x00FF0000) >> 8 & 0xFF00);

  /* Apparent constants
   * ------------------
   */
  uint8_t lotchar = (w0 & 0x00FF0000) >> 16;  // = 0x47
  uint8_t uid0    = (w2 & 0x0000FF00) >> 8;   // = 0x00
  uint8_t uid1    = (w2 & 0xFF000000) >> 24;  // = 0x00
  uint8_t bitmask = 0;
  bitmask |= 0x47U == lotchar ? 0 : 0x01;
  bitmask |= 0x00U == uid0    ? 0 : 0x02;
  bitmask |= 0x00U == uid1    ? 0 : 0x04;

  /* Assemble Unique ID
   * ------------------
   * unique cost: 5.5 bytes (lotnr:2.5 wafnr:1 uuid:2)
   * supply left: 2.5 bytes (bitmask:0.5 X:1 Y:1)
   * needed cost: 3.0 bytes (uid0:1 uid1:1 lotchar:1)
   */

  /* | bitmask | uniq[3] | uniq[2] | notes               |
   * |---------|---------|---------|---------------------|
   * | 0000    | uid0    | lotchar |                     |
   * | 0001    | uid0    | lotchar |                     |
   * | 0010    | uid0    | lotchar |                     |
   * | 0011    | uid0    | lotchar |                     |
   * | 0100    | uid1    | lotchar |                     |
   * | 0101    | uid1    | lotchar |                     |
   * | 0110    | uid1    | uid0    |                     |
   * | 0111    | uid1    | uid0    | Collision possible! |
   */
  DevEui[0] = (uuid & 0x00FF) >> 0;
  DevEui[1] = (uuid & 0xFF00) >> 8;
  DevEui[2] = (bitmask & 0x6) == 0x06 ? uid0 : lotchar;
  DevEui[3] = (bitmask & 0x4) == 0x04 ? uid1 : uid0;
  DevEui[4] = wafnr;
  DevEui[5] = (lotnr & 0x0000FF) >>  0;
  DevEui[6] = (lotnr & 0x00FF00) >>  8;
  DevEui[7] = (lotnr & 0x0F0000U) >> 16 | ((unsigned)bitmask << 4);
}

/**
  * \brief Enters Low Power Stop Mode
  *
  * \note ARM exists the function when waking up
  */
void LpmEnterStopMode( void)
{
    CRITICAL_SECTION_BEGIN( );

    BoardDeInitMcu( );

    // Disable the Power Voltage Detector
    HAL_PWR_DisablePVD( );

    // Clear wake up flag
    SET_BIT( PWR->CR, PWR_CR_CWUF );

    // Enable Ultra low power mode
    HAL_PWREx_EnableUltraLowPower( );

    // Enable the fast wake up from Ultra low power mode
    HAL_PWREx_EnableFastWakeUp( );

    CRITICAL_SECTION_END( );

    // Enter Stop Mode
    HAL_PWR_EnterSTOPMode( PWR_LOWPOWERREGULATOR_ON, PWR_STOPENTRY_WFI );
}

/*!
 * \brief Exists Low Power Stop Mode
 */
void LpmExitStopMode( void )
{
    // Disable IRQ while the MCU is not running on HSI
    CRITICAL_SECTION_BEGIN( );

    // Initilizes the peripherals
    BoardInitMcu( );

    CRITICAL_SECTION_END( );
}

/*!
 * \brief Enters Low Power Sleep Mode
 *
 * \note ARM exits the function when waking up
 */
void LpmEnterSleepMode( void)
{
    HAL_PWR_EnterSLEEPMode(PWR_MAINREGULATOR_ON, PWR_SLEEPENTRY_WFI);
}

void BoardLowPowerHandler( void )
{
    __disable_irq( );
    /*!
     * If an interrupt has occurred after __disable_irq( ), it is kept pending 
     * and cortex will not enter low power anyway
     */

    LpmEnterLowPower( );

    __enable_irq( );
}
