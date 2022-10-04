#include "adc.h"
#include "dma.h"
#include "i2c.h"
#include "rtc.h"
#include "spi.h"
#include "gpio.h"
#include "main.h"
#include "bma400.h"
#include "sfh7776.h"
#include "hdc2080.h"
#include "sensors.h"
#include "hardware.h"
#include "eeprom.h"
#include <assert.h>
#include <math.h>

#ifdef BMA400
struct bma400_dev bma;
struct BMA400_Handle bma400;

/* NAME
 *        BMA400_Init - Initialize BMA400 Bosch Accelerometer
 *
 * DESCRIPTION
 *    Reference X/Y/Z-axes
 *        Since gravity is also acceleration, reference is meant to account for it, e.g. {0,0,9}.
 *        Merely flipping device over can cause ~2g difference.
 *
 *        The BMA400_ONE_TIME_UPDATE could be used to detect orientation change.
 *        The BMA400_EVERY_TIME_UPDATE could be used to detect crudely linear acceleration.
 *
 *    Interrupt Status
 *        Electrical behavior of INT Pin is configurable. Currently MCU is
 *        Hi-Z and IC push-pull. Trigger on rising edge.
 *        IC active level lasts 80ms, when Auto Low Power is enabled with
 *        timeout of 0 (regardless of Latch Mode).
 *        Yes, Latch Mode is ineffective with Auto Low Power, and Auto Low
 *        Power prolongs active level from 40ms to 80ms due wakeup time of
 *        2/ODR.
 *
 *    Run Modes (OSR=0 ODR=25Hz)
 *        - Sleep Mode       200 nA ~  160 nA  powerup in 1 ms
 *        - Normal Mode    14500 nA ~ 3500 nA  wakeup in 80 ms  800 Hz .. 12.5 Hz
 *        - Low Power Mode  1200 nA ~  850 nA                    25 Hz
 *
 *    Assumptions
 *        A 1 g is 9.80665 m/s², and 1 mg is 0.001 g.
 *
 * SEE ALSO
 *    https://github.com/BoschSensortec/BMA400-API
 *        Upstream driver, contains examples (none for low power mode).
 *    https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bma400-ds000.pdf
 *        Datasheet.
 */
void BMA400_Init(uint16_t config, uint16_t threshold) {
  int32_t r, c;

  bma400.p = &bma;

  /* Initialize BMA400 Driver */
  bma.dev_id = BMA400_I2C_ADDRESS_SDO_LOW; /* I2C device address is 0x80 */
  bma.intf = BMA400_I2C_INTF;              /* I2C interface used */
  bma.intf_ptr = &hi2c1;      /* Hook I2C1 peripheral handle to driver */
  bma.delay_ms = delay_ms;    /* Hook HAL_Delay to driver */
  bma.read = i2c_reg_read;    /* Hook HAL_I2C_Mem_Read to driver */
  bma.write = i2c_reg_write;  /* Hook HAL_I2C_Mem_Write to driver */

  if((r = bma400_init(&bma))) {c = 0x1; goto err;};

  if((r = bma400_soft_reset(&bma))) {c = 0x2; goto err;};

  /* Configure Acceleration */
  struct bma400_sensor_conf sconf;
  sconf.type = BMA400_ACCEL;

  if((r = bma400_get_sensor_conf(&sconf, 1, &bma))) {c = 0x3; goto err;};

  sconf.param.accel.odr = BMA400_ODR_25HZ;
  sconf.param.accel.range = BMA400_2G_RANGE;
  sconf.param.accel.data_src = BMA400_DATA_SRC_ACCEL_FILT_1;
  sconf.param.accel.osr = (config & 0x300) >> 8;

  if((r = bma400_set_sensor_conf(&sconf, 1, &bma))) {c = 0x4; goto err;};
  bma.delay_ms(100);

  /* Configure Wake Up Interrupt */
  struct bma400_device_conf dconf;
  dconf.type = BMA400_AUTOWAKEUP_INT;

  if((r = bma400_get_device_conf(&dconf, 1, &bma))) {c = 0x5; goto err;};

  dconf.param.wakeup.int_wkup_threshold = round(threshold * 256 / 9.80665 / 4 / 100);                            /* Acceleration distance from reference on any X/Y/Z: N*0.153m/s^2 (15.6mg/lsb) */
  dconf.param.wakeup.sample_count = (config & 0xe) >> 1;                                                  /* Acceleration lasts atleast duration: N*40ms (25Hz samples) */
  dconf.param.wakeup.wakeup_ref_update = config & 1 ? BMA400_EVERY_TIME_UPDATE : BMA400_ONE_TIME_UPDATE;  /* Wake-up on delta acceleration, ignore gravity & orientation. */
  dconf.param.wakeup.int_chan = BMA400_INT_CHANNEL_1;
  dconf.param.wakeup.wakeup_axes_en = (config & 0x70) >> 4; /* abs((actX >> 4) - refX) > thres ||
                                                               abs((actY >> 4) - refY) > thres ||
                                                               abs((actZ >> 4) - refZ) > thres */

  if((r = bma400_set_device_conf(&dconf, 1, &bma))) {c = 0x6; goto err;};

  /* Configure Auto Low Power */
  dconf.type = BMA400_AUTO_LOW_POWER;

  if((r = bma400_get_device_conf(&dconf, 1, &bma))) {c = 0x7; goto err;};

  dconf.param.auto_lp.auto_low_power_trigger = BMA400_AUTO_LP_TIMEOUT_EN;
  dconf.param.auto_lp.auto_lp_timeout_threshold = 0;

  if((r = bma400_set_device_conf(&dconf, 1, &bma))) {c = 0x8; goto err;};

  /* Configure Interrupt Mappings */
  struct bma400_int_enable iconf[2];
  iconf[0].type = BMA400_LATCH_INT_EN;
  iconf[0].conf = BMA400_DISABLE;
  iconf[1].type = BMA400_AUTO_WAKEUP_EN;
  iconf[1].conf = BMA400_ENABLE;

  if((r = bma400_enable_interrupt(iconf, 2, &bma))) {c = 0x9; goto err;};
  bma.delay_ms(100);

  /* Configure Power Mode */
  if((r = bma400_set_power_mode(BMA400_LOW_POWER_MODE, &bma))) {c = 0xa; goto err;};

  return;
err:
  DEBUG_PRINTF("SEN BMA400 ERR ret:0x%x cond:0x%x Init Failed!\n", r, c);
  return;
}

void BMA400_Read(void) {
  struct bma400_sensor_data data;
  struct bma400_device_conf conf;
  conf.type = BMA400_AUTOWAKEUP_INT;

  bma400_get_accel_data(BMA400_DATA_ONLY, &data, &bma);
  bma400_get_device_conf(&conf, 1, &bma);
  bma400_get_interrupt_status(&bma400.status, &bma);

  bma400.raw_x = data.x;
  bma400.raw_y = data.y;
  bma400.raw_z = data.z;
  bma400.raw_x_ref = conf.param.wakeup.int_wkup_ref_x;
  bma400.raw_y_ref = conf.param.wakeup.int_wkup_ref_y;
  bma400.raw_z_ref = conf.param.wakeup.int_wkup_ref_z;
  bma400.fix_x = lsb_to_ms2(bma400.raw_x >> 4, 2, 8);
  bma400.fix_y = lsb_to_ms2(bma400.raw_y >> 4, 2, 8);
  bma400.fix_z = lsb_to_ms2(bma400.raw_z >> 4, 2, 8);
  bma400.fix_x_ref = lsb_to_ms2(bma400.raw_x_ref, 2, 8);
  bma400.fix_y_ref = lsb_to_ms2(bma400.raw_y_ref, 2, 8);
  bma400.fix_z_ref = lsb_to_ms2(bma400.raw_z_ref, 2, 8);
}

void BMA400_Reset(void) {
  bma400_soft_reset(&bma);
}

void BMA400_ForeverTest(void) {
  uint32_t ts_prev, ts_now, prev = 0;

  /* Turn off Interrupt handler */
  CLEAR_BIT(EXTI->IMR, Button0_Pin);

  /* for;ever;loop */
  for(;;) {
    /* Time value just for debug print */
    ts_now = HAL_GetTick();

    /* Manually poll interrupt pin */
    int now = HAL_GPIO_ReadPin(Button0_GPIO_Port, Button0_Pin);

    /* Read interrupt status, and X/Y/Z axes */
    BMA400_Read();

    /* Just debug logic */
    if(now != prev && now)
      DEBUG_PRINTF("TEST IRQ BMA400 PIN:0->1 X:%5d Y:%5d Z:%5d rX:%5d rY:%5d rZ:%5d IRQ:0x%04x\n",
          bma400.fix_x, bma400.fix_y, bma400.fix_z, bma400.fix_x_ref, bma400.fix_y_ref, bma400.fix_z_ref, bma400.status);
    else if(now != prev)
      DEBUG_PRINTF("TEST     BMA400 PIN:1->0 X:%5d Y:%5d Z:%5d rX:%5d rY:%5d rZ:%5d IRQ:0x%04x DUR:%4d\n",
          bma400.fix_x, bma400.fix_y, bma400.fix_z, bma400.fix_x_ref, bma400.fix_y_ref, bma400.fix_z_ref, bma400.status, ts_now - ts_prev);
    else
      DEBUG_PRINTF("TEST     BMA400 PIN:%x    X:%5d Y:%5d Z:%5d rX:%5d rY:%5d rZ:%5d IRQ:0x%04x\n",
          now, bma400.fix_x, bma400.fix_y, bma400.fix_z, bma400.fix_x_ref, bma400.fix_y_ref, bma400.fix_z_ref, bma400.status);

    /* Time duration, also just for debug print */
    ts_prev = now != prev ? ts_now : ts_prev;
    prev = now;
  }
}
#endif

#ifdef SFH7776
struct SFH7776_Handle sfh7776;

/* NAME
 *        SFH7776_Init - Configure the SFH7776 IC Luminance sensor.
 *
 * DESCRIPTION
 *    Gain
 *        Higher gain, e.g. x64 over x1, decreases lux range, but increases
 *        granularity.
 *
 *    Int Pin
 *        Open-Drain, i.e. 2 states of either Hi-Z or GND. So default state is
 *        1, and interrupt happens on 0.
 *
 * SEE ALSO
 *    https://dammedia.osram.info/media/resource/hires/osram-dam-2496477/SFH 7776.pdf#page=26
 *        Describes Int Pin.
 */
void SFH7776_Init(uint16_t upper_thres, uint16_t lower_thres) {
  int32_t r, c = 0;
  uint8_t val[4];
  uint32_t als_vis_th = fminf(roundf((uint32_t)GAIN_VIS * upper_thres / 8 / 4), UINT16_MAX);
  uint32_t als_vis_tl = fminf(roundf((uint32_t)GAIN_VIS * lower_thres / 8 / 4), UINT16_MAX);

  als_vis_th = GAIN_VIS * upper_thres / 8 / 4, als_vis_th = als_vis_th > UINT16_MAX ? UINT16_MAX : als_vis_th;
  als_vis_tl = GAIN_VIS * lower_thres / 8 / 4, als_vis_tl = als_vis_tl > UINT16_MAX ? UINT16_MAX : als_vis_tl;

  /* Communicate via NFC that threshold was lowered to maximum */
  DevCfg.sfh7776_threshold_upper = 8 * 4 * als_vis_th / GAIN_VIS;
  DevCfg.sfh7776_threshold_lower = 8 * 4 * als_vis_tl / GAIN_VIS;

  // SYSTEM_CONTROL: reset and check identity
  *val = 0x80;
  if((r = HAL_I2C_Mem_Write(&hi2c1, 0x72, SFH7776_SYSTEM_CONTROL, I2C_MEMADD_SIZE_8BIT, val, 1, 100))) {c = 0x1; goto err;};
  if((r = HAL_I2C_Mem_Read(&hi2c1, 0x72, SFH7776_SYSTEM_CONTROL, I2C_MEMADD_SIZE_8BIT, val, 1, 100))) {c = 0x2; goto err;};
  HAL_Delay(100);
  if(*val != 0x09) {c = 0x3; goto err;};

  // MODE_CONTROL: PS disabled, ALS enabled and measure for 100ms every 400ms.
  // ALS_PS_CONTROL: ALS_VIS and ALS_IR use x64 gain.
  static_assert(T_INT_ALS == 100 && GAIN_VIS == 64 && GAIN_IR == 64, "");
  val[0] = 0x08, val[1] = 0x28;
  if((r = HAL_I2C_Mem_Write(&hi2c1, 0x72, SFH7776_MODE_CONTROL, I2C_MEMADD_SIZE_8BIT, val, 2, 100))) {c = 0x4; goto err;};

  // ALS_VIS_TH: ALS upper threshold
  // ALS_VIS_TL: ALS lower threshold
  val[0] = als_vis_th, val[1] = als_vis_th >> 8, val[2] = als_vis_tl, val[3] = als_vis_tl >> 8;
  if((r = HAL_I2C_Mem_Write(&hi2c1, 0x72, SFH7776_ALS_VIS_TH_LSB, I2C_MEMADD_SIZE_8BIT, val, 4, 100))) {c = 0x5; goto err;};

  // INTERRUPT_CONTROL: ALS only, non-latched.
  *val = 0x06;
  if((r = HAL_I2C_Mem_Write(&hi2c1, 0x72, SFH7776_INTERRUPT_CONTROL, I2C_MEMADD_SIZE_8BIT, val, 1, 100))) {c = 0x6; goto err;};

  sfh7776.als_vis_tl = als_vis_tl;

  return;
err:
  DEBUG_PRINTF("SEN SFH7776 ERR ret:0x%x cond:0x%x val:0x%02x err:0x%x Init Failed!\n", r, c, *val, hi2c1.ErrorCode);
}

/* NAME
 *        SFH7776_Read - Update globals with values from IC
 *
 * DESCRIPTION
 *    Interrupt Status
 *        A 1->0 fall (slave pull to GND) happens on:
 *        a. In any-latched modes, next 400ms ALS measurement is
 *           outside-threshold, even consecutive mesurements.
 *
 *        A 0->1 rise (slave release from GND) happens on:
 *        a. In non-latched mode, next 400ms ALS measurement became
 *           within-threshold.
 *        b. Side-effect from master reading INT_STATUS.
 *
 *        Thus if on fall `1->0` we read INT_STATUS causing rise `0->1`. The
 *        slave would keep triggering the master every 400ms for the entire
 *        duration while ALS is outside-threshold.
 *
 *        Summary, to interrupt only on fall, we disable latched mode and never
 *        read INT_STATUS.
 *
 * SEE ALSO
 *    https://dammedia.osram.info/media/resource/hires/osram-dam-2496565/SFH 7776 (IR-LED + proximity sensor + ambient light sensor).pdf#page=6
 *        C/Eq.(1) exemplifies Lux formula w/o overlayed covers
 *        I/Eq.(5) elaborates Lux formula for overlayed covers
 */
void SFH7776_Read(void) {
  uint8_t buf[4];
  float lux;

  HAL_I2C_Mem_Read(&hi2c1, 0x72, 0x46, I2C_MEMADD_SIZE_8BIT, buf, sizeof buf, 100);
  const uint16_t ALS_VIS = buf[1] << 8 | buf[0];
  const uint16_t ALS_IR = buf[3] << 8 | buf[2];

  // Reference Calculation (No cover)
  lux =
    1.0 * ALS_IR / ALS_VIS < 0.109       ?        1.534 * ALS_VIS / GAIN_VIS -         3.759 * ALS_IR / GAIN_IR : // - LED, fluorescence and sunlight based light.
    1.0 * ALS_IR / ALS_VIS < 0.429       ?        1.339 * ALS_VIS / GAIN_VIS -         1.972 * ALS_IR / GAIN_IR : // - Incandescent and halogen lamps.
    1.0 * ALS_IR / ALS_VIS < 0.95 * 1.45 ?        0.701 * ALS_VIS / GAIN_VIS -         0.483 * ALS_IR / GAIN_IR : // - Dimmed incandescent and halogen lamps,
    1.0 * ALS_IR / ALS_VIS < 1.5  * 1.45 ?  2.0 * 0.701 * ALS_VIS / GAIN_VIS -  1.18 * 0.483 * ALS_IR / GAIN_IR : //   characterized by increased infrared.
    1.0 * ALS_IR / ALS_VIS < 2.5  * 1.45 ?  4.0 * 0.701 * ALS_VIS / GAIN_VIS -  1.33 * 0.483 * ALS_IR / GAIN_IR :
                                            8.0 * 0.701 * ALS_VIS / GAIN_VIS;

  // AN099/page28 I/eq5 Example Calculation (example cover)
  lux =
    1.0 * ALS_IR / ALS_VIS < 0.670       ?       11.071 * ALS_VIS / GAIN_VIS -        14.286 * ALS_IR / GAIN_IR : // - LED, fluorescence and sunlight based light.
    1.0 * ALS_IR / ALS_VIS < 0.746       ?        5.876 * ALS_VIS / GAIN_VIS -         6.536 * ALS_IR / GAIN_IR : // - Incandescent and halogen lamps.
    1.0 * ALS_IR / ALS_VIS < 0.95 * 1.56 ?        1.914 * ALS_VIS / GAIN_VIS -         1.225 * ALS_IR / GAIN_IR : // - Dimmed incandescent and halogen lamps,
    1.0 * ALS_IR / ALS_VIS < 1.5  * 1.56 ?  2.0 * 1.914 * ALS_VIS / GAIN_VIS -  1.18 * 1.225 * ALS_IR / GAIN_IR : //   characterized by increased infrared.
    1.0 * ALS_IR / ALS_VIS < 2.5  * 1.56 ?  4.0 * 1.914 * ALS_VIS / GAIN_VIS -  1.33 * 1.225 * ALS_IR / GAIN_IR :
                                            8.0 * 1.914 * ALS_VIS / GAIN_VIS;
  sfh7776.lux = lux * 100 / T_INT_ALS;

  // Since calculating true ALS (with IR) can cause 87% variation (e.g. threshold is 6000 lux; but triggers at 759 lux)
  // And wakeup can't accomodate IR to begin with, I'll choose visible light only solution.

  // Multiplier hand measured through trial & error, by comparing phone and device against white IPS LCD monitor 40% brightness (target: 250 lux)
  lux = 8.0 * 1.914 * ALS_VIS / GAIN_VIS; // AN099 Cover example   (cover:120 lux; exposed: 1455 lux)
  lux = 8.0 * 0.701 * ALS_VIS / GAIN_VIS; // AN099 Reference value (cover: 42 lux; exposed:  550 lux)
  lux = 8   * 4     * ALS_VIS / GAIN_VIS; // Trial & Error         (cover:236 lux; exposed: 2957 lux)

  /*
   * gcc discards redundant calculations, like no floats invoked. Demonstrated by:
   * arm-none-eabi-objdump --visualize-jumps=extended-color -FCz --disassemble=SFH7776_Read ./stx-fw.elf
   */

  sfh7776.lux = 8 * 4 * ALS_VIS * 100 / T_INT_ALS / GAIN_VIS;
  sfh7776.als_vis = ALS_VIS;
  sfh7776.als_ir = ALS_IR;
}

void SFH7776_Reset(void) {
  uint8_t val = 0x80;
  if(HAL_OK != HAL_I2C_Mem_Read(&hi2c1, 0x72, SFH7776_SYSTEM_CONTROL, I2C_MEMADD_SIZE_8BIT, &val, 1, 100))
    DEBUG_MSG("SEN SFH7776 Reset Failed!\n");
}

void SFH7776_ForeverTest(void) {
  int prev;
  /* Turn off Interrupt handler */
  CLEAR_BIT(EXTI->IMR, LIGHT_Int_Pin);

  for(;;) {
    /* Manually poll interrupt pin */
    int now = HAL_GPIO_ReadPin(LIGHT_Int_GPIO_Port, LIGHT_Int_Pin);

    /* Read and calculate ambient light values */
    SFH7776_Read();

    /* Just debug logic */
    if(prev != now && !now)
      DEBUG_PRINTF("TEST IRQ SFH7776 PIN:1->0 ALS_VIS:0x%04x ALS_IR:0x%04x lux:%5d\n", sfh7776.als_vis, sfh7776.als_ir, sfh7776.lux);
    else
      DEBUG_PRINTF("TEST     SFH7776 PIN:%x    ALS_VIS:0x%04x ALS_IR:0x%04x lux:%5d\n", now, sfh7776.als_vis, sfh7776.als_ir, sfh7776.lux);

    prev = now;
    HAL_Delay(100);
  }
}
#endif

#ifdef BME680
#include "bme680.h"
#ifdef BSEC
#include "bsec_datatypes.h"
#include "bsec_interface.h"
struct BME680_Handle bme680 = {
  /* Configure BME680 driver */
  .dev.dev_id = BME680_I2C_ADDR_PRIMARY,
  .dev.intf = BME680_I2C_INTF,
  .dev.read = user_i2c_read,
  .dev.write = user_i2c_write,
  .dev.delay_ms = HAL_Delay,
};

void BSEC_Init(float sample_rate) {
  bsec_sensor_configuration_t phy[BSEC_MAX_PHYSICAL_SENSOR];
  bsec_sensor_configuration_t virt[] = {
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_IAQ},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_STATIC_IAQ},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_CO2_EQUIVALENT},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_BREATH_VOC_EQUIVALENT},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_RAW_TEMPERATURE},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_RAW_PRESSURE},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_RAW_HUMIDITY},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_RAW_GAS},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_STABILIZATION_STATUS},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_RUN_IN_STATUS},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_TEMPERATURE},
    {.sample_rate = sample_rate, .sensor_id = BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_HUMIDITY},
    //{.sample_rate = BSEC_SAMPLE_RATE_LP, .sensor_id = BSEC_OUTPUT_COMPENSATED_GAS},
    //{.sample_rate = BSEC_SAMPLE_RATE_LP, .sensor_id = BSEC_OUTPUT_GAS_PERCENTAGE},
  };
  /* note: Virtual sensors as desired to be added here */

  uint8_t phy_count = sizeof phy / sizeof *phy;
  int r, c;


  /* Initialize BME680 API */
  if((r = bme680_init(&bme680.dev))) {c = 0x1; goto err;};

  /* Initialize BSEC library */
  if((r = bsec_init())) {c = 0x2; goto err;};

  /* Enable virtual sensors */
  if((r = bsec_update_subscription(virt, sizeof virt / sizeof *virt, phy, &phy_count))) {c = 0x3; goto err;};

  return;
err:
  DBG_PRINTF("SEN BSEC    ERR ret:0x%x cond:0x%x Init Failed\n", r, c);
}

void BSEC_Read(void) {
  /* BSEC sensor settings struct */
  bsec_bme_settings_t settings;

  /* BME680 Physical Sensors  */
  bsec_input_t inputs[BSEC_MAX_PHYSICAL_SENSOR];
  uint8_t inputs_n;

  /* BSEC Virtual Sensors */
  bsec_output_t outputs[BSEC_NUMBER_OUTPUTS];
  uint8_t outputs_n;

  /* Timing */
  uint16_t measure_period;
  int64_t timestamp = HW_RTCGetNsTime();

  /* Debug Information */
  unsigned outputs_i = 0, inputs_i = 0;
  int r;

  // Ask BSEC:
  // 1. How to configure BME680.
  // 2. Should we do a measurement right now.
  // 3. When to consult BSEC again.
  if((r = bsec_sensor_control(timestamp, &settings))) {
    DBG_PRINTF("BSEC ERR sensor_control ret:%d\n", r);
  }
  DBG_PRINTF("BSEC   %10u sensor_control ts:%10d.%09u next_call:%10d.%09u do_meas:%x do_gas:%x do:%x ht:%u C hd:%u ms p:%x t:%x h:%x\n",
      HAL_GetTick(),
      (int32_t)(timestamp / 1000 / 1000 / 1000), (uint32_t)(timestamp % (1000 * 1000 * 1000)),
      (int32_t)(settings.next_call / 1000 / 1000 / 1000), (uint32_t)(settings.next_call % (1000 * 1000 * 1000)),
      settings.trigger_measurement,
      settings.run_gas,
      settings.process_data,
      settings.heater_temperature,
      settings.heating_duration,
      settings.pressure_oversampling,
      settings.temperature_oversampling,
      settings.humidity_oversampling
  );
  bme680.bsec.next_call = settings.next_call;

  // Measure BME680 Now (if BSEC asked)
  if(settings.trigger_measurement) {
    /*
     * Measure physical sensors
     */
    // Configure BME680
    bme680.dev.tph_sett.os_hum     = settings.humidity_oversampling;
    bme680.dev.tph_sett.os_pres    = settings.pressure_oversampling;
    bme680.dev.tph_sett.os_temp    = settings.temperature_oversampling;
    bme680.dev.gas_sett.run_gas    = settings.run_gas;
    bme680.dev.gas_sett.heatr_temp = settings.heater_temperature; /* degree Celsius */
    bme680.dev.gas_sett.heatr_dur  = settings.heating_duration; /* milliseconds */
    bme680.dev.power_mode = BME680_FORCED_MODE;

    if(bme680_set_sensor_settings(BME680_OST_SEL | BME680_OSP_SEL | BME680_OSH_SEL | BME680_GAS_SENSOR_SEL, &bme680.dev)) {
      DBG_PRINTF("BSEC ERR set_sensor_settings\n");
    }
    DBG_PRINTF("BME680 %10u set_sensor_settings\n", HAL_GetTick());

    // Begin BME680 Measurement
    if(bme680_set_sensor_mode(&bme680.dev)) {
      DBG_PRINTF("BSEC ERR set_sensor_mode\n");
    }
    DBG_PRINTF("BME680 %10u set_sensor_mode\n", HAL_GetTick());

    // Wait BME680 Measurement to finish
    bme680_get_profile_dur(&measure_period, &bme680.dev);
    DBG_PRINTF("BME680 %10u get_profile_dur %10u\n", HAL_GetTick(), measure_period);
    HAL_Delay(measure_period);

    // Poll BME680 Measurement to finish
    while(bme680.dev.power_mode == BME680_FORCED_MODE) {
      HAL_Delay(5);
      if(bme680_get_sensor_mode(&bme680.dev)) {
        DBG_PRINTF("BSEC ERR get_sensor_mode %10u\n", HAL_GetTick());
      }
    }
    DBG_PRINTF("BME680 %10u SLEEP_MODE\n", HAL_GetTick());

    /*
     * Read physical sensors
     */
    inputs_n = 0;
    if(settings.process_data) {
      if(bme680_get_sensor_data(&bme680.data, &bme680.dev)) {
        DBG_PRINTF("BSEC ERR get_sensor_data\n");
      }
      DBG_PRINTF("BME680 %10u PHY  %10d", HAL_GetTick(), inputs_i++);
      if(bme680.data.status & BME680_NEW_DATA_MSK) {
        if(settings.process_data & BSEC_PROCESS_PRESSURE) {
          inputs[inputs_n].sensor_id = BSEC_INPUT_PRESSURE;
          inputs[inputs_n].signal = bme680.data.pressure;
          inputs[inputs_n].time_stamp = timestamp;
          inputs_n++;
          DBG_PRINTF(" p:%3d", bme680.data.pressure);
        }
        if(settings.process_data & BSEC_PROCESS_TEMPERATURE) {
          inputs[inputs_n].sensor_id = BSEC_INPUT_TEMPERATURE;
          inputs[inputs_n].signal = bme680.data.temperature / 100.0f;
          inputs[inputs_n].time_stamp = timestamp;
          inputs_n++;
          DBG_PRINTF(" t:%3d", bme680.data.temperature);
        }
        if(settings.process_data & BSEC_PROCESS_HUMIDITY) {
          inputs[inputs_n].sensor_id = BSEC_INPUT_HUMIDITY;
          inputs[inputs_n].signal = bme680.data.humidity / 1000.0f;
          inputs[inputs_n].time_stamp = timestamp;
          inputs_n++;
          DBG_PRINTF(" h:%3d", bme680.data.humidity);
        }
        if(settings.process_data & BSEC_PROCESS_GAS && bme680.data.status & BME680_GASM_VALID_MSK) {
          inputs[inputs_n].sensor_id = BSEC_INPUT_GASRESISTOR;
          inputs[inputs_n].signal = bme680.data.gas_resistance;
          inputs[inputs_n].time_stamp = timestamp;
          inputs_n++;
          DBG_PRINTF(" g:%3d", (int)bme680.data.gas_resistance);
        }
      }
      DEBUG_MSG("\n");

    }

    /*
     * Read virtual sensors
     */
    if(inputs_n) {
      /* Perform processing of the data by BSEC
       * Note:
       * - The number of outputs you get depends on what you asked for during bsec_update_subscription(). This is
       *   handled under bme680_bsec_update_subscription() function in this example file.
       * - The number of actual outputs that are returned is written to num_bsec_outputs.
       */
      outputs_n = sizeof outputs / sizeof *outputs;
      bsec_do_steps(inputs, inputs_n, outputs, &outputs_n);
      DBG_PRINTF("BSEC   %10u VIRT %10d", HAL_GetTick(), outputs_i++);
      for(int i = 0; i < outputs_n; i++) {
        switch(outputs[i].sensor_id) {
        case BSEC_OUTPUT_IAQ:
          DBG_PRINTF(" iaq:%3d.%03d (%x)", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          bme680.bsec.iaq = outputs[i].signal;
          bme680.bsec.acc = outputs[i].accuracy;
          break;
        case BSEC_OUTPUT_STATIC_IAQ:
          DBG_PRINTF(" siaq:%3d.%03d (%x)", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_CO2_EQUIVALENT:
          DBG_PRINTF(" co2:%4d.%03d (%x)", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          bme680.bsec.co2 = outputs[i].signal;
          break;
        case BSEC_OUTPUT_BREATH_VOC_EQUIVALENT:
          DBG_PRINTF(" voc:%3d.%03d (%x)", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          bme680.bsec.voc = outputs[i].signal;
          break;
        case BSEC_OUTPUT_RAW_TEMPERATURE:
          DBG_PRINTF(" t:%3d.%02d", (int)outputs[i].signal, (int)(outputs[i].signal * 100) % 100);
          break;
        case BSEC_OUTPUT_RAW_PRESSURE:
          DBG_PRINTF(" p:%6d", (int)outputs[i].signal);
          break;
        case BSEC_OUTPUT_RAW_HUMIDITY:
          DBG_PRINTF(" h:%3d.%03d", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000);
          break;
        case BSEC_OUTPUT_RAW_GAS:
          DBG_PRINTF(" g:%5d", (int)outputs[i].signal);
          break;
        case BSEC_OUTPUT_STABILIZATION_STATUS:
          DBG_PRINTF(" g_st:%x", (int)outputs[i].signal);
          break;
        case BSEC_OUTPUT_RUN_IN_STATUS:
          DBG_PRINTF(" g_ru:%x", (int)outputs[i].signal);
          break;
        case BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_TEMPERATURE:
          DBG_PRINTF(" t_hc:%3d.%03d ?%x?", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_HUMIDITY:
          DBG_PRINTF(" h_hc:%3d.%03d ?%x?", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_COMPENSATED_GAS:
          DBG_PRINTF(" g_c:%3d.%03d ?%x?", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_GAS_PERCENTAGE:
          DBG_PRINTF(" g_p:%3d.%03d ?%x?", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        }
      }
      DEBUG_MSG("\n");
    }
  }
}

void BSEC_ForeverTest(void) {
  /* BSEC sensor settings struct */
  bsec_bme_settings_t settings;

  /* BME680 Physical Sensors  */
  bsec_input_t inputs[BSEC_MAX_PHYSICAL_SENSOR];
  uint8_t inputs_n;

  /* BSEC Virtual Sensors */
  bsec_output_t outputs[BSEC_NUMBER_OUTPUTS];
  uint8_t outputs_n;

  uint16_t measure_period;

  /* Debug Information */
  unsigned outputs_i = 0, inputs_i = 0;
  int r;

  while(1) {
    /* nanosecond timestamps */
    int64_t timestamp = HW_RTCGetNsTime();

    /* BSEC tells us how the BME680 sensors should be configured */
    if((r = bsec_sensor_control(timestamp, &settings))) {
      DBG_PRINTF("BSEC ERR sensor_control ret:%d\n", r);
    }
    DBG_PRINTF("BSEC   %10u sensor_control ts:%10d.%09u next_call:%10d.%09u do_meas:%x do_gas:%x do:%x ht:%u C hd:%u ms p:%x t:%x h:%x\n",
        HAL_GetTick(),
        (int32_t)(timestamp / 1000 / 1000 / 1000), (uint32_t)(timestamp % (1000 * 1000 * 1000)),
        (int32_t)(settings.next_call / 1000 / 1000 / 1000), (uint32_t)(settings.next_call % (1000 * 1000 * 1000)),
        settings.trigger_measurement,
        settings.run_gas,
        settings.process_data,
        settings.heater_temperature,
        settings.heating_duration,
        settings.pressure_oversampling,
        settings.temperature_oversampling,
        settings.humidity_oversampling

    );

    /* Configure BME680 according to BSEC instructions */
    if(settings.trigger_measurement) {
      /*
       * Configure
       */
      bme680.dev.tph_sett.os_hum     = settings.humidity_oversampling;
      bme680.dev.tph_sett.os_pres    = settings.pressure_oversampling;
      bme680.dev.tph_sett.os_temp    = settings.temperature_oversampling;
      bme680.dev.gas_sett.run_gas    = settings.run_gas;
      bme680.dev.gas_sett.heatr_temp = settings.heater_temperature; /* degree Celsius */
      bme680.dev.gas_sett.heatr_dur  = settings.heating_duration; /* milliseconds */
      bme680.dev.power_mode = BME680_FORCED_MODE;

      /* Set the desired sensor configuration */
      if(bme680_set_sensor_settings(BME680_OST_SEL | BME680_OSP_SEL | BME680_OSH_SEL | BME680_GAS_SENSOR_SEL, &bme680.dev)) {
        DBG_PRINTF("BSEC ERR set_sensor_settings\n");
      }
      DBG_PRINTF("BME680 %10u set_sensor_settings\n", HAL_GetTick());

      /* Trigger forced mode measurement */
      if(bme680_set_sensor_mode(&bme680.dev)) {
        DBG_PRINTF("BSEC ERR set_sensor_mode\n");
      }
      DBG_PRINTF("BME680 %10u set_sensor_mode\n", HAL_GetTick());

      /*
       * Wait
       */
      /* Delay till measurement is ready */
      bme680_get_profile_dur(&measure_period, &bme680.dev);
      DBG_PRINTF("BME680 %10u get_profile_dur %10u\n", HAL_GetTick(), measure_period);
      HAL_Delay(measure_period);
    }

    /* When the measurement is completed and data is ready for reading, the sensor must be in BME680_SLEEP_MODE.
     * Read operation mode to check whether measurement is completely done and wait until the sensor is no more
     * in BME680_FORCED_MODE. */
    while(bme680.dev.power_mode == BME680_FORCED_MODE) {
      HAL_Delay(5);
      if(bme680_get_sensor_mode(&bme680.dev)) {
        DBG_PRINTF("BSEC ERR get_sensor_mode\n");
      }
    }
    DBG_PRINTF("BME680 %10u SLEEP_MODE\n", HAL_GetTick());

    /*
     * Read physical sensors
     */
    inputs_n = 0;
    if(settings.process_data) {
      if(bme680_get_sensor_data(&bme680.data, &bme680.dev)) {
        DBG_PRINTF("BSEC ERR get_sensor_data\n");
      }
      DBG_PRINTF("BME680 %10u PHY  %10d", HAL_GetTick(), inputs_i++);
      if(bme680.data.status & BME680_NEW_DATA_MSK) {
        if(settings.process_data & BSEC_PROCESS_PRESSURE) {
          inputs[inputs_n].sensor_id = BSEC_INPUT_PRESSURE;
          inputs[inputs_n].signal = bme680.data.pressure;
          inputs[inputs_n].time_stamp = timestamp;
          inputs_n++;
          DBG_PRINTF(" p:%3d", bme680.data.pressure);
        }
        if(settings.process_data & BSEC_PROCESS_TEMPERATURE) {
          inputs[inputs_n].sensor_id = BSEC_INPUT_TEMPERATURE;
          inputs[inputs_n].signal = bme680.data.temperature / 100.0f;
          inputs[inputs_n].time_stamp = timestamp;
          inputs_n++;
          DBG_PRINTF(" t:%3d", bme680.data.temperature);
        }
        if(settings.process_data & BSEC_PROCESS_HUMIDITY) {
          inputs[inputs_n].sensor_id = BSEC_INPUT_HUMIDITY;
          inputs[inputs_n].signal = bme680.data.humidity / 1000.0f;
          inputs[inputs_n].time_stamp = timestamp;
          inputs_n++;
          DBG_PRINTF(" h:%3d", bme680.data.humidity);
        }
        if(settings.process_data & BSEC_PROCESS_GAS && bme680.data.status & BME680_GASM_VALID_MSK) {
          inputs[inputs_n].sensor_id = BSEC_INPUT_GASRESISTOR;
          inputs[inputs_n].signal = bme680.data.gas_resistance;
          inputs[inputs_n].time_stamp = timestamp;
          inputs_n++;
          DBG_PRINTF(" g:%3d", (int)bme680.data.gas_resistance);
        }
      }
      DEBUG_MSG("\n");

    }

    /*
     * Read virtual sensors
     */
    if(inputs_n) {
      /* Perform processing of the data by BSEC
       * Note:
       * - The number of outputs you get depends on what you asked for during bsec_update_subscription(). This is
       *   handled under bme680_bsec_update_subscription() function in this example file.
       * - The number of actual outputs that are returned is written to num_bsec_outputs.
       */
      outputs_n = sizeof outputs / sizeof *outputs;
      bsec_do_steps(inputs, inputs_n, outputs, &outputs_n);
      DBG_PRINTF("BSEC   %10u VIRT %10d", HAL_GetTick(), outputs_i++);
      for(int i = 0; i < outputs_n; i++) {
        switch(outputs[i].sensor_id) {
        case BSEC_OUTPUT_IAQ:
          DBG_PRINTF(" iaq:%3d.%03d (%x)", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_STATIC_IAQ:
          DBG_PRINTF(" siaq:%3d.%03d (%x)", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_CO2_EQUIVALENT:
          DBG_PRINTF(" co2:%4d.%03d (%x)", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_BREATH_VOC_EQUIVALENT:
          DBG_PRINTF(" voc:%3d.%03d (%x)", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_RAW_TEMPERATURE:
          DBG_PRINTF(" t:%3d.%02d", (int)outputs[i].signal, (int)(outputs[i].signal * 100) % 100);
          break;
        case BSEC_OUTPUT_RAW_PRESSURE:
          DBG_PRINTF(" p:%6d", (int)outputs[i].signal);
          break;
        case BSEC_OUTPUT_RAW_HUMIDITY:
          DBG_PRINTF(" h:%3d.%03d", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000);
          break;
        case BSEC_OUTPUT_RAW_GAS:
          DBG_PRINTF(" g:%5d", (int)outputs[i].signal);
          break;
        case BSEC_OUTPUT_STABILIZATION_STATUS:
          DBG_PRINTF(" g_st:%x", (int)outputs[i].signal);
          break;
        case BSEC_OUTPUT_RUN_IN_STATUS:
          DBG_PRINTF(" g_ru:%x", (int)outputs[i].signal);
          break;
        case BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_TEMPERATURE:
          DBG_PRINTF(" t_hc:%3d.%03d ?%x?", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_HUMIDITY:
          DBG_PRINTF(" h_hc:%3d.%03d ?%x?", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_COMPENSATED_GAS:
          DBG_PRINTF(" g_c:%3d.%03d ?%x?", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        case BSEC_OUTPUT_GAS_PERCENTAGE:
          DBG_PRINTF(" g_p:%3d.%03d ?%x?", (int)outputs[i].signal, (int)(outputs[i].signal * 1000) % 1000, outputs[i].accuracy);
          break;
        }
      }
      DEBUG_MSG("\n");
    }

    timestamp = HW_RTCGetNsTime();
    if(settings.next_call / 1000 / 1000 > timestamp / 1000 / 1000) {
      DBG_PRINTF("BSEC Sleep %d\n", (int)((settings.next_call - timestamp) / 1000 / 1000));
      HAL_Delay((settings.next_call - timestamp) / 1000 / 1000);
    }
  }
}

/**
 * base-8 3-bit exponent, 10-bit fractional mantissa:
 *
 * | bits | scale                       | min              | max                | step         |
 * |------|-----------------------------|------------------|--------------------|--------------|
 * | 000  | n/1024                      |      0.000000000 |       0.9990234375 | 0.0009765625 |
 * | 001  | n/1024 * ( 8^1 - 8^0) + 8^0 |      1.000000000 |       7.9931640625 | 0.0068359375 |
 * | 010  | n/1024 * ( 8^2 - 8^1) + 8^1 |      8.0000000   |      63.9453125    | 0.0546875    |
 * | 011  | n/1024 * ( 8^3 - 8^2) + 8^2 |     64.0000      |     511.5625       | 0.4375       |
 * | 100  | n/1024 * ( 8^4 - 8^3) + 8^3 |    512.0         |    4092.5          | 3.5          |
 * | 101  | n/1024 * ( 8^5 - 8^4) + 8^4 |   4096.          |   32740.           | 28           |
 * | 110  | n/1024 * ( 8^6 - 8^5) + 8^5 |  32768.          |  261920.           | 224          |
 * | 111  | n/1024 * ( 8^7 - 8^6) + 8^6 | 262144.          | 2095360.           | 1792         |
 */
uint16_t BSEC_float(float f) {
  unsigned min, max, exponent, mantissa;
  if(f < 0)
    return 0x0000;
  if(f > 2095360)
    return 0x1fff;
  exponent =
    f > 2095360 ? 7 :
    f >  261920 ? 7 :
    f >   32740 ? 6 :
    f >    4093 ? 5 :
    f >     511 ? 4 :
    f >      63 ? 3 :
    f >       7 ? 2 :
    f >       1 ? 1 : 0;
  min = 1U << 3 * (exponent - 1);
  max = 1U << 3 *  exponent;
  mantissa = (unsigned)roundf(exponent
      ? (f - (float)min) * 1024 / (float)(max - min)
      :  f               * 1024
  );
  return (uint16_t)(((exponent & 0x7) << 10) | (mantissa & 0x3ff));
}

#else
struct BME680_Handle bme680 = {
  /* Configure BME680 driver */
  .dev.dev_id = BME680_I2C_ADDR_PRIMARY,
  .dev.intf = BME680_I2C_INTF,
  .dev.read = user_i2c_read,
  .dev.write = user_i2c_write,
  .dev.delay_ms = HAL_Delay,
  .dev.amb_temp = 25,
  /* Set the humidity, temperature and pressure settings */
  .dev.tph_sett.os_hum = BME680_OS_2X,
  .dev.tph_sett.os_temp = BME680_OS_8X,
  .dev.tph_sett.os_pres = BME680_OS_4X,
  .dev.tph_sett.filter = BME680_FILTER_SIZE_3,
  /* Set the remaining gas sensor settings and link the heating profile */
  .dev.gas_sett.run_gas = BME680_ENABLE_GAS_MEAS,
  /* Create a ramp heat waveform in 3 steps */
  .dev.gas_sett.heatr_temp = 320, /* Celsius */
  .dev.gas_sett.heatr_dur = 150, /* milliseconds */
  /* Select the power mode */
  .dev.power_mode = BME680_FORCED_MODE,
};

void BME680_Init(void) {
  int r, c;

  if((r = bme680_init(&bme680.dev))) {c = 0x1; goto err;};

  /* Set the desired sensor configuration */
  if((r = bme680_set_sensor_settings(
      BME680_OST_SEL |
      BME680_OSP_SEL |
      BME680_OSH_SEL |
      BME680_FILTER_SEL |
      BME680_GAS_SENSOR_SEL, &bme680.dev))) {c = 0x2; goto err;};

  /* Apply the power mode */
  if((r = bme680_set_sensor_mode(&bme680.dev))) {c = 0x3; goto err;};

  return;
err:
  DEBUG_PRINTF("SEN BME680  ERR ret:0x%x cond:0x%x Init Failed!\n", r, c);
}

void BME680_Read(void) {
  uint16_t measure_period;

  /* Delay till measurement is ready */
  bme680_get_profile_dur(&measure_period, &bme680.dev);
  HAL_Delay(measure_period);

  /* measure */
  bme680_get_sensor_data(&bme680.data, &bme680.dev);

  /* Trigger the next measurement if you would like to read data out continuously */
  if (bme680.dev.power_mode == BME680_FORCED_MODE) {
    bme680_set_sensor_mode(&bme680.dev);
  }
}

/**
 * DESCRIPTION
 *        This is an older inherited reading function. Its origins are unknown,
 *        and logic behind AQI calculation is not understood.
 */
void BME680_ReadOld(void) {
  static uint16_t gas_reference = 0;
  uint16_t meas_period;

  bme680_get_profile_dur(&meas_period, &bme680.dev);

  /* Delay till measurement is ready */
  HAL_Delay(meas_period);

  bme680_get_sensor_data(&bme680.data, &bme680.dev);

  /* Avoid using measurements from an unstable heating setup */
  if(bme680.data.status & BME680_GASM_VALID_MSK)
    gas_reference = bme680.data.gas_resistance;

  // Calculation of AQI
  uint16_t AQI;
  uint16_t humidityAQI;
  uint16_t gasAQI;
  uint8_t humidity;

  // 0.) normalize humidity
  humidity = bme680.data.humidity < 1000 || bme680.data.humidity > 100000 ?
    0 : bme680.data.humidity / 1000;

  // 1.) humidity contribution
  humidityAQI =
    humidity >= 38 && humidity <= 42 ? 0.25                                     * 100 : // Humidity +/-5% around optimum
    humidity <  38                   ? 0.25 /        40  * humidity             * 100 : // Humidity reference: 40
                                     (-0.25 / (100 - 40) * humidity + 0.416666) * 100;  // Humidity reference: 40

  // 2.) Gas resistance contribution
  const uint16_t gas_lower_limit = 5000;   // Bad air quality limit
  const uint16_t gas_upper_limit = 50000;  // Good air quality limit
  gas_reference =
    gas_reference > gas_upper_limit ? gas_upper_limit :
    gas_reference < gas_lower_limit ? gas_lower_limit :
                                      gas_reference;
  gasAQI = (0.75 / (gas_upper_limit - gas_lower_limit) * gas_reference - gas_lower_limit * 0.75 / (gas_upper_limit - gas_lower_limit)) * 100;

  // Combine results for the final IAQ index value (0-100% where 100% is good quality air)
  AQI = humidityAQI + gasAQI;

  DBG_PRINTF("SEN BME680 T: %2d.%02d H: %2d.%03d P: %06d G: %5d -- hAQI: %3d gAQI: %3d AQI: %3d\n",
    bme680.data.temperature / 100, bme680.data.temperature % 100,
    bme680.data.humidity   / 1000, bme680.data.humidity   % 1000,
    bme680.data.pressure         , bme680.data.gas_resistance,
    humidityAQI, gasAQI, AQI);

  /* Trigger the next measurement if you would like to read data out continuously */
  if(bme680.dev.power_mode)
    bme680_set_sensor_mode(&bme680.dev);
}
#endif /* BSEC */
#endif /* BME680 */

#ifdef HDC2080
struct HDC2080_Handle hdc2080;
void HDC2080_Init(enum HDC2080_Threshold type, int32_t thres) {
  int32_t r, c;
  uint8_t buf[6];

  /* Turn off Interrupt handler */
  CLEAR_BIT(EXTI->IMR, TEMP_Int_Pin);

  // HDC2080_CONFIG: reset peripheral
  *buf = 0x80;
  r = HAL_I2C_Mem_Write(&hi2c1, HDC2080_I2C_ADDR, HDC2080_CONFIG, I2C_MEMADD_SIZE_8BIT, buf, 1, 50);
  HAL_Delay(1);

  // HDC2080_INT_ENABLE: enable specific threshold interrupt
  *buf =
    type == HDC2080_TEMPERATURE_LOW  ? 0x20 :
    type == HDC2080_TEMPERATURE_HIGH ? 0x40 :
    type == HDC2080_HUMIDITY_LOW  ? 0x80 :
    type == HDC2080_HUMIDITY_HIGH ? 0x10 : 0x10;
  if((r = HAL_I2C_Mem_Write(&hi2c1, HDC2080_I2C_ADDR, HDC2080_INT_ENABLE, I2C_MEMADD_SIZE_8BIT, buf, 1, 50))) {c = 0x2; goto err;};

  // HDC2080_*_TL: Configure specific threshold
  buf[0] = type != HDC2080_TEMPERATURE_LOW  ? 0x00 : (thres + 4000) * 256 / 16500;
  buf[1] = type != HDC2080_TEMPERATURE_HIGH ? 0xff : (thres + 4000) * 256 / 16500;
  buf[2] = type != HDC2080_HUMIDITY_LOW     ? 0x00 : thres * 256 / 100;
  buf[3] = type != HDC2080_HUMIDITY_HIGH    ? 0xff : thres * 256 / 100;

  // HDC2080_CONFIG: 1Hz Auto measure mode, Enable interrupt (non-latched; high active level)
  buf[4] = 0x01 | 0x02 | 0x04 | 0x50;

  // HDC2080_MEASURE: Measure humidity and temperature with 9-bit resolution, Start Measurement.
  buf[5] = 0x80 | 0x20 | 0x01;
  if((r = HAL_I2C_Mem_Write(&hi2c1, HDC2080_I2C_ADDR, HDC2080_TEMP_TL, I2C_MEMADD_SIZE_8BIT, buf, 6, 50))) {c = 0x3; goto err;};

  goto exit;
err:
  DEBUG_PRINTF("SEN HDC2080 ERR ret:0x%x cond:0x%x Init Failed\n", r, c);
exit:
  /* Enable Interrupt Handler */
  SET_BIT(EXTI->IMR, TEMP_Int_Pin);
}

void HDC2080_Read(void) {
  int32_t r;
  uint8_t buf[5];
  if(r = HAL_I2C_Mem_Read(&hi2c1, HDC2080_I2C_ADDR, HDC2080_TEMP, I2C_MEMADD_SIZE_8BIT, buf, 5, 50), r != HAL_OK) {
    DEBUG_PRINTF("SEN HDC2080 I2C <RX ERR ret:0x%x\n", r);
    return;
  };

  hdc2080.raw_temp = buf[1] << 8 | buf[0];
  hdc2080.raw_humid = buf[3] << 8 | buf[2];
  hdc2080.fix_temp = hdc2080.raw_temp * 165 * 100 / 65536 - 4000;
  hdc2080.humid = hdc2080.raw_humid * 100 / 65536;
  hdc2080.status = buf[4];
}

void HDC2080_Reset(void) {
  uint8_t val = 0x80;
  if(HAL_OK != HAL_I2C_Mem_Write(&hi2c1, HDC2080_I2C_ADDR, HDC2080_CONFIG, I2C_MEMADD_SIZE_8BIT, &val, 1, 100))
    DEBUG_MSG("SEN HDC2080 Reset Failed!\n");
  HAL_Delay(1);
}

void HDC2080_ForeverTest(void) {
  int prev;
  for(;;) {
    /* Manually poll interrupt pin */
    int now = HAL_GPIO_ReadPin(TEMP_Int_GPIO_Port, TEMP_Int_Pin);

    /* Read and calculate temperature and relative humidity */
    HDC2080_Read();

    if(prev != now && now)
      DEBUG_PRINTF("TEST     HDC2080 PIN:0->1 TEMP:%5d 0x%04x HUMID:%5d 0x%04x\n", hdc2080.fix_temp, hdc2080.raw_temp, hdc2080.humid, hdc2080.raw_humid);
    else
      DEBUG_PRINTF("TEST     HDC2080 PIN:%x    TEMP:%5d 0x%04x HUMID:%5d 0x%04x\n", now, hdc2080.fix_temp, hdc2080.raw_temp, hdc2080.humid, hdc2080.raw_humid);

    prev = now;
    HAL_Delay(1000);
  }
}
#endif

