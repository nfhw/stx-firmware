################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../mbed-os/drivers/AnalogIn.cpp \
../mbed-os/drivers/BusIn.cpp \
../mbed-os/drivers/BusInOut.cpp \
../mbed-os/drivers/BusOut.cpp \
../mbed-os/drivers/CAN.cpp \
../mbed-os/drivers/Ethernet.cpp \
../mbed-os/drivers/FlashIAP.cpp \
../mbed-os/drivers/I2C.cpp \
../mbed-os/drivers/I2CSlave.cpp \
../mbed-os/drivers/InterruptIn.cpp \
../mbed-os/drivers/InterruptManager.cpp \
../mbed-os/drivers/MbedCRC.cpp \
../mbed-os/drivers/RawSerial.cpp \
../mbed-os/drivers/SPI.cpp \
../mbed-os/drivers/SPISlave.cpp \
../mbed-os/drivers/Serial.cpp \
../mbed-os/drivers/SerialBase.cpp \
../mbed-os/drivers/TableCRC.cpp \
../mbed-os/drivers/Ticker.cpp \
../mbed-os/drivers/Timeout.cpp \
../mbed-os/drivers/Timer.cpp \
../mbed-os/drivers/TimerEvent.cpp \
../mbed-os/drivers/UARTSerial.cpp 

OBJS += \
./mbed-os/drivers/AnalogIn.o \
./mbed-os/drivers/BusIn.o \
./mbed-os/drivers/BusInOut.o \
./mbed-os/drivers/BusOut.o \
./mbed-os/drivers/CAN.o \
./mbed-os/drivers/Ethernet.o \
./mbed-os/drivers/FlashIAP.o \
./mbed-os/drivers/I2C.o \
./mbed-os/drivers/I2CSlave.o \
./mbed-os/drivers/InterruptIn.o \
./mbed-os/drivers/InterruptManager.o \
./mbed-os/drivers/MbedCRC.o \
./mbed-os/drivers/RawSerial.o \
./mbed-os/drivers/SPI.o \
./mbed-os/drivers/SPISlave.o \
./mbed-os/drivers/Serial.o \
./mbed-os/drivers/SerialBase.o \
./mbed-os/drivers/TableCRC.o \
./mbed-os/drivers/Ticker.o \
./mbed-os/drivers/Timeout.o \
./mbed-os/drivers/Timer.o \
./mbed-os/drivers/TimerEvent.o \
./mbed-os/drivers/UARTSerial.o 

CPP_DEPS += \
./mbed-os/drivers/AnalogIn.d \
./mbed-os/drivers/BusIn.d \
./mbed-os/drivers/BusInOut.d \
./mbed-os/drivers/BusOut.d \
./mbed-os/drivers/CAN.d \
./mbed-os/drivers/Ethernet.d \
./mbed-os/drivers/FlashIAP.d \
./mbed-os/drivers/I2C.d \
./mbed-os/drivers/I2CSlave.d \
./mbed-os/drivers/InterruptIn.d \
./mbed-os/drivers/InterruptManager.d \
./mbed-os/drivers/MbedCRC.d \
./mbed-os/drivers/RawSerial.d \
./mbed-os/drivers/SPI.d \
./mbed-os/drivers/SPISlave.d \
./mbed-os/drivers/Serial.d \
./mbed-os/drivers/SerialBase.d \
./mbed-os/drivers/TableCRC.d \
./mbed-os/drivers/Ticker.d \
./mbed-os/drivers/Timeout.d \
./mbed-os/drivers/Timer.d \
./mbed-os/drivers/TimerEvent.d \
./mbed-os/drivers/UARTSerial.d 


# Each subdirectory must supply rules for building sources it contributes
mbed-os/drivers/%.o: ../mbed-os/drivers/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C++ Compiler'
	arm-none-eabi-g++ -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -std=gnu++11 -fabi-version=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


