################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Drivers/LoRaMac-node/mac/region/Region.c \
../Drivers/LoRaMac-node/mac/region/RegionBaseUS.c \
../Drivers/LoRaMac-node/mac/region/RegionCommon.c \
../Drivers/LoRaMac-node/mac/region/RegionEU868.c \
../Drivers/LoRaMac-node/mac/region/RegionUS915.c 

C_DEPS += \
./Drivers/LoRaMac-node/mac/region/Region.d \
./Drivers/LoRaMac-node/mac/region/RegionBaseUS.d \
./Drivers/LoRaMac-node/mac/region/RegionCommon.d \
./Drivers/LoRaMac-node/mac/region/RegionEU868.d \
./Drivers/LoRaMac-node/mac/region/RegionUS915.d 

OBJS += \
./Drivers/LoRaMac-node/mac/region/Region.o \
./Drivers/LoRaMac-node/mac/region/RegionBaseUS.o \
./Drivers/LoRaMac-node/mac/region/RegionCommon.o \
./Drivers/LoRaMac-node/mac/region/RegionEU868.o \
./Drivers/LoRaMac-node/mac/region/RegionUS915.o 


# Each subdirectory must supply rules for building sources it contributes
Drivers/LoRaMac-node/mac/region/%.o Drivers/LoRaMac-node/mac/region/%.su: ../Drivers/LoRaMac-node/mac/region/%.c Drivers/LoRaMac-node/mac/region/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-Drivers-2f-LoRaMac-2d-node-2f-mac-2f-region

clean-Drivers-2f-LoRaMac-2d-node-2f-mac-2f-region:
	-$(RM) ./Drivers/LoRaMac-node/mac/region/Region.d ./Drivers/LoRaMac-node/mac/region/Region.o ./Drivers/LoRaMac-node/mac/region/Region.su ./Drivers/LoRaMac-node/mac/region/RegionBaseUS.d ./Drivers/LoRaMac-node/mac/region/RegionBaseUS.o ./Drivers/LoRaMac-node/mac/region/RegionBaseUS.su ./Drivers/LoRaMac-node/mac/region/RegionCommon.d ./Drivers/LoRaMac-node/mac/region/RegionCommon.o ./Drivers/LoRaMac-node/mac/region/RegionCommon.su ./Drivers/LoRaMac-node/mac/region/RegionEU868.d ./Drivers/LoRaMac-node/mac/region/RegionEU868.o ./Drivers/LoRaMac-node/mac/region/RegionEU868.su ./Drivers/LoRaMac-node/mac/region/RegionUS915.d ./Drivers/LoRaMac-node/mac/region/RegionUS915.o ./Drivers/LoRaMac-node/mac/region/RegionUS915.su

.PHONY: clean-Drivers-2f-LoRaMac-2d-node-2f-mac-2f-region

