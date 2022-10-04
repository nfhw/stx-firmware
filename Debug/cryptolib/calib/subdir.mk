################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
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
cryptolib/calib/%.o cryptolib/calib/%.su: ../cryptolib/calib/%.c cryptolib/calib/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-cryptolib-2f-calib

clean-cryptolib-2f-calib:
	-$(RM) ./cryptolib/calib/calib_aes.d ./cryptolib/calib/calib_aes.o ./cryptolib/calib/calib_aes.su ./cryptolib/calib/calib_aes_gcm.d ./cryptolib/calib/calib_aes_gcm.o ./cryptolib/calib/calib_aes_gcm.su ./cryptolib/calib/calib_basic.d ./cryptolib/calib/calib_basic.o ./cryptolib/calib/calib_basic.su ./cryptolib/calib/calib_checkmac.d ./cryptolib/calib/calib_checkmac.o ./cryptolib/calib/calib_checkmac.su ./cryptolib/calib/calib_command.d ./cryptolib/calib/calib_command.o ./cryptolib/calib/calib_command.su ./cryptolib/calib/calib_counter.d ./cryptolib/calib/calib_counter.o ./cryptolib/calib/calib_counter.su ./cryptolib/calib/calib_derivekey.d ./cryptolib/calib/calib_derivekey.o ./cryptolib/calib/calib_derivekey.su ./cryptolib/calib/calib_ecdh.d ./cryptolib/calib/calib_ecdh.o ./cryptolib/calib/calib_ecdh.su ./cryptolib/calib/calib_execution.d ./cryptolib/calib/calib_execution.o ./cryptolib/calib/calib_execution.su ./cryptolib/calib/calib_gendig.d ./cryptolib/calib/calib_gendig.o ./cryptolib/calib/calib_gendig.su ./cryptolib/calib/calib_genkey.d ./cryptolib/calib/calib_genkey.o ./cryptolib/calib/calib_genkey.su ./cryptolib/calib/calib_hmac.d ./cryptolib/calib/calib_hmac.o ./cryptolib/calib/calib_hmac.su ./cryptolib/calib/calib_info.d ./cryptolib/calib/calib_info.o ./cryptolib/calib/calib_info.su ./cryptolib/calib/calib_kdf.d ./cryptolib/calib/calib_kdf.o ./cryptolib/calib/calib_kdf.su ./cryptolib/calib/calib_lock.d ./cryptolib/calib/calib_lock.o ./cryptolib/calib/calib_lock.su ./cryptolib/calib/calib_mac.d ./cryptolib/calib/calib_mac.o ./cryptolib/calib/calib_mac.su ./cryptolib/calib/calib_nonce.d ./cryptolib/calib/calib_nonce.o ./cryptolib/calib/calib_nonce.su ./cryptolib/calib/calib_privwrite.d ./cryptolib/calib/calib_privwrite.o ./cryptolib/calib/calib_privwrite.su ./cryptolib/calib/calib_random.d ./cryptolib/calib/calib_random.o ./cryptolib/calib/calib_random.su ./cryptolib/calib/calib_read.d ./cryptolib/calib/calib_read.o ./cryptolib/calib/calib_read.su ./cryptolib/calib/calib_secureboot.d ./cryptolib/calib/calib_secureboot.o ./cryptolib/calib/calib_secureboot.su ./cryptolib/calib/calib_selftest.d ./cryptolib/calib/calib_selftest.o ./cryptolib/calib/calib_selftest.su ./cryptolib/calib/calib_sha.d ./cryptolib/calib/calib_sha.o ./cryptolib/calib/calib_sha.su ./cryptolib/calib/calib_sign.d ./cryptolib/calib/calib_sign.o ./cryptolib/calib/calib_sign.su ./cryptolib/calib/calib_updateextra.d ./cryptolib/calib/calib_updateextra.o ./cryptolib/calib/calib_updateextra.su ./cryptolib/calib/calib_verify.d ./cryptolib/calib/calib_verify.o ./cryptolib/calib/calib_verify.su ./cryptolib/calib/calib_write.d ./cryptolib/calib/calib_write.o ./cryptolib/calib/calib_write.su

.PHONY: clean-cryptolib-2f-calib

