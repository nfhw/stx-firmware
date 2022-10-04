################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../mbed-os/events/EventQueue.cpp \
../mbed-os/events/mbed_shared_queues.cpp 

OBJS += \
./mbed-os/events/EventQueue.o \
./mbed-os/events/mbed_shared_queues.o 

CPP_DEPS += \
./mbed-os/events/EventQueue.d \
./mbed-os/events/mbed_shared_queues.d 


# Each subdirectory must supply rules for building sources it contributes
mbed-os/events/%.o: ../mbed-os/events/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C++ Compiler'
	arm-none-eabi-g++ -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -std=gnu++11 -fabi-version=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


