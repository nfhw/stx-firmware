#include <inttypes.h>
#include <stdarg.h>
#include <string.h>

#include "hardware.h"
#include "stm32l0xx_hal_conf.h"
#include "i2c.h"
#include "cryptoauthlib.h"
#include "atca_devtypes.h"

#ifndef ATAC_HAL_MBED_MAX_I2C
#define ATAC_HAL_MBED_MAX_I2C       1
#endif

// HAL structure, use this to store data
typedef struct {
    bool active;
    uint8_t slave_address;
    uint8_t bus;
    uint32_t baud;
    uint16_t wake_delay;
    int rx_retries;
    I2C_TypeDef *i2c;
} mbed_i2c_hal_data_t;

// Hold all active HAL structures
static mbed_i2c_hal_data_t mbed_i2c_hal_data[ATAC_HAL_MBED_MAX_I2C];
static bool mbed_i2c_hal_first_init = true;


void atca_delay_us(uint32_t delay) {
  HAL_Delay(delay / 1000);
}

void atca_delay_10us(uint32_t delay) {
  HAL_Delay(delay / 100);
}

void atca_delay_ms(uint32_t delay) {
  HAL_Delay(delay);
}


/** \brief hal_i2c_init manages requests to initialize a physical interface.  it manages use counts so when an interface
 * has released the physical layer, it will disable the interface for some other use.
 * You can have multiple ATCAIFace instances using the same bus, and you can have multiple ATCAIFace instances on
 * multiple i2c buses, so hal_i2c_init manages these things and ATCAIFace is abstracted from the physical details.
 */

/** \brief initialize an I2C interface using given config
 * \param[in] hal - opaque ptr to HAL data
 * \param[in] cfg - interface configuration
 * \return ATCA_SUCCESS on success, otherwise an error code.
 */
ATCA_STATUS hal_i2c_init(void *hal, ATCAIfaceCfg *cfg) {
    if (mbed_i2c_hal_first_init) {
       // mbed_i2c = new I2C(MBED_CONF_CRYPTOAUTHLIB_I2C_SDA, MBED_CONF_CRYPTOAUTHLIB_I2C_SCL);
    	HAL_I2C_MspInit(&hi2c1);
        for (size_t ix = 0; ix < ATAC_HAL_MBED_MAX_I2C; ix++) {
            mbed_i2c_hal_data[ix].active = false;
        }
        mbed_i2c_hal_first_init = false;
    }

    if (cfg->iface_type != ATCA_I2C_IFACE) {
        return ATCA_BAD_PARAM;
    }

    // OK... Let's find an unused item...
    mbed_i2c_hal_data_t *hal_data = NULL;
    for (size_t ix = 0; ix < ATAC_HAL_MBED_MAX_I2C; ix++) {
        if (!mbed_i2c_hal_data[ix].active) {
            hal_data = &mbed_i2c_hal_data[ix];
            break;
        }
    }

    if (!hal_data) {
    	DBG_PRINTF("Could not find unallocated mbed_i2c_hal_data_t structure");
        return ATCA_ALLOC_FAILURE;
    }

    // tr_debug("hal_i2c_init, slave_address=%u, bus=%u, baud=%lu, wake_delay=%u, rx_retries=%d",
    //     cfg->atcai2c.slave_address, cfg->atcai2c.bus, cfg->atcai2c.baud, cfg->wake_delay, cfg->rx_retries);

    hal_data->active = true;
	hal_data->slave_address = cfg->atcai2c.slave_address;
    hal_data->bus = cfg->atcai2c.bus;
    // the CryptoAuth Xplained Pro modules don't seem to work at 400Khz. Allow overriding.
#if MBED_CONF_CRYPTOAUTHLIB_I2C_FORCE_FREQUENCY != 0
    hal_data->baud = MBED_CONF_CRYPTOAUTHLIB_I2C_FORCE_FREQUENCY; // @todo: cfg->atcai2c.baud; <-- this does not work on a variety of boards
#else
    hal_data->baud = cfg->atcai2c.baud;
#endif
    hal_data->wake_delay = cfg->wake_delay;
    hal_data->rx_retries = cfg->rx_retries;

    // @todo, bus is ignored, and we only search primary bus. This needs to be fixed.
//    mbed_i2c->frequency(hal_data->baud);
    hal_data->i2c = I2C1;

    ((ATCAHAL_t*)hal)->hal_data = hal_data;

    return ATCA_SUCCESS;
}

ATCA_STATUS hal_i2c_post_init(ATCAIface iface) {
  return ATCA_SUCCESS;
}

/** \brief HAL implementation of I2C send over ASF
 * \param[in] iface     instance
 * \param[in] txdata    pointer to space to bytes to send
 * \param[in] txlength  number of bytes to send
 * \return ATCA_SUCCESS on success, otherwise an error code.
 */
ATCA_STATUS hal_i2c_send(ATCAIface iface, uint8_t word_address, uint8_t *txdata, int txlength) {
    mbed_i2c_hal_data_t *hal_data = (mbed_i2c_hal_data_t*)(iface->hal_data);
//    DBG_PRINTF("hal_i2c_send length=%d", txlength);

    // for this implementation of I2C with CryptoAuth chips, txdata is assumed to have ATCAPacket format

    // other device types that don't require i/o tokens on the front end of a command need a different hal_i2c_send and wire it up instead of this one
    // this covers devices such as ATSHA204A and ATECCx08A that require a word address value pre-pended to the packet
    // txdata[0] is using _reserved byte of the ATCAPacket
    txdata[0] = 0x3;    // insert the Word Address Value, Command token
    txlength++;         // account for word address value byte.

//    int r = hal_data->i2c->write(hal_data->slave_address, (char*)txdata, txlength);
      int r;
    r = HAL_I2C_Master_Transmit(&hi2c1, 0xC0, txdata, txlength, 100);
//    DBG_PRINTF("hal_i2c_send returned %x", r);
    if (r != 0) {
        return ATCA_TX_FAIL;
    }
    return ATCA_SUCCESS;
}

ATCA_STATUS hal_i2c_receive(ATCAIface iface, uint8_t word_address, uint8_t *rxdata, uint16_t *rxlength) {
    mbed_i2c_hal_data_t *hal_data = (mbed_i2c_hal_data_t*)(iface->hal_data);

    // read procedure is:
    // 1. read 1 byte, this will be the length of the package
    // 2. read the rest of the package

    uint8_t lengthPackage[1] = { 0 };
    int r = -1;
    int retries = hal_data->rx_retries;
    while (--retries > 0 && r != 0) {
        //r = hal_data->i2c->read(hal_data->slave_address, lengthPackage, 1);
    	r = HAL_I2C_Master_Receive(&hi2c1, 0xC0, lengthPackage, 1, 100);
    }

    if (r != 0) {
        return ATCA_RX_TIMEOUT;
    }

    uint8_t bytesToRead = lengthPackage[0] - 1;

    if (bytesToRead > *rxlength) {
    	DBG_PRINTF("hal_i2c_receive buffer too small, requested %u, but have %u", bytesToRead, *rxlength);
        return ATCA_SMALL_BUFFER;
    }

    memset(rxdata, 0, *rxlength);
    rxdata[0] = lengthPackage[0];

    r = -1;
    retries = hal_data->rx_retries;
    while (--retries > 0 && r != 0) {
        //r = hal_data->i2c->read(hal_data->slave_address, (char*)rxdata + 1, bytesToRead);
    	r = HAL_I2C_Master_Receive(&hi2c1, 0xC0, rxdata+1, bytesToRead, 100);
    }

    if (r != 0) {
        return ATCA_RX_TIMEOUT;
    }

    *rxlength = lengthPackage[0];

    return ATCA_SUCCESS;
}


ATCA_STATUS hal_i2c_wake(ATCAIface iface)
{
   HAL_I2C_Master_Transmit(&hi2c1, 0x00, 0x00, 1, 100);
   return ATCA_SUCCESS;
}

ATCA_STATUS hal_i2c_idle(ATCAIface iface)
{
	 mbed_i2c_hal_data_t *hal_data = (mbed_i2c_hal_data_t*)(iface->hal_data);

	 uint8_t buffer[1] = { 0x2 }; // idle word address value
	 HAL_StatusTypeDef r;
     r = HAL_I2C_Master_Transmit(&hi2c1, 0xC0, buffer, 1, 100);

    return ATCA_SUCCESS;
}

ATCA_STATUS hal_i2c_sleep(ATCAIface iface)
{
	mbed_i2c_hal_data_t *hal_data = (mbed_i2c_hal_data_t*)(iface->hal_data);

	uint8_t buffer[1] = { 0x1 };  // sleep word address value
	HAL_StatusTypeDef r;
	r = HAL_I2C_Master_Transmit(&hi2c1, 0xC0, buffer, 1, 100);

    return ATCA_SUCCESS;
}

ATCA_STATUS hal_i2c_release(void *hal_data) {

	mbed_i2c_hal_data_t *data = (mbed_i2c_hal_data_t*)hal_data;

	    if (data->i2c) {
	        // is now static, don't delete
	    }
	    data->active = false;

    return ATCA_SUCCESS;
}

ATCA_STATUS hal_i2c_discover_buses(int i2c_buses[], int max_buses)
{
    return ATCA_UNIMPLEMENTED;
}

ATCA_STATUS hal_i2c_discover_devices(int bus_num, ATCAIfaceCfg *cfg, int *found)
{
    return ATCA_UNIMPLEMENTED;
}
