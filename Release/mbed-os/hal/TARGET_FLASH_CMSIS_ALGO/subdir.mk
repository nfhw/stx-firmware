################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../mbed-os/hal/TARGET_FLASH_CMSIS_ALGO/flash_common_algo.c 

OBJS += \
./mbed-os/hal/TARGET_FLASH_CMSIS_ALGO/flash_common_algo.o 

C_DEPS += \
./mbed-os/hal/TARGET_FLASH_CMSIS_ALGO/flash_common_algo.d 


# Each subdirectory must supply rules for building sources it contributes
mbed-os/hal/TARGET_FLASH_CMSIS_ALGO/%.o: ../mbed-os/hal/TARGET_FLASH_CMSIS_ALGO/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


