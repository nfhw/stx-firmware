################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../cryptolib/crypto/atca_crypto_hw_aes_cbc.c \
../cryptolib/crypto/atca_crypto_hw_aes_cbcmac.c \
../cryptolib/crypto/atca_crypto_hw_aes_ccm.c \
../cryptolib/crypto/atca_crypto_hw_aes_cmac.c \
../cryptolib/crypto/atca_crypto_hw_aes_ctr.c \
../cryptolib/crypto/atca_crypto_sw_ecdsa.c \
../cryptolib/crypto/atca_crypto_sw_rand.c \
../cryptolib/crypto/atca_crypto_sw_sha1.c \
../cryptolib/crypto/atca_crypto_sw_sha2.c 

C_DEPS += \
./cryptolib/crypto/atca_crypto_hw_aes_cbc.d \
./cryptolib/crypto/atca_crypto_hw_aes_cbcmac.d \
./cryptolib/crypto/atca_crypto_hw_aes_ccm.d \
./cryptolib/crypto/atca_crypto_hw_aes_cmac.d \
./cryptolib/crypto/atca_crypto_hw_aes_ctr.d \
./cryptolib/crypto/atca_crypto_sw_ecdsa.d \
./cryptolib/crypto/atca_crypto_sw_rand.d \
./cryptolib/crypto/atca_crypto_sw_sha1.d \
./cryptolib/crypto/atca_crypto_sw_sha2.d 

OBJS += \
./cryptolib/crypto/atca_crypto_hw_aes_cbc.o \
./cryptolib/crypto/atca_crypto_hw_aes_cbcmac.o \
./cryptolib/crypto/atca_crypto_hw_aes_ccm.o \
./cryptolib/crypto/atca_crypto_hw_aes_cmac.o \
./cryptolib/crypto/atca_crypto_hw_aes_ctr.o \
./cryptolib/crypto/atca_crypto_sw_ecdsa.o \
./cryptolib/crypto/atca_crypto_sw_rand.o \
./cryptolib/crypto/atca_crypto_sw_sha1.o \
./cryptolib/crypto/atca_crypto_sw_sha2.o 


# Each subdirectory must supply rules for building sources it contributes
cryptolib/crypto/atca_crypto_hw_aes_cbc.o: ../cryptolib/crypto/atca_crypto_hw_aes_cbc.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/crypto/atca_crypto_hw_aes_cbc.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/crypto/atca_crypto_hw_aes_cbcmac.o: ../cryptolib/crypto/atca_crypto_hw_aes_cbcmac.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/crypto/atca_crypto_hw_aes_cbcmac.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/crypto/atca_crypto_hw_aes_ccm.o: ../cryptolib/crypto/atca_crypto_hw_aes_ccm.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/crypto/atca_crypto_hw_aes_ccm.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/crypto/atca_crypto_hw_aes_cmac.o: ../cryptolib/crypto/atca_crypto_hw_aes_cmac.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/crypto/atca_crypto_hw_aes_cmac.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/crypto/atca_crypto_hw_aes_ctr.o: ../cryptolib/crypto/atca_crypto_hw_aes_ctr.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/crypto/atca_crypto_hw_aes_ctr.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/crypto/atca_crypto_sw_ecdsa.o: ../cryptolib/crypto/atca_crypto_sw_ecdsa.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/crypto/atca_crypto_sw_ecdsa.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/crypto/atca_crypto_sw_rand.o: ../cryptolib/crypto/atca_crypto_sw_rand.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/crypto/atca_crypto_sw_rand.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/crypto/atca_crypto_sw_sha1.o: ../cryptolib/crypto/atca_crypto_sw_sha1.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/crypto/atca_crypto_sw_sha1.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/crypto/atca_crypto_sw_sha2.o: ../cryptolib/crypto/atca_crypto_sw_sha2.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/crypto/atca_crypto_sw_sha2.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

