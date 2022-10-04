################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../mbed-os/events/equeue/equeue.c \
../mbed-os/events/equeue/equeue_posix.c 

CPP_SRCS += \
../mbed-os/events/equeue/equeue_mbed.cpp 

OBJS += \
./mbed-os/events/equeue/equeue.o \
./mbed-os/events/equeue/equeue_mbed.o \
./mbed-os/events/equeue/equeue_posix.o 

C_DEPS += \
./mbed-os/events/equeue/equeue.d \
./mbed-os/events/equeue/equeue_posix.d 

CPP_DEPS += \
./mbed-os/events/equeue/equeue_mbed.d 


# Each subdirectory must supply rules for building sources it contributes
mbed-os/events/equeue/%.o: ../mbed-os/events/equeue/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

mbed-os/events/equeue/%.o: ../mbed-os/events/equeue/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C++ Compiler'
	arm-none-eabi-g++ -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -std=gnu++11 -fabi-version=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


