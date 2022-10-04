################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../radio/sx126x/radio.c \
../radio/sx126x/sx126x.c 

C_DEPS += \
./radio/sx126x/radio.d \
./radio/sx126x/sx126x.d 

OBJS += \
./radio/sx126x/radio.o \
./radio/sx126x/sx126x.o 


# Each subdirectory must supply rules for building sources it contributes
radio/sx126x/%.o radio/sx126x/%.su: ../radio/sx126x/%.c radio/sx126x/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-radio-2f-sx126x

clean-radio-2f-sx126x:
	-$(RM) ./radio/sx126x/radio.d ./radio/sx126x/radio.o ./radio/sx126x/radio.su ./radio/sx126x/sx126x.d ./radio/sx126x/sx126x.o ./radio/sx126x/sx126x.su

.PHONY: clean-radio-2f-sx126x

