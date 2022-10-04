# ADC Read

  HAL_ADCEx_Calibration_Start(&hadc, ADC_SINGLE_ENDED);
  HAL_ADC_Start(&hadc);
  int r1 = 82000;                       // R2 in ohm
  int r2 = 82000;                       // R3 in ohm
  float r_divider = (float)r2 / (r1 + r2);
  while(1) {
    if (HAL_ADC_PollForConversion(&hadc, 1000000) == HAL_OK) {
      int ADCValue = HAL_ADC_GetValue(&hadc);
      DEBUG_PRINTF("---ADC Value: %d\n", ADCValue);
      float voltage = (float)ADCValue * (3.3 / 4095);
      int integer = (voltage * 1000); // r_divider; // / r_divider
      DEBUG_PRINTF("---ADC Value conv: %d\n", integer);
      HAL_ADC_Start(&hadc);
    }
    HAL_Delay(100);
  }


# Blink Loop
void blinkXTimes(uint8_t times, uint16_t led);

  while (true) {
    blinkXTimes(1, LED_1_Pin);
    HAL_Delay(8000 * 1000L);
  }
