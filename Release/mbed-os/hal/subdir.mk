################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../mbed-os/hal/mbed_critical_section_api.c \
../mbed-os/hal/mbed_flash_api.c \
../mbed-os/hal/mbed_gpio.c \
../mbed-os/hal/mbed_itm_api.c \
../mbed-os/hal/mbed_lp_ticker_api.c \
../mbed-os/hal/mbed_pinmap_common.c \
../mbed-os/hal/mbed_sleep_manager.c \
../mbed-os/hal/mbed_ticker_api.c \
../mbed-os/hal/mbed_us_ticker_api.c 

OBJS += \
./mbed-os/hal/mbed_critical_section_api.o \
./mbed-os/hal/mbed_flash_api.o \
./mbed-os/hal/mbed_gpio.o \
./mbed-os/hal/mbed_itm_api.o \
./mbed-os/hal/mbed_lp_ticker_api.o \
./mbed-os/hal/mbed_pinmap_common.o \
./mbed-os/hal/mbed_sleep_manager.o \
./mbed-os/hal/mbed_ticker_api.o \
./mbed-os/hal/mbed_us_ticker_api.o 

C_DEPS += \
./mbed-os/hal/mbed_critical_section_api.d \
./mbed-os/hal/mbed_flash_api.d \
./mbed-os/hal/mbed_gpio.d \
./mbed-os/hal/mbed_itm_api.d \
./mbed-os/hal/mbed_lp_ticker_api.d \
./mbed-os/hal/mbed_pinmap_common.d \
./mbed-os/hal/mbed_sleep_manager.d \
./mbed-os/hal/mbed_ticker_api.d \
./mbed-os/hal/mbed_us_ticker_api.d 


# Each subdirectory must supply rules for building sources it contributes
mbed-os/hal/%.o: ../mbed-os/hal/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


