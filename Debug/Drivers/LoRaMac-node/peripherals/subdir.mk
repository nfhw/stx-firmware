################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Drivers/LoRaMac-node/peripherals/aes.c \
../Drivers/LoRaMac-node/peripherals/cmac.c \
../Drivers/LoRaMac-node/peripherals/soft-se-hal.c \
../Drivers/LoRaMac-node/peripherals/soft-se.c 

C_DEPS += \
./Drivers/LoRaMac-node/peripherals/aes.d \
./Drivers/LoRaMac-node/peripherals/cmac.d \
./Drivers/LoRaMac-node/peripherals/soft-se-hal.d \
./Drivers/LoRaMac-node/peripherals/soft-se.d 

OBJS += \
./Drivers/LoRaMac-node/peripherals/aes.o \
./Drivers/LoRaMac-node/peripherals/cmac.o \
./Drivers/LoRaMac-node/peripherals/soft-se-hal.o \
./Drivers/LoRaMac-node/peripherals/soft-se.o 


# Each subdirectory must supply rules for building sources it contributes
Drivers/LoRaMac-node/peripherals/%.o Drivers/LoRaMac-node/peripherals/%.su: ../Drivers/LoRaMac-node/peripherals/%.c Drivers/LoRaMac-node/peripherals/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-Drivers-2f-LoRaMac-2d-node-2f-peripherals

clean-Drivers-2f-LoRaMac-2d-node-2f-peripherals:
	-$(RM) ./Drivers/LoRaMac-node/peripherals/aes.d ./Drivers/LoRaMac-node/peripherals/aes.o ./Drivers/LoRaMac-node/peripherals/aes.su ./Drivers/LoRaMac-node/peripherals/cmac.d ./Drivers/LoRaMac-node/peripherals/cmac.o ./Drivers/LoRaMac-node/peripherals/cmac.su ./Drivers/LoRaMac-node/peripherals/soft-se-hal.d ./Drivers/LoRaMac-node/peripherals/soft-se-hal.o ./Drivers/LoRaMac-node/peripherals/soft-se-hal.su ./Drivers/LoRaMac-node/peripherals/soft-se.d ./Drivers/LoRaMac-node/peripherals/soft-se.o ./Drivers/LoRaMac-node/peripherals/soft-se.su

.PHONY: clean-Drivers-2f-LoRaMac-2d-node-2f-peripherals

