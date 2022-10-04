################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Drivers/LoRaMac-node/system/delay.c \
../Drivers/LoRaMac-node/system/fifo.c \
../Drivers/LoRaMac-node/system/gpio.c \
../Drivers/LoRaMac-node/system/i2c.c \
../Drivers/LoRaMac-node/system/nvmm.c \
../Drivers/LoRaMac-node/system/systime.c \
../Drivers/LoRaMac-node/system/timer.c 

C_DEPS += \
./Drivers/LoRaMac-node/system/delay.d \
./Drivers/LoRaMac-node/system/fifo.d \
./Drivers/LoRaMac-node/system/gpio.d \
./Drivers/LoRaMac-node/system/i2c.d \
./Drivers/LoRaMac-node/system/nvmm.d \
./Drivers/LoRaMac-node/system/systime.d \
./Drivers/LoRaMac-node/system/timer.d 

OBJS += \
./Drivers/LoRaMac-node/system/delay.o \
./Drivers/LoRaMac-node/system/fifo.o \
./Drivers/LoRaMac-node/system/gpio.o \
./Drivers/LoRaMac-node/system/i2c.o \
./Drivers/LoRaMac-node/system/nvmm.o \
./Drivers/LoRaMac-node/system/systime.o \
./Drivers/LoRaMac-node/system/timer.o 


# Each subdirectory must supply rules for building sources it contributes
Drivers/LoRaMac-node/system/%.o Drivers/LoRaMac-node/system/%.su: ../Drivers/LoRaMac-node/system/%.c Drivers/LoRaMac-node/system/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -I"/hw/ibt-1-fw/Drivers/BSEC/inc" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-Drivers-2f-LoRaMac-2d-node-2f-system

clean-Drivers-2f-LoRaMac-2d-node-2f-system:
	-$(RM) ./Drivers/LoRaMac-node/system/delay.d ./Drivers/LoRaMac-node/system/delay.o ./Drivers/LoRaMac-node/system/delay.su ./Drivers/LoRaMac-node/system/fifo.d ./Drivers/LoRaMac-node/system/fifo.o ./Drivers/LoRaMac-node/system/fifo.su ./Drivers/LoRaMac-node/system/gpio.d ./Drivers/LoRaMac-node/system/gpio.o ./Drivers/LoRaMac-node/system/gpio.su ./Drivers/LoRaMac-node/system/i2c.d ./Drivers/LoRaMac-node/system/i2c.o ./Drivers/LoRaMac-node/system/i2c.su ./Drivers/LoRaMac-node/system/nvmm.d ./Drivers/LoRaMac-node/system/nvmm.o ./Drivers/LoRaMac-node/system/nvmm.su ./Drivers/LoRaMac-node/system/systime.d ./Drivers/LoRaMac-node/system/systime.o ./Drivers/LoRaMac-node/system/systime.su ./Drivers/LoRaMac-node/system/timer.d ./Drivers/LoRaMac-node/system/timer.o ./Drivers/LoRaMac-node/system/timer.su

.PHONY: clean-Drivers-2f-LoRaMac-2d-node-2f-system

