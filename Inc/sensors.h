#ifndef __SENSORS_H
#define __SENSORS_H
#ifdef __cplusplus
extern "C" {
#endif

#include "main.h"

enum Send_Trigger {
  SEND_TRIGGER_ALWAYS,
  SEND_TRIGGER_ON_CHANGE,
};

enum Send_Strategy {
  SEND_STRATEGY_PERIODIC,
  SEND_STRATEGY_INSTANT,
  SEND_STRATEGY_BOTH,
};

#ifdef BMA400
void BMA400_ForeverTest(void);
void BMA400_Init(uint16_t, uint16_t);
void BMA400_Read(void);
void BMA400_Reset(void);

extern struct BMA400_Handle bma400;
struct BMA400_Handle {
  struct bma400_dev *p;
  uint16_t status;  /* Interrupt status, not quite IC register representation */
  int16_t fix_x;    /* scale 100 fixed-point value representation, m/s^2 */
  int16_t fix_y;    /* scale 100 fixed-point value representation, m/s^2 */
  int16_t fix_z;    /* scale 100 fixed-point value representation, m/s^2 */
  int16_t fix_x_ref;    /* scale 100 fixed-point value representation, m/s^2 */
  int16_t fix_y_ref;    /* scale 100 fixed-point value representation, m/s^2 */
  int16_t fix_z_ref;    /* scale 100 fixed-point value representation, m/s^2 */
  int16_t raw_x;     /* IC register raw byte representation, signed ratio */
  int16_t raw_y;     /* IC register raw byte representation, signed ratio */
  int16_t raw_z;     /* IC register raw byte representation, signed ratio */
  int8_t raw_x_ref;  /* IC register raw byte representation, signed ratio */
  int8_t raw_y_ref;  /* IC register raw byte representation, signed ratio */
  int8_t raw_z_ref;  /* IC register raw byte representation, signed ratio */
};
#endif

#ifdef SFH7776
void SFH7776_ForeverTest(void);
void SFH7776_Init(uint16_t, uint16_t);
void SFH7776_Read(void);
void SFH7776_Reset(void);

extern struct SFH7776_Handle sfh7776;
struct SFH7776_Handle {
	uint16_t als_vis;
	uint16_t als_ir;
	uint16_t als_vis_tl;
	uint16_t lux;
};
#endif

#ifdef BME680
#ifdef BSEC
#include "bsec_datatypes.h"
void BSEC_Init(float sample_rate);
void BSEC_Read(void);
void BSEC_ForeverTest(void);
uint16_t BSEC_float(float);
#endif /* BSEC */

#include "bme680_defs.h"
void BME680_Init(void);
void BME680_Read(void);
void BME680_ReadOld(void);

extern struct BME680_Handle bme680;
struct BSEC_Handle {
  int64_t next_call;
  float iaq;
  float co2;
  float voc;
  unsigned acc;
};
struct BME680_Handle {
  struct bme680_dev dev;
  struct bme680_field_data data;
#ifdef BSEC
  struct BSEC_Handle bsec;
#endif
};

#endif /* BME680 */

#ifdef HDC2080
enum HDC2080_Threshold {
  HDC2080_TEMPERATURE_LOW,
  HDC2080_TEMPERATURE_HIGH,
  HDC2080_HUMIDITY_LOW,
  HDC2080_HUMIDITY_HIGH,
};

void HDC2080_ForeverTest(void);
void HDC2080_Init(enum HDC2080_Threshold type, int32_t thres);
void HDC2080_Read(void);
void HDC2080_Reset(void);

extern struct HDC2080_Handle hdc2080;
struct HDC2080_Handle {
  uint16_t raw_temp;   /* IC register raw byte representation, unsigned ratio   C = RAW / 65536.0 * 165 - 40 */
  uint16_t raw_humid;  /* IC register raw byte representation, unsigned ratio, rH = RAW / 65536.0 * 100 */
  int16_t fix_temp;  /* scale 100 fixed-point value representation, [-4000, 12499] Celsius */
  uint8_t humid;     /* integer value representation, [0, 99] */
  uint8_t status;
};
#endif

#ifdef __cplusplus
}
#endif
#endif /* __SENSORS_H */
