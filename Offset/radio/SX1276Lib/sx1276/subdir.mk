################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../radio/SX1276Lib/sx1276/sx1276.cpp 

OBJS += \
./radio/SX1276Lib/sx1276/sx1276.o 

CPP_DEPS += \
./radio/SX1276Lib/sx1276/sx1276.d 


# Each subdirectory must supply rules for building sources it contributes
radio/SX1276Lib/sx1276/sx1276.o: ../radio/SX1276Lib/sx1276/sx1276.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"radio/SX1276Lib/sx1276/sx1276.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

