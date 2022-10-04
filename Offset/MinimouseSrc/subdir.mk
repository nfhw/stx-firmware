################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../MinimouseSrc/LoRaMacCryptoMiniMouse.cpp \
../MinimouseSrc/LoraWanProcess.cpp \
../MinimouseSrc/MacLayer.cpp \
../MinimouseSrc/MiniMouseAes.cpp \
../MinimouseSrc/MiniMouseCmac.cpp \
../MinimouseSrc/PhyLayer.cpp \
../MinimouseSrc/RadioIsrRoutine.cpp \
../MinimouseSrc/RegionUS.cpp \
../MinimouseSrc/Regions.cpp \
../MinimouseSrc/TimerIsrRoutine.cpp \
../MinimouseSrc/utilities.cpp 

OBJS += \
./MinimouseSrc/LoRaMacCryptoMiniMouse.o \
./MinimouseSrc/LoraWanProcess.o \
./MinimouseSrc/MacLayer.o \
./MinimouseSrc/MiniMouseAes.o \
./MinimouseSrc/MiniMouseCmac.o \
./MinimouseSrc/PhyLayer.o \
./MinimouseSrc/RadioIsrRoutine.o \
./MinimouseSrc/RegionUS.o \
./MinimouseSrc/Regions.o \
./MinimouseSrc/TimerIsrRoutine.o \
./MinimouseSrc/utilities.o 

CPP_DEPS += \
./MinimouseSrc/LoRaMacCryptoMiniMouse.d \
./MinimouseSrc/LoraWanProcess.d \
./MinimouseSrc/MacLayer.d \
./MinimouseSrc/MiniMouseAes.d \
./MinimouseSrc/MiniMouseCmac.d \
./MinimouseSrc/PhyLayer.d \
./MinimouseSrc/RadioIsrRoutine.d \
./MinimouseSrc/RegionUS.d \
./MinimouseSrc/Regions.d \
./MinimouseSrc/TimerIsrRoutine.d \
./MinimouseSrc/utilities.d 


# Each subdirectory must supply rules for building sources it contributes
MinimouseSrc/LoRaMacCryptoMiniMouse.o: ../MinimouseSrc/LoRaMacCryptoMiniMouse.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/LoRaMacCryptoMiniMouse.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
MinimouseSrc/LoraWanProcess.o: ../MinimouseSrc/LoraWanProcess.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/LoraWanProcess.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
MinimouseSrc/MacLayer.o: ../MinimouseSrc/MacLayer.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/MacLayer.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
MinimouseSrc/MiniMouseAes.o: ../MinimouseSrc/MiniMouseAes.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/MiniMouseAes.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
MinimouseSrc/MiniMouseCmac.o: ../MinimouseSrc/MiniMouseCmac.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/MiniMouseCmac.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
MinimouseSrc/PhyLayer.o: ../MinimouseSrc/PhyLayer.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/PhyLayer.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
MinimouseSrc/RadioIsrRoutine.o: ../MinimouseSrc/RadioIsrRoutine.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/RadioIsrRoutine.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
MinimouseSrc/RegionUS.o: ../MinimouseSrc/RegionUS.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/RegionUS.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
MinimouseSrc/Regions.o: ../MinimouseSrc/Regions.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/Regions.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
MinimouseSrc/TimerIsrRoutine.o: ../MinimouseSrc/TimerIsrRoutine.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/TimerIsrRoutine.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"
MinimouseSrc/utilities.o: ../MinimouseSrc/utilities.cpp
	arm-none-eabi-g++ "$<" -mcpu=cortex-m0plus -std=gnu++14 -g3 -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER '-DLOW_POWER_MODE=0' -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/lib_nfc/common/inc" -I"/hw/ibt-1-fw/lib_nfc/lib_NDEF/inc" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/radio/SX126X" -I"/hw/ibt-1-fw/radio/sx1272" -I"/hw/ibt-1-fw/radio/SX1276Lib/sx1276" -I"/hw/ibt-1-fw/radio/SX1276Lib/registers" -I"/hw/ibt-1-fw/MinimouseSrc" -I"/hw/ibt-1-fw/MmServices" -I"/hw/ibt-1-fw/McuApi" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/HDC2080" -I"/hw/ibt-1-fw/cryptolib" -Os -ffunction-sections -fdata-sections -fno-exceptions -fno-rtti -fno-use-cxa-atexit -Wall -fstack-usage -MMD -MP -MF"MinimouseSrc/utilities.d" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

