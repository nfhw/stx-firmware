################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../mbed-os/events/equeue/tests/prof.c \
../mbed-os/events/equeue/tests/tests.c 

OBJS += \
./mbed-os/events/equeue/tests/prof.o \
./mbed-os/events/equeue/tests/tests.o 

C_DEPS += \
./mbed-os/events/equeue/tests/prof.d \
./mbed-os/events/equeue/tests/tests.d 


# Each subdirectory must supply rules for building sources it contributes
mbed-os/events/equeue/tests/%.o: ../mbed-os/events/equeue/tests/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


