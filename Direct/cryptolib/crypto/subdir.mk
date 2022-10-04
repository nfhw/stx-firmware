################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (10.3-2021.10)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../cryptolib/crypto/atca_crypto_hw_aes_cbc.c \
../cryptolib/crypto/atca_crypto_hw_aes_cbcmac.c \
../cryptolib/crypto/atca_crypto_hw_aes_ccm.c \
../cryptolib/crypto/atca_crypto_hw_aes_cmac.c \
../cryptolib/crypto/atca_crypto_hw_aes_ctr.c \
../cryptolib/crypto/atca_crypto_sw_ecdsa.c \
../cryptolib/crypto/atca_crypto_sw_rand.c \
../cryptolib/crypto/atca_crypto_sw_sha1.c \
../cryptolib/crypto/atca_crypto_sw_sha2.c 

C_DEPS += \
./cryptolib/crypto/atca_crypto_hw_aes_cbc.d \
./cryptolib/crypto/atca_crypto_hw_aes_cbcmac.d \
./cryptolib/crypto/atca_crypto_hw_aes_ccm.d \
./cryptolib/crypto/atca_crypto_hw_aes_cmac.d \
./cryptolib/crypto/atca_crypto_hw_aes_ctr.d \
./cryptolib/crypto/atca_crypto_sw_ecdsa.d \
./cryptolib/crypto/atca_crypto_sw_rand.d \
./cryptolib/crypto/atca_crypto_sw_sha1.d \
./cryptolib/crypto/atca_crypto_sw_sha2.d 

OBJS += \
./cryptolib/crypto/atca_crypto_hw_aes_cbc.o \
./cryptolib/crypto/atca_crypto_hw_aes_cbcmac.o \
./cryptolib/crypto/atca_crypto_hw_aes_ccm.o \
./cryptolib/crypto/atca_crypto_hw_aes_cmac.o \
./cryptolib/crypto/atca_crypto_hw_aes_ctr.o \
./cryptolib/crypto/atca_crypto_sw_ecdsa.o \
./cryptolib/crypto/atca_crypto_sw_rand.o \
./cryptolib/crypto/atca_crypto_sw_sha1.o \
./cryptolib/crypto/atca_crypto_sw_sha2.o 


# Each subdirectory must supply rules for building sources it contributes
cryptolib/crypto/%.o cryptolib/crypto/%.su: ../cryptolib/crypto/%.c cryptolib/crypto/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m0plus -std=gnu11 -g -DSTM32L071xx -DARM_MATH_CM0 -DDEBUG -DUSE_STDPERIPH_DRIVER -DLOW_POWER_MODE=0 -DSOFT_SE -DREGION_EU868 -DREGION_US915 -c -I"/hw/ibt-1-fw/Drivers/STM32L0xx_HAL_Driver/Inc" -I"/hw/ibt-1-fw/Drivers/CMSIS/Include" -I"/hw/ibt-1-fw/Drivers/CMSIS/Device/ST/STM32L0xx/Include" -I"/hw/ibt-1-fw/Drivers/ST25DV" -I"/hw/ibt-1-fw/Drivers/RTT" -I"/hw/ibt-1-fw/Inc" -I"/hw/ibt-1-fw/BMA400" -I"/hw/ibt-1-fw/BME680" -I"/hw/ibt-1-fw/cryptolib" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/mac/region" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node/boards" -I"/hw/ibt-1-fw/Drivers/LoRaMac-node" -I"/hw/ibt-1-fw/Drivers" -I"/hw/ibt-1-fw/radio" -I"/hw/ibt-1-fw/radio/sx126x" -I"/hw/ibt-1-fw/Drivers/BSEC/inc" -Os -ffunction-sections -fdata-sections -Wall -fno-common -fstack-usage -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfloat-abi=soft -mthumb -o "$@"

clean: clean-cryptolib-2f-crypto

clean-cryptolib-2f-crypto:
	-$(RM) ./cryptolib/crypto/atca_crypto_hw_aes_cbc.d ./cryptolib/crypto/atca_crypto_hw_aes_cbc.o ./cryptolib/crypto/atca_crypto_hw_aes_cbc.su ./cryptolib/crypto/atca_crypto_hw_aes_cbcmac.d ./cryptolib/crypto/atca_crypto_hw_aes_cbcmac.o ./cryptolib/crypto/atca_crypto_hw_aes_cbcmac.su ./cryptolib/crypto/atca_crypto_hw_aes_ccm.d ./cryptolib/crypto/atca_crypto_hw_aes_ccm.o ./cryptolib/crypto/atca_crypto_hw_aes_ccm.su ./cryptolib/crypto/atca_crypto_hw_aes_cmac.d ./cryptolib/crypto/atca_crypto_hw_aes_cmac.o ./cryptolib/crypto/atca_crypto_hw_aes_cmac.su ./cryptolib/crypto/atca_crypto_hw_aes_ctr.d ./cryptolib/crypto/atca_crypto_hw_aes_ctr.o ./cryptolib/crypto/atca_crypto_hw_aes_ctr.su ./cryptolib/crypto/atca_crypto_sw_ecdsa.d ./cryptolib/crypto/atca_crypto_sw_ecdsa.o ./cryptolib/crypto/atca_crypto_sw_ecdsa.su ./cryptolib/crypto/atca_crypto_sw_rand.d ./cryptolib/crypto/atca_crypto_sw_rand.o ./cryptolib/crypto/atca_crypto_sw_rand.su ./cryptolib/crypto/atca_crypto_sw_sha1.d ./cryptolib/crypto/atca_crypto_sw_sha1.o ./cryptolib/crypto/atca_crypto_sw_sha1.su ./cryptolib/crypto/atca_crypto_sw_sha2.d ./cryptolib/crypto/atca_crypto_sw_sha2.o ./cryptolib/crypto/atca_crypto_sw_sha2.su

.PHONY: clean-cryptolib-2f-crypto

