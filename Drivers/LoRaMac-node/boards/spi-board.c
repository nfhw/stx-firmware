/*!
 * \file      spi-board.c
 *
 * \brief     Target board SPI driver implementation
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
#include "stm32l0xx.h"
#include "boards/utilities.h"
#include "boards/board.h"
#include "system/gpio.h"
#include "spi-board.h"
#include <stdlib.h>
#include "spi.h"
#include "system/spi.h"

extern SPI_HandleTypeDef hspi1;

void SpiInit( Spi_t *obj, SpiId_t spiId, PinNames mosi, PinNames miso, PinNames sclk, PinNames nss )
{
    CRITICAL_SECTION_BEGIN( );

    if(spiId == SPI_1) {
        __HAL_RCC_SPI1_FORCE_RESET( );
        __HAL_RCC_SPI1_RELEASE_RESET( );
        __HAL_RCC_SPI1_CLK_ENABLE( );

        hspi1.Instance = ( SPI_TypeDef* )SPI1_BASE;

        GpioInit( &obj->Mosi, mosi, PIN_ALTERNATE_FCT, PIN_PUSH_PULL, PIN_PULL_DOWN, GPIO_AF0_SPI1 );
        GpioInit( &obj->Miso, miso, PIN_ALTERNATE_FCT, PIN_PUSH_PULL, PIN_PULL_DOWN, GPIO_AF0_SPI1 );
        GpioInit( &obj->Sclk, sclk, PIN_ALTERNATE_FCT, PIN_PUSH_PULL, PIN_PULL_DOWN, GPIO_AF0_SPI1 );
        GpioInit( &obj->Nss, nss, PIN_ALTERNATE_FCT, PIN_PUSH_PULL, PIN_PULL_UP, GPIO_AF0_SPI1 );
    }

    if( nss == NC )
    {
        hspi1.Init.NSS = SPI_NSS_SOFT;
        SpiFormat( obj, SPI_DATASIZE_8BIT, SPI_POLARITY_LOW, SPI_PHASE_1EDGE, 0 );
    }
    else
    {
        SpiFormat( obj, SPI_DATASIZE_8BIT, SPI_POLARITY_LOW, SPI_PHASE_1EDGE, 1 );
    }
    SpiFrequency( obj, 10000000 );

    HAL_SPI_Init( &hspi1 );

    CRITICAL_SECTION_END( );
}

void SpiFormat( Spi_t *obj, int8_t bits, int8_t cpol, int8_t cpha, int8_t slave )
{
  hspi1.Init.Direction = SPI_DIRECTION_2LINES;
    if( bits == SPI_DATASIZE_8BIT )
    {
      hspi1.Init.DataSize = SPI_DATASIZE_8BIT;
    }
    else
    {
      hspi1.Init.DataSize = SPI_DATASIZE_16BIT;
    }
    hspi1.Init.CLKPolarity = cpol;
    hspi1.Init.CLKPhase = cpha;
    hspi1.Init.FirstBit = SPI_FIRSTBIT_MSB;
    hspi1.Init.TIMode = SPI_TIMODE_DISABLE;
    hspi1.Init.CRCCalculation = SPI_CRCCALCULATION_DISABLE;
    hspi1.Init.CRCPolynomial = 7;

    if( slave == 0 )
    {
      hspi1.Init.Mode = SPI_MODE_MASTER;
    }
    else
    {
      hspi1.Init.Mode = SPI_MODE_SLAVE;
    }
}

void SpiFrequency( Spi_t *obj, uint32_t hz )
{
    uint32_t divisor = 0;
    uint32_t sysClkTmp = SystemCoreClock;
    uint32_t baudRate;

    while( sysClkTmp > hz )
    {
        divisor++;
        sysClkTmp = ( sysClkTmp >> 1 );

        if( divisor >= 7 )
        {
            break;
        }
    }

    baudRate =( ( ( divisor & 0x4 ) == 0 ) ? 0x0 : SPI_CR1_BR_2 ) |
              ( ( ( divisor & 0x2 ) == 0 ) ? 0x0 : SPI_CR1_BR_1 ) |
              ( ( ( divisor & 0x1 ) == 0 ) ? 0x0 : SPI_CR1_BR_0 );

    hspi1.Init.BaudRatePrescaler = baudRate;
}

uint16_t SpiInOut(Spi_t *obj, uint16_t outData) {
    uint8_t rxData = 0;

    if(obj == NULL || hspi1.Instance == NULL) {
        assert_param(LMN_STATUS_ERROR);
    }

    __HAL_SPI_ENABLE(&hspi1);

    CRITICAL_SECTION_BEGIN();

    while(__HAL_SPI_GET_FLAG(&hspi1, SPI_FLAG_TXE) == RESET);
    hspi1.Instance->DR = (uint16_t)(outData & 0xFF);

    while(__HAL_SPI_GET_FLAG(&hspi1, SPI_FLAG_RXNE) == RESET);
    rxData = (uint16_t)hspi1.Instance->DR;

    CRITICAL_SECTION_END();

    return rxData;
}

