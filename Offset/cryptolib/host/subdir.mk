################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../cryptolib/host/atca_host.c 

C_DEPS += \
./cryptolib/host/atca_host.d 

OBJS += \
./cryptolib/host/atca_host.o 


# Each subdirectory must supply rules for building sources it contributes
cryptolib/host/atca_host.o: ../cryptolib/host/atca_host.c
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g3 -DSTM32L071xx '-DVECT_TAB_OFFSET=0x8000' -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -DNFUSE -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP -MF"cryptolib/host/atca_host.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

