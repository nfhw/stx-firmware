/*
        HDC2080.h
        HDC2010.h originally created by: Brandon Fisher, August 1st 2017

        This code is release AS-IS into the public domain, no guarantee or warranty is given.

        Description: This header file accompanies HDC2080.cpp, and declares all methods, fields,
        and constants used in the source code.
*/

#ifndef HDC2080_H_
#define HDC2080_H_

//---------------------I2C Address------------------------------
#define HDC2080_I2C_ADDR        0x80U

//----------------------Registers-------------------------------
#define HDC2080_TEMP            0x00U
#define HDC2080_HUMID           0x02U
#define HDC2080_STATUS          0x04U
#define HDC2080_TEMP_MAX        0x05U
#define HDC2080_HUMID_MAX       0x06U
#define HDC2080_INT_ENABLE      0x07U
#define HDC2080_OFFSET_TEMP     0x08U
#define HDC2080_OFFSET_HUMID    0x09U
#define HDC2080_TEMP_TL         0x0aU
#define HDC2080_TEMP_TH         0x0bU
#define HDC2080_HUMID_TL        0x0cU
#define HDC2080_HUMID_TH        0x0dU
#define HDC2080_CONFIG          0x0eU
#define HDC2080_MEASURE         0x0fU
#define HDC2080_MANUFACTURERID  0xfcU
#define HDC2080_DEVICEID        0xfeU

//-----------------------Values---------------------------------

//  Constants for setting measurement resolution
#define FOURTEEN_BIT 0
#define ELEVEN_BIT 1
#define NINE_BIT  2

//  Constants for setting sample rate
#define MANUAL                  0
#define TWO_MINS                1
#define ONE_MINS                2
#define TEN_SECONDS             3
#define FIVE_SECONDS            4
#define ONE_HZ                  5
#define TWO_HZ                  6
#define FIVE_HZ                 7

//  Constants for setting sensor mode
#define TEMP_AND_HUMID     0
#define TEMP_ONLY          1
#define HUMID_ONLY         2
#define ACTIVE_LOW         0
#define ACTIVE_HIGH        1
#define LEVEL_MODE         0
#define COMPARATOR_MODE    1

#endif
