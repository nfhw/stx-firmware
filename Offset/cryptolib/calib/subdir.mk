################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../cryptolib/calib/calib_aes.c \
../cryptolib/calib/calib_aes_gcm.c \
../cryptolib/calib/calib_basic.c \
../cryptolib/calib/calib_checkmac.c \
../cryptolib/calib/calib_command.c \
../cryptolib/calib/calib_counter.c \
../cryptolib/calib/calib_derivekey.c \
../cryptolib/calib/calib_ecdh.c \
../cryptolib/calib/calib_execution.c \
../cryptolib/calib/calib_gendig.c \
../cryptolib/calib/calib_genkey.c \
../cryptolib/calib/calib_hmac.c \
../cryptolib/calib/calib_info.c \
../cryptolib/calib/calib_kdf.c \
../cryptolib/calib/calib_lock.c \
../cryptolib/calib/calib_mac.c \
../cryptolib/calib/calib_nonce.c \
../cryptolib/calib/calib_privwrite.c \
../cryptolib/calib/calib_random.c \
../cryptolib/calib/calib_read.c \
../cryptolib/calib/calib_secureboot.c \
../cryptolib/calib/calib_selftest.c \
../cryptolib/calib/calib_sha.c \
../cryptolib/calib/calib_sign.c \
../cryptolib/calib/calib_updateextra.c \
../cryptolib/calib/calib_verify.c \
../cryptolib/calib/calib_write.c 

C_DEPS += \
./cryptolib/calib/calib_aes.d \
./cryptolib/calib/calib_aes_gcm.d \
./cryptolib/calib/calib_basic.d \
./cryptolib/calib/calib_checkmac.d \
./cryptolib/calib/calib_command.d \
./cryptolib/calib/calib_counter.d \
./cryptolib/calib/calib_derivekey.d \
./cryptolib/calib/calib_ecdh.d \
./cryptolib/calib/calib_execution.d \
./cryptolib/calib/calib_gendig.d \
./cryptolib/calib/calib_genkey.d \
./cryptolib/calib/calib_hmac.d \
./cryptolib/calib/calib_info.d \
./cryptolib/calib/calib_kdf.d \
./cryptolib/calib/calib_lock.d \
./cryptolib/calib/calib_mac.d \
./cryptolib/calib/calib_nonce.d \
./cryptolib/calib/calib_privwrite.d \
./cryptolib/calib/calib_random.d \
./cryptolib/calib/calib_read.d \
./cryptolib/calib/calib_secureboot.d \
./cryptolib/calib/calib_selftest.d \
./cryptolib/calib/calib_sha.d \
./cryptolib/calib/calib_sign.d \
./cryptolib/calib/calib_updateextra.d \
./cryptolib/calib/calib_verify.d \
./cryptolib/calib/calib_write.d 

OBJS += \
./cryptolib/calib/calib_aes.o \
./cryptolib/calib/calib_aes_gcm.o \
./cryptolib/calib/calib_basic.o \
./cryptolib/calib/calib_checkmac.o \
./cryptolib/calib/calib_command.o \
./cryptolib/calib/calib_counter.o \
./cryptolib/calib/calib_derivekey.o \
./cryptolib/calib/calib_ecdh.o \
./cryptolib/calib/calib_execution.o \
./cryptolib/calib/calib_gendig.o \
./cryptolib/calib/calib_genkey.o \
./cryptolib/calib/calib_hmac.o \
./cryptolib/calib/calib_info.o \
./cryptolib/calib/calib_kdf.o \
./cryptolib/calib/calib_lock.o \
./cryptolib/calib/calib_mac.o \
./cryptolib/calib/calib_nonce.o \
./cryptolib/calib/calib_privwrite.o \
./cryptolib/calib/calib_random.o \
./cryptolib/calib/calib_read.o \
./cryptolib/calib/calib_secureboot.o \
./cryptolib/calib/calib_selftest.o \
./cryptolib/calib/calib_sha.o \
./cryptolib/calib/calib_sign.o \
./cryptolib/calib/calib_updateextra.o \
./cryptolib/calib/calib_verify.o \
./cryptolib/calib/calib_write.o 


# Each subdirectory must supply rules for building sources it contributes
cryptolib/calib/calib_aes.o: ../cryptolib/calib/calib_aes.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_aes.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_aes_gcm.o: ../cryptolib/calib/calib_aes_gcm.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_aes_gcm.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_basic.o: ../cryptolib/calib/calib_basic.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_basic.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_checkmac.o: ../cryptolib/calib/calib_checkmac.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_checkmac.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_command.o: ../cryptolib/calib/calib_command.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_command.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_counter.o: ../cryptolib/calib/calib_counter.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_counter.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_derivekey.o: ../cryptolib/calib/calib_derivekey.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_derivekey.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_ecdh.o: ../cryptolib/calib/calib_ecdh.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_ecdh.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_execution.o: ../cryptolib/calib/calib_execution.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_execution.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_gendig.o: ../cryptolib/calib/calib_gendig.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_gendig.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_genkey.o: ../cryptolib/calib/calib_genkey.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_genkey.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_hmac.o: ../cryptolib/calib/calib_hmac.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_hmac.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_info.o: ../cryptolib/calib/calib_info.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_info.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_kdf.o: ../cryptolib/calib/calib_kdf.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_kdf.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_lock.o: ../cryptolib/calib/calib_lock.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_lock.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_mac.o: ../cryptolib/calib/calib_mac.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_mac.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_nonce.o: ../cryptolib/calib/calib_nonce.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_nonce.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_privwrite.o: ../cryptolib/calib/calib_privwrite.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_privwrite.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_random.o: ../cryptolib/calib/calib_random.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_random.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_read.o: ../cryptolib/calib/calib_read.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_read.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_secureboot.o: ../cryptolib/calib/calib_secureboot.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_secureboot.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_selftest.o: ../cryptolib/calib/calib_selftest.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_selftest.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_sha.o: ../cryptolib/calib/calib_sha.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_sha.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_sign.o: ../cryptolib/calib/calib_sign.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_sign.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_updateextra.o: ../cryptolib/calib/calib_updateextra.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_updateextra.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_verify.o: ../cryptolib/calib/calib_verify.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_verify.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
cryptolib/calib/calib_write.o: ../cryptolib/calib/calib_write.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/calib/calib_write.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

