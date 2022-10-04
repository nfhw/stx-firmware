################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Drivers/LoRaMac-node/common/LmHandlerMsgDisplay.c \
../Drivers/LoRaMac-node/common/NvmDataMgmt.c 

C_DEPS += \
./Drivers/LoRaMac-node/common/LmHandlerMsgDisplay.d \
./Drivers/LoRaMac-node/common/NvmDataMgmt.d 

OBJS += \
./Drivers/LoRaMac-node/common/LmHandlerMsgDisplay.o \
./Drivers/LoRaMac-node/common/NvmDataMgmt.o 


# Each subdirectory must supply rules for building sources it contributes
Drivers/LoRaMac-node/common/%.o Drivers/LoRaMac-node/common/%.su: ../Drivers/LoRaMac-node/common/%.c Drivers/LoRaMac-node/common/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -I"/hw/ibt-1-fw/Drivers/BSEC/inc" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-Drivers-2f-LoRaMac-2d-node-2f-common

clean-Drivers-2f-LoRaMac-2d-node-2f-common:
	-$(RM) ./Drivers/LoRaMac-node/common/LmHandlerMsgDisplay.d ./Drivers/LoRaMac-node/common/LmHandlerMsgDisplay.o ./Drivers/LoRaMac-node/common/LmHandlerMsgDisplay.su ./Drivers/LoRaMac-node/common/NvmDataMgmt.d ./Drivers/LoRaMac-node/common/NvmDataMgmt.o ./Drivers/LoRaMac-node/common/NvmDataMgmt.su

.PHONY: clean-Drivers-2f-LoRaMac-2d-node-2f-common

