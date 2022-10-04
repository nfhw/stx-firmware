################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../cryptolib/atcacert/atcacert_client.c \
../cryptolib/atcacert/atcacert_date.c \
../cryptolib/atcacert/atcacert_def.c \
../cryptolib/atcacert/atcacert_der.c \
../cryptolib/atcacert/atcacert_host_hw.c \
../cryptolib/atcacert/atcacert_host_sw.c \
../cryptolib/atcacert/atcacert_pem.c 

C_DEPS += \
./cryptolib/atcacert/atcacert_client.d \
./cryptolib/atcacert/atcacert_date.d \
./cryptolib/atcacert/atcacert_def.d \
./cryptolib/atcacert/atcacert_der.d \
./cryptolib/atcacert/atcacert_host_hw.d \
./cryptolib/atcacert/atcacert_host_sw.d \
./cryptolib/atcacert/atcacert_pem.d 

OBJS += \
./cryptolib/atcacert/atcacert_client.o \
./cryptolib/atcacert/atcacert_date.o \
./cryptolib/atcacert/atcacert_def.o \
./cryptolib/atcacert/atcacert_der.o \
./cryptolib/atcacert/atcacert_host_hw.o \
./cryptolib/atcacert/atcacert_host_sw.o \
./cryptolib/atcacert/atcacert_pem.o 


# Each subdirectory must supply rules for building sources it contributes
cryptolib/atcacert/%.o cryptolib/atcacert/%.su: ../cryptolib/atcacert/%.c cryptolib/atcacert/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -I"/hw/ibt-1-fw/Drivers/BSEC/inc" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-cryptolib-2f-atcacert

clean-cryptolib-2f-atcacert:
	-$(RM) ./cryptolib/atcacert/atcacert_client.d ./cryptolib/atcacert/atcacert_client.o ./cryptolib/atcacert/atcacert_client.su ./cryptolib/atcacert/atcacert_date.d ./cryptolib/atcacert/atcacert_date.o ./cryptolib/atcacert/atcacert_date.su ./cryptolib/atcacert/atcacert_def.d ./cryptolib/atcacert/atcacert_def.o ./cryptolib/atcacert/atcacert_def.su ./cryptolib/atcacert/atcacert_der.d ./cryptolib/atcacert/atcacert_der.o ./cryptolib/atcacert/atcacert_der.su ./cryptolib/atcacert/atcacert_host_hw.d ./cryptolib/atcacert/atcacert_host_hw.o ./cryptolib/atcacert/atcacert_host_hw.su ./cryptolib/atcacert/atcacert_host_sw.d ./cryptolib/atcacert/atcacert_host_sw.o ./cryptolib/atcacert/atcacert_host_sw.su ./cryptolib/atcacert/atcacert_pem.d ./cryptolib/atcacert/atcacert_pem.o ./cryptolib/atcacert/atcacert_pem.su

.PHONY: clean-cryptolib-2f-atcacert

