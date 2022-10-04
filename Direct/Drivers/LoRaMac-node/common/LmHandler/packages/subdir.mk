################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Drivers/LoRaMac-node/common/LmHandler/packages/FragDecoder.c \
../Drivers/LoRaMac-node/common/LmHandler/packages/LmhpClockSync.c \
../Drivers/LoRaMac-node/common/LmHandler/packages/LmhpCompliance.c \
../Drivers/LoRaMac-node/common/LmHandler/packages/LmhpFragmentation.c \
../Drivers/LoRaMac-node/common/LmHandler/packages/LmhpRemoteMcastSetup.c 

C_DEPS += \
./Drivers/LoRaMac-node/common/LmHandler/packages/FragDecoder.d \
./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpClockSync.d \
./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpCompliance.d \
./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpFragmentation.d \
./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpRemoteMcastSetup.d 

OBJS += \
./Drivers/LoRaMac-node/common/LmHandler/packages/FragDecoder.o \
./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpClockSync.o \
./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpCompliance.o \
./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpFragmentation.o \
./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpRemoteMcastSetup.o 


# Each subdirectory must supply rules for building sources it contributes
Drivers/LoRaMac-node/common/LmHandler/packages/%.o Drivers/LoRaMac-node/common/LmHandler/packages/%.su: ../Drivers/LoRaMac-node/common/LmHandler/packages/%.c Drivers/LoRaMac-node/common/LmHandler/packages/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -I"/hw/ibt-1-fw/Drivers/BSEC/inc" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-Drivers-2f-LoRaMac-2d-node-2f-common-2f-LmHandler-2f-packages

clean-Drivers-2f-LoRaMac-2d-node-2f-common-2f-LmHandler-2f-packages:
	-$(RM) ./Drivers/LoRaMac-node/common/LmHandler/packages/FragDecoder.d ./Drivers/LoRaMac-node/common/LmHandler/packages/FragDecoder.o ./Drivers/LoRaMac-node/common/LmHandler/packages/FragDecoder.su ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpClockSync.d ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpClockSync.o ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpClockSync.su ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpCompliance.d ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpCompliance.o ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpCompliance.su ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpFragmentation.d ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpFragmentation.o ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpFragmentation.su ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpRemoteMcastSetup.d ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpRemoteMcastSetup.o ./Drivers/LoRaMac-node/common/LmHandler/packages/LmhpRemoteMcastSetup.su

.PHONY: clean-Drivers-2f-LoRaMac-2d-node-2f-common-2f-LmHandler-2f-packages

