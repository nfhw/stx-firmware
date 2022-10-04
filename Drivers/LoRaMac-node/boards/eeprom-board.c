/*!
 * \file      eeprom-board.c
 *
 * \brief     Target board EEPROM driver implementation
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
#include <stdlib.h>
#include "stm32l0xx.h"
#include "stm32l0xx_hal.h"
#include "boards/utilities.h"
#include "eeprom-board.h"
#include "hardware.h"

LmnStatus_t EepromMcuWriteBuffer( uint16_t addr, uint8_t *buffer, uint16_t size )
{
    LmnStatus_t status = LMN_STATUS_ERROR;

    assert_param( ( EEPROM_LORA + addr ) >= EEPROM_LORA );
    assert_param( buffer != NULL );
    assert_param( size < ( EEPROM_LORA_END - EEPROM_LORA ) );

    if( HAL_FLASHEx_DATAEEPROM_Unlock( ) == HAL_OK )
    {
        CRITICAL_SECTION_BEGIN( );
        for( uint16_t i = 0; i < size; i++ )
        {
            if( HAL_FLASHEx_DATAEEPROM_Program( FLASH_TYPEPROGRAMDATA_BYTE,
                                                ( EEPROM_LORA + addr + i ),
                                                  buffer[i] ) != HAL_OK )
            {
                // Failed to write EEPROM
                break;
            }
        }
        CRITICAL_SECTION_END( );
        status = LMN_STATUS_OK;
    }

    HAL_FLASHEx_DATAEEPROM_Lock( );
    return status;
}

LmnStatus_t EepromMcuReadBuffer( uint16_t addr, uint8_t *buffer, uint16_t size )
{
    assert_param( ( EEPROM_LORA + addr ) >= EEPROM_LORA );
    assert_param( buffer != NULL );
    assert_param( size < ( EEPROM_LORA_END - EEPROM_LORA ) );

    memcpy1( buffer, ( uint8_t* )( EEPROM_LORA + addr ), size );
    return LMN_STATUS_OK;
}

void EepromMcuSetDeviceAddr( uint8_t addr )
{
    assert_param( LMN_STATUS_ERROR );
}

LmnStatus_t EepromMcuGetDeviceAddr( void )
{
    assert_param( LMN_STATUS_ERROR );
    return 0;
}
