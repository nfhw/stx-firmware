################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../mbed-os/platform/mbed_application.c \
../mbed-os/platform/mbed_assert.c \
../mbed-os/platform/mbed_board.c \
../mbed-os/platform/mbed_critical.c \
../mbed-os/platform/mbed_error.c \
../mbed-os/platform/mbed_interface.c \
../mbed-os/platform/mbed_mktime.c \
../mbed-os/platform/mbed_sdk_boot.c \
../mbed-os/platform/mbed_semihost_api.c \
../mbed-os/platform/mbed_stats.c \
../mbed-os/platform/mbed_wait_api_no_rtos.c 

CPP_SRCS += \
../mbed-os/platform/ATCmdParser.cpp \
../mbed-os/platform/CallChain.cpp \
../mbed-os/platform/FileBase.cpp \
../mbed-os/platform/FileHandle.cpp \
../mbed-os/platform/FilePath.cpp \
../mbed-os/platform/FileSystemHandle.cpp \
../mbed-os/platform/LocalFileSystem.cpp \
../mbed-os/platform/Stream.cpp \
../mbed-os/platform/mbed_alloc_wrappers.cpp \
../mbed-os/platform/mbed_mem_trace.cpp \
../mbed-os/platform/mbed_poll.cpp \
../mbed-os/platform/mbed_retarget.cpp \
../mbed-os/platform/mbed_rtc_time.cpp \
../mbed-os/platform/mbed_wait_api_rtos.cpp 

OBJS += \
./mbed-os/platform/ATCmdParser.o \
./mbed-os/platform/CallChain.o \
./mbed-os/platform/FileBase.o \
./mbed-os/platform/FileHandle.o \
./mbed-os/platform/FilePath.o \
./mbed-os/platform/FileSystemHandle.o \
./mbed-os/platform/LocalFileSystem.o \
./mbed-os/platform/Stream.o \
./mbed-os/platform/mbed_alloc_wrappers.o \
./mbed-os/platform/mbed_application.o \
./mbed-os/platform/mbed_assert.o \
./mbed-os/platform/mbed_board.o \
./mbed-os/platform/mbed_critical.o \
./mbed-os/platform/mbed_error.o \
./mbed-os/platform/mbed_interface.o \
./mbed-os/platform/mbed_mem_trace.o \
./mbed-os/platform/mbed_mktime.o \
./mbed-os/platform/mbed_poll.o \
./mbed-os/platform/mbed_retarget.o \
./mbed-os/platform/mbed_rtc_time.o \
./mbed-os/platform/mbed_sdk_boot.o \
./mbed-os/platform/mbed_semihost_api.o \
./mbed-os/platform/mbed_stats.o \
./mbed-os/platform/mbed_wait_api_no_rtos.o \
./mbed-os/platform/mbed_wait_api_rtos.o 

C_DEPS += \
./mbed-os/platform/mbed_application.d \
./mbed-os/platform/mbed_assert.d \
./mbed-os/platform/mbed_board.d \
./mbed-os/platform/mbed_critical.d \
./mbed-os/platform/mbed_error.d \
./mbed-os/platform/mbed_interface.d \
./mbed-os/platform/mbed_mktime.d \
./mbed-os/platform/mbed_sdk_boot.d \
./mbed-os/platform/mbed_semihost_api.d \
./mbed-os/platform/mbed_stats.d \
./mbed-os/platform/mbed_wait_api_no_rtos.d 

CPP_DEPS += \
./mbed-os/platform/ATCmdParser.d \
./mbed-os/platform/CallChain.d \
./mbed-os/platform/FileBase.d \
./mbed-os/platform/FileHandle.d \
./mbed-os/platform/FilePath.d \
./mbed-os/platform/FileSystemHandle.d \
./mbed-os/platform/LocalFileSystem.d \
./mbed-os/platform/Stream.d \
./mbed-os/platform/mbed_alloc_wrappers.d \
./mbed-os/platform/mbed_mem_trace.d \
./mbed-os/platform/mbed_poll.d \
./mbed-os/platform/mbed_retarget.d \
./mbed-os/platform/mbed_rtc_time.d \
./mbed-os/platform/mbed_wait_api_rtos.d 


# Each subdirectory must supply rules for building sources it contributes
mbed-os/platform/%.o: ../mbed-os/platform/%.cpp
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C++ Compiler'
	arm-none-eabi-g++ -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -std=gnu++11 -fabi-version=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

mbed-os/platform/%.o: ../mbed-os/platform/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


