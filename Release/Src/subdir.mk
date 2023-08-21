################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Src/adc.c \
../Src/atecc608a_integration.c \
../Src/dma.c \
../Src/eeprom.c \
../Src/gpio.c \
../Src/hardware.c \
../Src/i2c.c \
../Src/isr.c \
../Src/lptim.c \
../Src/lrw.c \
../Src/main.c \
../Src/nfc.c \
../Src/protobuf.c \
../Src/rtc.c \
../Src/sensors.c \
../Src/spi.c \
../Src/stm32l0xx_hal_msp.c \
../Src/stm32l0xx_it.c \
../Src/system_stm32l0xx.c \
../Src/task_mgr.c 

S_UPPER_SRCS += \
../Src/startup_stm32l071xx.S 

C_DEPS += \
./Src/adc.d \
./Src/atecc608a_integration.d \
./Src/dma.d \
./Src/eeprom.d \
./Src/gpio.d \
./Src/hardware.d \
./Src/i2c.d \
./Src/isr.d \
./Src/lptim.d \
./Src/lrw.d \
./Src/main.d \
./Src/nfc.d \
./Src/protobuf.d \
./Src/rtc.d \
./Src/sensors.d \
./Src/spi.d \
./Src/stm32l0xx_hal_msp.d \
./Src/stm32l0xx_it.d \
./Src/system_stm32l0xx.d \
./Src/task_mgr.d 

OBJS += \
./Src/adc.o \
./Src/atecc608a_integration.o \
./Src/dma.o \
./Src/eeprom.o \
./Src/gpio.o \
./Src/hardware.o \
./Src/i2c.o \
./Src/isr.o \
./Src/lptim.o \
./Src/lrw.o \
./Src/main.o \
./Src/nfc.o \
./Src/protobuf.o \
./Src/rtc.o \
./Src/sensors.o \
./Src/spi.o \
./Src/startup_stm32l071xx.o \
./Src/stm32l0xx_hal_msp.o \
./Src/stm32l0xx_it.o \
./Src/system_stm32l0xx.o \
./Src/task_mgr.o 

S_UPPER_DEPS += \
./Src/startup_stm32l071xx.d 


# Each subdirectory must supply rules for building sources it contributes
Src/%.o Src/%.su: ../Src/%.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -DSTM32L071xx -DARM_MATH_CM0 -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
Src/%.o: ../Src/%.S Src/subdir.mk
	arm-none-eabi-gcc -mcpu=cortex-m0plus -DSTM32L071xx -DUSE_STDPERIPH_DRIVER -DOS_INCLUDE_STARTUP_INIT_MULTIPLE_RAM_SECTIONS -c -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32L0xx/Include -I../Drivers/STM32L0xx_HAL_Driver/Inc -I../Src -I../Inc -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -fPIE -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@" "$<"

clean: clean-Src

clean-Src:
	-$(RM) ./Src/adc.d ./Src/adc.o ./Src/adc.su ./Src/atecc608a_integration.d ./Src/atecc608a_integration.o ./Src/atecc608a_integration.su ./Src/dma.d ./Src/dma.o ./Src/dma.su ./Src/eeprom.d ./Src/eeprom.o ./Src/eeprom.su ./Src/gpio.d ./Src/gpio.o ./Src/gpio.su ./Src/hardware.d ./Src/hardware.o ./Src/hardware.su ./Src/i2c.d ./Src/i2c.o ./Src/i2c.su ./Src/isr.d ./Src/isr.o ./Src/isr.su ./Src/lptim.d ./Src/lptim.o ./Src/lptim.su ./Src/lrw.d ./Src/lrw.o ./Src/lrw.su ./Src/main.d ./Src/main.o ./Src/main.su ./Src/nfc.d ./Src/nfc.o ./Src/nfc.su ./Src/protobuf.d ./Src/protobuf.o ./Src/protobuf.su ./Src/rtc.d ./Src/rtc.o ./Src/rtc.su ./Src/sensors.d ./Src/sensors.o ./Src/sensors.su ./Src/spi.d ./Src/spi.o ./Src/spi.su ./Src/startup_stm32l071xx.d ./Src/startup_stm32l071xx.o ./Src/stm32l0xx_hal_msp.d ./Src/stm32l0xx_hal_msp.o ./Src/stm32l0xx_hal_msp.su ./Src/stm32l0xx_it.d ./Src/stm32l0xx_it.o ./Src/stm32l0xx_it.su ./Src/system_stm32l0xx.d ./Src/system_stm32l0xx.o ./Src/system_stm32l0xx.su ./Src/task_mgr.d ./Src/task_mgr.o ./Src/task_mgr.su

.PHONY: clean-Src

