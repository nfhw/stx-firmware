################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Drivers/LoRaMac-node/mac/LoRaMac.c \
../Drivers/LoRaMac-node/mac/LoRaMacAdr.c \
../Drivers/LoRaMac-node/mac/LoRaMacClassB.c \
../Drivers/LoRaMac-node/mac/LoRaMacCommands.c \
../Drivers/LoRaMac-node/mac/LoRaMacConfirmQueue.c \
../Drivers/LoRaMac-node/mac/LoRaMacCrypto.c \
../Drivers/LoRaMac-node/mac/LoRaMacParser.c \
../Drivers/LoRaMac-node/mac/LoRaMacSerializer.c 

C_DEPS += \
./Drivers/LoRaMac-node/mac/LoRaMac.d \
./Drivers/LoRaMac-node/mac/LoRaMacAdr.d \
./Drivers/LoRaMac-node/mac/LoRaMacClassB.d \
./Drivers/LoRaMac-node/mac/LoRaMacCommands.d \
./Drivers/LoRaMac-node/mac/LoRaMacConfirmQueue.d \
./Drivers/LoRaMac-node/mac/LoRaMacCrypto.d \
./Drivers/LoRaMac-node/mac/LoRaMacParser.d \
./Drivers/LoRaMac-node/mac/LoRaMacSerializer.d 

OBJS += \
./Drivers/LoRaMac-node/mac/LoRaMac.o \
./Drivers/LoRaMac-node/mac/LoRaMacAdr.o \
./Drivers/LoRaMac-node/mac/LoRaMacClassB.o \
./Drivers/LoRaMac-node/mac/LoRaMacCommands.o \
./Drivers/LoRaMac-node/mac/LoRaMacConfirmQueue.o \
./Drivers/LoRaMac-node/mac/LoRaMacCrypto.o \
./Drivers/LoRaMac-node/mac/LoRaMacParser.o \
./Drivers/LoRaMac-node/mac/LoRaMacSerializer.o 


# Each subdirectory must supply rules for building sources it contributes
Drivers/LoRaMac-node/mac/%.o Drivers/LoRaMac-node/mac/%.su: ../Drivers/LoRaMac-node/mac/%.c Drivers/LoRaMac-node/mac/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-Drivers-2f-LoRaMac-2d-node-2f-mac

clean-Drivers-2f-LoRaMac-2d-node-2f-mac:
	-$(RM) ./Drivers/LoRaMac-node/mac/LoRaMac.d ./Drivers/LoRaMac-node/mac/LoRaMac.o ./Drivers/LoRaMac-node/mac/LoRaMac.su ./Drivers/LoRaMac-node/mac/LoRaMacAdr.d ./Drivers/LoRaMac-node/mac/LoRaMacAdr.o ./Drivers/LoRaMac-node/mac/LoRaMacAdr.su ./Drivers/LoRaMac-node/mac/LoRaMacClassB.d ./Drivers/LoRaMac-node/mac/LoRaMacClassB.o ./Drivers/LoRaMac-node/mac/LoRaMacClassB.su ./Drivers/LoRaMac-node/mac/LoRaMacCommands.d ./Drivers/LoRaMac-node/mac/LoRaMacCommands.o ./Drivers/LoRaMac-node/mac/LoRaMacCommands.su ./Drivers/LoRaMac-node/mac/LoRaMacConfirmQueue.d ./Drivers/LoRaMac-node/mac/LoRaMacConfirmQueue.o ./Drivers/LoRaMac-node/mac/LoRaMacConfirmQueue.su ./Drivers/LoRaMac-node/mac/LoRaMacCrypto.d ./Drivers/LoRaMac-node/mac/LoRaMacCrypto.o ./Drivers/LoRaMac-node/mac/LoRaMacCrypto.su ./Drivers/LoRaMac-node/mac/LoRaMacParser.d ./Drivers/LoRaMac-node/mac/LoRaMacParser.o ./Drivers/LoRaMac-node/mac/LoRaMacParser.su ./Drivers/LoRaMac-node/mac/LoRaMacSerializer.d ./Drivers/LoRaMac-node/mac/LoRaMacSerializer.o ./Drivers/LoRaMac-node/mac/LoRaMacSerializer.su

.PHONY: clean-Drivers-2f-LoRaMac-2d-node-2f-mac

