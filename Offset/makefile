################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include radio/sx1272/subdir.mk
-include radio/SX1276Lib/sx1276/subdir.mk
-include radio/SX126X/subdir.mk
-include cryptolib/jwt/subdir.mk
-include cryptolib/host/subdir.mk
-include cryptolib/hal/subdir.mk
-include cryptolib/crypto/hashes/subdir.mk
-include cryptolib/crypto/subdir.mk
-include cryptolib/calib/subdir.mk
-include cryptolib/atcacert/subdir.mk
-include cryptolib/subdir.mk
-include Src/subdir.mk
-include MinimouseSrc/subdir.mk
-include McuApi/subdir.mk
-include HDC2080/subdir.mk
-include Drivers/STM32L0xx_HAL_Driver/Src/subdir.mk
-include Drivers/ST25DV/subdir.mk
-include Drivers/RTT/subdir.mk
-include BME680/subdir.mk
-include BMA400/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(CC_DEPS)),)
-include $(CC_DEPS)
endif
ifneq ($(strip $(C++_DEPS)),)
-include $(C++_DEPS)
endif
ifneq ($(strip $(C_UPPER_DEPS)),)
-include $(C_UPPER_DEPS)
endif
ifneq ($(strip $(CXX_DEPS)),)
-include $(CXX_DEPS)
endif
ifneq ($(strip $(S_DEPS)),)
-include $(S_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
ifneq ($(strip $(CPP_DEPS)),)
-include $(CPP_DEPS)
endif
endif

-include ../makefile.defs

BUILD_ARTIFACT_NAME := ibt-1-fw
BUILD_ARTIFACT_EXTENSION := elf
BUILD_ARTIFACT_PREFIX := 
BUILD_ARTIFACT := $(BUILD_ARTIFACT_PREFIX)$(BUILD_ARTIFACT_NAME).$(BUILD_ARTIFACT_EXTENSION)

# Add inputs and outputs from these tool invocations to the build variables 
EXECUTABLES += \
ibt-1-fw.elf \

SIZE_OUTPUT += \
default.size.stdout \

OBJDUMP_LIST += \
ibt-1-fw.list \

OBJCOPY_BIN += \
ibt-1-fw.bin \


# All Target
all: main-build

# Main-build Target
main-build: ibt-1-fw.elf secondary-outputs

# Tool invocations
ibt-1-fw.elf: $(OBJS) $(USER_OBJS) ../ldscripts/linker_via_bootldr.ld
	arm-none-eabi-g++ -o "ibt-1-fw.elf" @"objects.list" $(USER_OBJS) $(LIBS) -mcpu=cortex-m0plus -T"../ldscripts/linker_via_bootldr.ld" --specs=nosys.specs -Wl,-Map="ibt-1-fw.map" -Wl,--gc-sections -static -Wl,-cref,-u,Reset_Handler --specs=nano.specs -mfloat-abi=soft -mthumb -Wl,--start-group -lc -lm -lstdc++ -lsupc++ -Wl,--end-group
	@echo 'Finished building target: $@'
	@echo ' '

default.size.stdout: $(EXECUTABLES)
	arm-none-eabi-size  $(EXECUTABLES)
	@echo 'Finished building: $@'
	@echo ' '

ibt-1-fw.list: $(EXECUTABLES)
	arm-none-eabi-objdump -h -S $(EXECUTABLES) > "ibt-1-fw.list"
	@echo 'Finished building: $@'
	@echo ' '

ibt-1-fw.bin: $(EXECUTABLES)
	arm-none-eabi-objcopy  -O binary $(EXECUTABLES) "ibt-1-fw.bin"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) *
	-@echo ' '

secondary-outputs: $(SIZE_OUTPUT) $(OBJDUMP_LIST) $(OBJCOPY_BIN)

fail-specified-linker-script-missing:
	@echo 'Error: Cannot find the specified linker script. Check the linker settings in the build configuration.'
	@exit 2

warn-no-linker-script-specified:
	@echo 'Warning: No linker script specified. Check the linker settings in the build configuration.'

.PHONY: all clean dependents fail-specified-linker-script-missing warn-no-linker-script-specified
.SECONDARY:

-include ../makefile.targets
