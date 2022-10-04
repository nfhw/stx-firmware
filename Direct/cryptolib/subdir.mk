################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../cryptolib/atca_basic.c \
../cryptolib/atca_cfgs.c \
../cryptolib/atca_command.c \
../cryptolib/atca_debug.c \
../cryptolib/atca_device.c \
../cryptolib/atca_helpers.c \
../cryptolib/atca_iface.c \
../cryptolib/atca_utils_sizes.c 

C_DEPS += \
./cryptolib/atca_basic.d \
./cryptolib/atca_cfgs.d \
./cryptolib/atca_command.d \
./cryptolib/atca_debug.d \
./cryptolib/atca_device.d \
./cryptolib/atca_helpers.d \
./cryptolib/atca_iface.d \
./cryptolib/atca_utils_sizes.d 

OBJS += \
./cryptolib/atca_basic.o \
./cryptolib/atca_cfgs.o \
./cryptolib/atca_command.o \
./cryptolib/atca_debug.o \
./cryptolib/atca_device.o \
./cryptolib/atca_helpers.o \
./cryptolib/atca_iface.o \
./cryptolib/atca_utils_sizes.o 


# Each subdirectory must supply rules for building sources it contributes
cryptolib/%.o cryptolib/%.su: ../cryptolib/%.c cryptolib/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -I"/hw/ibt-1-fw/Drivers/BSEC/inc" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-cryptolib

clean-cryptolib:
	-$(RM) ./cryptolib/atca_basic.d ./cryptolib/atca_basic.o ./cryptolib/atca_basic.su ./cryptolib/atca_cfgs.d ./cryptolib/atca_cfgs.o ./cryptolib/atca_cfgs.su ./cryptolib/atca_command.d ./cryptolib/atca_command.o ./cryptolib/atca_command.su ./cryptolib/atca_debug.d ./cryptolib/atca_debug.o ./cryptolib/atca_debug.su ./cryptolib/atca_device.d ./cryptolib/atca_device.o ./cryptolib/atca_device.su ./cryptolib/atca_helpers.d ./cryptolib/atca_helpers.o ./cryptolib/atca_helpers.su ./cryptolib/atca_iface.d ./cryptolib/atca_iface.o ./cryptolib/atca_iface.su ./cryptolib/atca_utils_sizes.d ./cryptolib/atca_utils_sizes.o ./cryptolib/atca_utils_sizes.su

.PHONY: clean-cryptolib
