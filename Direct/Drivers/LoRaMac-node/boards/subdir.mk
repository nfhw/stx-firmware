################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Drivers/LoRaMac-node/boards/board.c \
../Drivers/LoRaMac-node/boards/delay-board.c \
../Drivers/LoRaMac-node/boards/eeprom-board.c \
../Drivers/LoRaMac-node/boards/gpio-board.c \
../Drivers/LoRaMac-node/boards/lpm-board.c \
../Drivers/LoRaMac-node/boards/rtc-board.c \
../Drivers/LoRaMac-node/boards/spi-board.c \
../Drivers/LoRaMac-node/boards/sx1261mbxbas-board.c \
../Drivers/LoRaMac-node/boards/utilities.c 

C_DEPS += \
./Drivers/LoRaMac-node/boards/board.d \
./Drivers/LoRaMac-node/boards/delay-board.d \
./Drivers/LoRaMac-node/boards/eeprom-board.d \
./Drivers/LoRaMac-node/boards/gpio-board.d \
./Drivers/LoRaMac-node/boards/lpm-board.d \
./Drivers/LoRaMac-node/boards/rtc-board.d \
./Drivers/LoRaMac-node/boards/spi-board.d \
./Drivers/LoRaMac-node/boards/sx1261mbxbas-board.d \
./Drivers/LoRaMac-node/boards/utilities.d 

OBJS += \
./Drivers/LoRaMac-node/boards/board.o \
./Drivers/LoRaMac-node/boards/delay-board.o \
./Drivers/LoRaMac-node/boards/eeprom-board.o \
./Drivers/LoRaMac-node/boards/gpio-board.o \
./Drivers/LoRaMac-node/boards/lpm-board.o \
./Drivers/LoRaMac-node/boards/rtc-board.o \
./Drivers/LoRaMac-node/boards/spi-board.o \
./Drivers/LoRaMac-node/boards/sx1261mbxbas-board.o \
./Drivers/LoRaMac-node/boards/utilities.o 


# Each subdirectory must supply rules for building sources it contributes
Drivers/LoRaMac-node/boards/%.o Drivers/LoRaMac-node/boards/%.su: ../Drivers/LoRaMac-node/boards/%.c Drivers/LoRaMac-node/boards/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -I"/hw/ibt-1-fw/Drivers/BSEC/inc" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-Drivers-2f-LoRaMac-2d-node-2f-boards

clean-Drivers-2f-LoRaMac-2d-node-2f-boards:
	-$(RM) ./Drivers/LoRaMac-node/boards/board.d ./Drivers/LoRaMac-node/boards/board.o ./Drivers/LoRaMac-node/boards/board.su ./Drivers/LoRaMac-node/boards/delay-board.d ./Drivers/LoRaMac-node/boards/delay-board.o ./Drivers/LoRaMac-node/boards/delay-board.su ./Drivers/LoRaMac-node/boards/eeprom-board.d ./Drivers/LoRaMac-node/boards/eeprom-board.o ./Drivers/LoRaMac-node/boards/eeprom-board.su ./Drivers/LoRaMac-node/boards/gpio-board.d ./Drivers/LoRaMac-node/boards/gpio-board.o ./Drivers/LoRaMac-node/boards/gpio-board.su ./Drivers/LoRaMac-node/boards/lpm-board.d ./Drivers/LoRaMac-node/boards/lpm-board.o ./Drivers/LoRaMac-node/boards/lpm-board.su ./Drivers/LoRaMac-node/boards/rtc-board.d ./Drivers/LoRaMac-node/boards/rtc-board.o ./Drivers/LoRaMac-node/boards/rtc-board.su ./Drivers/LoRaMac-node/boards/spi-board.d ./Drivers/LoRaMac-node/boards/spi-board.o ./Drivers/LoRaMac-node/boards/spi-board.su ./Drivers/LoRaMac-node/boards/sx1261mbxbas-board.d ./Drivers/LoRaMac-node/boards/sx1261mbxbas-board.o ./Drivers/LoRaMac-node/boards/sx1261mbxbas-board.su ./Drivers/LoRaMac-node/boards/utilities.d ./Drivers/LoRaMac-node/boards/utilities.o ./Drivers/LoRaMac-node/boards/utilities.su

.PHONY: clean-Drivers-2f-LoRaMac-2d-node-2f-boards

