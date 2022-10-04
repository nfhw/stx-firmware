#!/usr/bin/env -vSLD_LIBRARY_PATH=/usr/local/lib64 arm-none-eabi-gdb -n --batch --command

set width 0
set height 0
set verbose off
set pagination off
set logging file /tmp/gdb.txt

target remote 127.0.0.1:2331
set logging on

# Target
# ------
# MCU: STM32L071KZ
# Core: Cortex-M0+
# Profile: ARMv6-M
# Sources:
# - |
#   https://www.st.com/en/microcontrollers-microprocessors/stm32l071kz.html
#   Resources --> Technical Documentation --> Product Specifications --> DS10690
#   Resources --> Technical Documentation --> Reference Manuals --> RM0377
# - |
#   http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0419e/index.html
#   ARM architecture --> Reference Manuals --> ARMv6-M Architecture Reference Manual (registration required!)
# - |
#   http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0484c/index.html
#   Cortex-M series processors --> Cortex-M0+ --> Revision: r0p1 --> Cortex-M0+ Technical Reference Manual
# pdfs:
#   ds10690: https://www.st.com/resource/en/datasheet/stm32l071kz.pdf
#   rm0377: https://www.st.com/resource/en/reference_manual/dm00108282.pdf
#   ddi0484c_m0p_trm: https://static.docs.arm.com/ddi0484/c/DDI0484C_cortex_m0p_r0p1_trm.pdf
#   ddi0419e_arm_armv6m: https://static.docs.arm.com/ddi0419/e/DDI0419E_armv6m_arm.pdf

# Pitfalls
# --------
# Access MMIO (Memory-Mapped I/O) registers as words, avoid non-word access:
# (gdb) x/4xb 0xe000ed08
# 0xe000ed08:     0x00    0x00    0x00    0x00
# (gdb) x/1xw 0xe000ed08
# 0xe000ed08:     0x08000000

# Units
# -----
# | system                                   | flash                   | st25               |
# | bytes | power of two | halfwords | words | pages | sectors | banks | blocks | end units |
# |-------+--------------+-----------+-------+-------+---------+-------+--------+-----------|
# | 4     | 2^2          | 2         | 1     | -     | -       | -     | 1      | -         |
# | 32    | 2^5          | 16        | 8     | -     | -       | -     | 8      | 1         |
# | 128   | 2^7          | 64        | 32    | 1     | -       | -     | ^      | ^         |
# | 4096  | 2^12         | 2048      | 1024  | 32    | 1       | -     | ^      | ^         |
# | 98304 | 2^15*3       | ^         | ^     | ^     | 24      | 1     | ^      | ^         |

# Claritive Notes
# ---------------
# Say fourth bit ala bit three. Don't say third bit.
# Call 0xa as ten or a, but don't call 0x10 ten, instead one and zero.
# Last address      implies highest inclusive byte, e.g. 0x0802_ffff
# End address       implies the byte after that, e.g. 0x0803_0000 (Relevant in gdb)
# Bit is set        implies the bit is or becomes 1.
# Bit is reset      implies the bit is or becomes 0.
# Bit is cleared    implies the bit is or becomes 0.
#
# Note:
# *Some bits* can be *cleared* by *writing* a 1.
# That is to say, a bit that is 1, is made 0, by writing a 1.
#
# w/ w/o i/p        implies with, without, in-progress.
# tx                implies transmit from MCU to peripheral. The transmit and transfer are disparate terms.
# Flag, status bit  implies a read-only bit, set by hardware. Like Ready, Carry, Overflow flags.
# Tdnf=.*Ti2cclk    implies time of digital noise filter is this value it self multiplied by Ti2cclk.
#
# "Inaccuracy Saves a World Of Explanation" is the principle of each entry
# description fitting in a single line.  Where appropriate, datasheets and
# reference manuals are to be consulted for details.
# Incentive is put on recap, rather than explanation.

# Precondition notation
# ---------------------
# w!PE==0   implies, before modifying this register, PE bit must be cleared first. Like e.g. some I2C attributes can only be configured when I2C is turned off.
# w!        implies, whether you can write depends on multitude of factors.
# b!SMBHEN  implies, the behavior is ambiguous and dependent by the state of SMBHEN value.
# e!SBC==1  implies, meaningful only if the given bit is set.
#
# r    implies, software can only read
# w    implies, software can only write
# rw   implies, bit is set and cleared by software.
# rs1  implies, bit is set by software, cleared by hardware.
# rc0  implies, bit is set by hardware, cleared by software by writing 0.
# rc1  implies, bit is set by hardware, cleared by software by writing 1.
# rcr  implies, bit is cleared as side-effect of software reading it.
# rwr  implies, bit is set by hardware as side-effect of software reading it.
# rwt  implies, bit triggers an event, but won't change value, when software writes.
# mux  implies, not register, but convenience entry indirecting register values.
#ir    implies, read is interpreted by gdb script, not the actual raw value.

# Scratchpad
# ----------
# $sp         0xffff_ffff SP R13 (stack pointer register).value (r=*(VTOR+0x0)): 0x2000_5000
# $lr         0xffff_ffff LR R14 (return link register).value (address to execute after callee finished): 0
# $pc         0xffff_ffff PC R15 (program counter register).value (r=*(VTOR+0x4)): 0x0800_074a
# $xpsr       0x0000_003f xPSR IPSR (irq program status register).ENR (0 is Thread mode, else Handler mode; exception nr bitfield): 0
# $xpsr       0x0000_0200 xPSR EPSR (exec program status register).a (handler mode only; reserved, exclusive to stacked xPSR; SP 3rd bit; 8B alignment bit): 0
# $xpsr       0x0100_0000 xPSR EPSR (exec program status register).T (Thumb bit): 1
# $xpsr       0x1000_0000 xPSR APSR (app program status register).V (cond flag; 1 if signed overflow, oVerflow bit): 0
# $xpsr       0x2000_0000 xPSR APSR (app program status register).C (cond flag; 1 if unsigned over/underflow or bitshift lost bit, Carry bit): 1
# $xpsr       0x4000_0000 xPSR APSR (app program status register).Z (cond flag; 1 if result 0, Zero bit): 1
# $xpsr       0x8000_0000 xPSR APSR (app program status register).N (cond flag; 0/1 is >=0 or <0 respectively, Negative bit): 0
# $xpsr       0xf100_023f xPSR (app/irq/exec program status register).value: 6100_0000
# $xpsr       0x0000_0001 PRIMASK (priority mask register).PM (0/1 is instr "CPSIE i"/"CPSID i"; raise irq priority to zero; interrupt disable bit): 1
# $xpsr       0x0000_0001 PRIMASK (priority mask register).value: 0
# $control    0x0000_0002 CONTROL (control register).SPSEL (thread mode only; 1/0 PSP/MSP stack pointer mode bit): 0
# $control    0x0000_0001 CONTROL (control register).nPRIV (thread mode only; 1/0 is un/privileged mode bit): 0
# $control    0x0000_0003 CONTROL (control register).value (r=0x0): 0
#
# MSP (R13; main stack pointer)
# PSP (R13; process stack pointer)
# LR (R14; link register).value (holds return info for fn calls, subroutines, exceptions): 0x800096b
# PC (R15; program counter).value: 0x8001dbe
#
# Reset types
# ===========
# Power Reset: |
#   Names:
#     POR: Power-On Reset
#     PDR: Power-Down Reset
#     BOR: Brown-Out Reset
# System Reset: |
#   Issued by:
#     (gdb) monit reset 2. Via Software.
#     Power Reset. Via Hardware.
#     nRST pin asserted high, then low. Via Hardware.
# RTC Reset: |
#   Issued by: |
#     RCC_CSR.RTCRST reset bit. Via Software.
#     Power Reset. Via Hardware.
#   Resets:
#   - RCC_CSR .LSEON .LSERDY .LSEBYP .LSEDRV .CSSLSEON .CSSLSED .RTCSEL .RTCEN

define portdesc
	set $MODE = $arg2 >> 2*$arg1 &0x3
	set $OTYPE = $arg3 >> $arg1 & 0x1
	set $OSPEED = $arg4 >> 2*$arg1 & 0x3
	set $PUPD = $arg5 >> 2*$arg1 & 0x3
	set $ID = $arg6 >> $arg1 & 0x1
	set $OD = $arg7 >> $arg1 & 0x1
	set $LCK = $arg8 >> $arg1 & 0x1
if $arg1 < 8
	set $AF = $arg9 >> 4*$arg1 & 0xf
else
	set $AF = $arg10 >> 4*($arg1-8) & 0xf
end
	set $PORT = $arg11
	set $NR = $arg1

printf $arg0

if $MODE == 0
	printf "0/i       "
end
if $MODE == 1
	printf "0/gpo     "
end
if $MODE == 2
	printf "2/af      "
end
if $MODE == 3
	printf "3/analog  "
end

if $OTYPE == 0
	printf "0/push-pull   "
end
if $OTYPE == 1
	printf "1/open-drain  "
end


if $OSPEED == 0
	printf "0/low        "
end
if $OSPEED == 1
	printf "1/medium     "
end
if $OSPEED == 2
	printf "2/high       "
end
if $OSPEED == 3
	printf "3/very high  "
end

if $PUPD == 0
	printf "0/none      "
end
if $PUPD == 1
	printf "1/pullup    "
end
if $PUPD == 2
	printf "2/pulldown  "
end
if $PUPD == 3
	printf "3/res       "
end

printf "%x/input  ", $ID
printf "%x/output  ", $OD

if $LCK == 0
	printf "0/unlocked  "
else
	printf "1/locked    "
end

printf "%x/af ", $AF

if $MODE == 2 && $PORT == 'A' && $NR == 5 && $AF == 0
printf "SPI1_SCK    "
end
if $MODE == 2 && $PORT == 'A' && $NR == 6 && $AF == 0
printf "SPI1_MISO   "
end
if $MODE == 2 && $PORT == 'A' && $NR == 7 && $AF == 0
printf "SPI1_MOSI   "
end
if $MODE == 2 && $PORT == 'A' && $NR == 13 && $AF == 0
printf "SWDIO       "
end
if $MODE == 2 && $PORT == 'A' && $NR == 14 && $AF == 0
printf "SWDCLK      "
end
if $MODE == 2 && $PORT == 'B' && $NR == 6 && $AF == 1
printf "I2C1_SCL    "
end
if $MODE == 2 && $PORT == 'B' && $NR == 6 && $AF == 2
printf "LPTIM1_ETR  "
end
if $MODE == 2 && $PORT == 'B' && $NR == 7 && $AF == 1
printf "I2C1_SDA    "
end
if $MODE != 2
printf "            "
end

printf $arg12


printf "\n"

end

define reglist
	set $OFLASH_OPTR_LSH = (unsigned int) *0x1ff80000
	set $OFLASH_OPTR_MSH = (unsigned int) *0x1ff80004
	set $OFLASH_WRPROT1_LSH = (unsigned int) *0x1ff80008
	set $OFLASH_WRPROT1_MSH = (unsigned int) *0x1ff8000c
	set $OFLASH_WRPROT2_LSH = (unsigned int) *0x1ff80010

	set $FLASH_ACR = (unsigned int) *0x40022000
	set $FLASH_PECR = (unsigned int) *0x40022004
	set $FLASH_SR = (unsigned int) *0x40022018
	set $FLASH_OPTR = (unsigned int) *0x4002201c
	set $FLASH_WRPROT1 = (unsigned int) *0x40022020
	set $FLASH_WRPROT2 = (unsigned int) *0x40022080

	set $RTC_TR = (unsigned int) *0x40002800
	set $RTC_DR = (unsigned int) *0x40002804
	set $RTC_CR = (unsigned int) *0x40002808
	set $RTC_ISR = (unsigned int) *0x4000280c
	set $RTC_PRER = (unsigned int) *0x40002810
	set $RTC_WUTR = (unsigned int) *0x40002814
	set $RTC_ALRMAR = (unsigned int) *0x4000281c
	set $RTC_ALRMBR = (unsigned int) *0x40002820
	set $RTC_SSR = (unsigned int) *0x40002828
	set $RTC_TSTR = (unsigned int) *0x40002830
	set $RTC_TSDR = (unsigned int) *0x40002834
	set $RTC_TSSSR = (unsigned int) *0x40002838
	set $RTC_CALR = (unsigned int) *0x4000283c
	set $RTC_TAMPCR = (unsigned int) *0x40002840
	set $RTC_ALRMASSR = (unsigned int) *0x40002844
	set $RTC_ALRMBSSR = (unsigned int) *0x40002848
	set $RTC_OR = (unsigned int) *0x4000284c
	set $RTC_BKP0R = (unsigned int) *0x40002850
	set $RTC_BKP1R = (unsigned int) *0x40002854
	set $RTC_BKP2R = (unsigned int) *0x40002858
	set $RTC_BKP3R = (unsigned int) *0x4000285c
	set $RTC_BKP4R = (unsigned int) *0x40002860

	set $I2C_CR1 = (unsigned int) *0x40005400
	set $I2C_CR2 = (unsigned int) *0x40005404
	set $I2C_OAR1 = (unsigned int) *0x40005408
	set $I2C_OAR2 = (unsigned int) *0x4000540c
	set $I2C_TIMINGR = (unsigned int) *0x40005410
	set $I2C_TIMEOUTR = (unsigned int) *0x40005414
	set $I2C_ISR = (unsigned int) *0x40005418
	set $I2C_PECR = (unsigned int) *0x40005420
	set $I2C_RXDR = (unsigned int) *0x40005424
	set $I2C_TXDR = (unsigned int) *0x40005428

	set $PWR_CR = (unsigned int) *0x40007000
	set $PWR_CSR = (unsigned int) *0x40007004

	set $LPTIM_ISR = (unsigned int) *0x40007c00
	set $LPTIM_IER = (unsigned int) *0x40007c08
	set $LPTIM_CFGR = (unsigned int) *0x40007c0c
	set $LPTIM_CR = (unsigned int) *0x40007c10
	set $LPTIM_CMP = (unsigned int) *0x40007c14
	set $LPTIM_ARR = (unsigned int) *0x40007c18
	set $LPTIM_CNT = (unsigned int) *0x40007c1c
	set $SYSCFG_CFGR1 = (unsigned int) *0x40010000
	set $SYSCFG_CFGR2 = (unsigned int) *0x40010004
	set $SYSCFG_EXTICR1 = (unsigned int) *0x40010008
	set $SYSCFG_EXTICR2 = (unsigned int) *0x4001000c
	set $SYSCFG_EXTICR3 = (unsigned int) *0x40010010
	set $SYSCFG_EXTICR4 = (unsigned int) *0x40010014
	set $SYSCFG_CFGR3 = (unsigned int) *0x40010020

	set $EXTI_IMR = (unsigned int) *0x40010400
	set $EXTI_EMR = (unsigned int) *0x40010404
	set $EXTI_RTSR = (unsigned int) *0x40010408
	set $EXTI_FTSR = (unsigned int) *0x4001040c
	set $EXTI_SWIER = (unsigned int) *0x40010410
	set $EXTI_PR = (unsigned int) *0x40010414

	set $RCC_CR = (unsigned int) *0x40021000
	set $RCC_ICSCR = (unsigned int) *0x40021004
	set $RCC_CFGR = (unsigned int) *0x4002100c
	set $RCC_CIER = (unsigned int) *0x40021010
	set $RCC_CIFR = (unsigned int) *0x40021014
	set $RCC_IOPRSTR = (unsigned int) *0x4002101c
	set $RCC_AHBRSTR = (unsigned int) *0x40021020
	set $RCC_APB2RSTR = (unsigned int) *0x40021024
	set $RCC_APB1RSTR = (unsigned int) *0x40021028
	set $RCC_IOPENR = (unsigned int) *0x4002102c
	set $RCC_AHBENR = (unsigned int) *0x40021030
	set $RCC_APB2ENR = (unsigned int) *0x40021034
	set $RCC_APB1ENR = (unsigned int) *0x40021038
	set $RCC_IOPSMEN = (unsigned int) *0x4002103c
	set $RCC_AHBSMENR = (unsigned int) *0x40021040
	set $RCC_APB2SMENR = (unsigned int) *0x40021044
	set $RCC_APB1SMENR = (unsigned int) *0x40021048
	set $RCC_CCIPR = (unsigned int) *0x4002104c
	set $RCC_CSR = (unsigned int) *0x40021050

	set $FLASH_ACR = (unsigned int) *0x40022000
	set $FLASH_PECR = (unsigned int) *0x40022004
	set $FLASH_SR = (unsigned int) *0x40022018
	set $FLASH_OPTR = (unsigned int) *0x4002201c
	set $FLASH_WRPROT1 = (unsigned int) *0x40022020
	set $FLASH_WRPROT2 = (unsigned int) *0x40022080

	set $GPIOA_MODER = (unsigned int) *0x50000000
	set $GPIOA_OTYPER = (unsigned int) *0x50000004
	set $GPIOA_OSPEEDR = (unsigned int) *0x50000008
	set $GPIOA_PUPDR = (unsigned int) *0x5000000c
	set $GPIOA_IDR = (unsigned int) *0x50000010
	set $GPIOA_ODR = (unsigned int) *0x50000014
	set $GPIOA_LCKR = (unsigned int) *0x5000001c
	set $GPIOA_AFRL = (unsigned int) *0x50000020
	set $GPIOA_AFRH = (unsigned int) *0x50000024

	set $GPIOB_MODER = (unsigned int) *0x50000400
	set $GPIOB_OTYPER = (unsigned int) *0x50000404
	set $GPIOB_OSPEEDR = (unsigned int) *0x50000408
	set $GPIOB_PUPDR = (unsigned int) *0x5000040c
	set $GPIOB_IDR = (unsigned int) *0x50000410
	set $GPIOB_ODR = (unsigned int) *0x50000414
	set $GPIOB_LCKR = (unsigned int) *0x5000041c
	set $GPIOB_AFRL = (unsigned int) *0x50000420
	set $GPIOB_AFRH = (unsigned int) *0x50000424

	set $GPIOC_MODER = (unsigned int) *0x50000800
	set $GPIOC_OTYPER = (unsigned int) *0x50000804
	set $GPIOC_OSPEEDR = (unsigned int) *0x50000808
	set $GPIOC_PUPDR = (unsigned int) *0x5000080c
	set $GPIOC_IDR = (unsigned int) *0x50000810
	set $GPIOC_ODR = (unsigned int) *0x50000814
	set $GPIOC_LCKR = (unsigned int) *0x5000081c
	set $GPIOC_AFRL = (unsigned int) *0x50000820
	set $GPIOC_AFRH = (unsigned int) *0x50000824

	set $GPIOD_MODER = (unsigned int) *0x50000c00
	set $GPIOD_OTYPER = (unsigned int) *0x50000c04
	set $GPIOD_OSPEEDR = (unsigned int) *0x50000c08
	set $GPIOD_PUPDR = (unsigned int) *0x50000c0c
	set $GPIOD_IDR = (unsigned int) *0x50000c10
	set $GPIOD_ODR = (unsigned int) *0x50000c14
	set $GPIOD_LCKR = (unsigned int) *0x50000c1c
	set $GPIOD_AFRL = (unsigned int) *0x50000c20
	set $GPIOD_AFRH = (unsigned int) *0x50000c24

	set $GPIOE_MODER = (unsigned int) *0x50001000
	set $GPIOE_OTYPER = (unsigned int) *0x50001004
	set $GPIOE_OSPEEDR = (unsigned int) *0x50001008
	set $GPIOE_PUPDR = (unsigned int) *0x5000100c
	set $GPIOE_IDR = (unsigned int) *0x50001010
	set $GPIOE_ODR = (unsigned int) *0x50001014
	set $GPIOE_LCKR = (unsigned int) *0x5000101c
	set $GPIOE_AFRL = (unsigned int) *0x50001020
	set $GPIOE_AFRH = (unsigned int) *0x50001024

	set $GPIOH_MODER = (unsigned int) *0x50001c00
	set $GPIOH_OTYPER = (unsigned int) *0x50001c04
	set $GPIOH_OSPEEDR = (unsigned int) *0x50001c08
	set $GPIOH_PUPDR = (unsigned int) *0x50001c0c
	set $GPIOH_IDR = (unsigned int) *0x50001c10
	set $GPIOH_ODR = (unsigned int) *0x50001c14
	set $GPIOH_LCKR = (unsigned int) *0x50001c1c
	set $GPIOH_AFRL = (unsigned int) *0x50001c20
	set $GPIOH_AFRH = (unsigned int) *0x50001c24

	set $NVIC_IP0_3 = (unsigned int) *0xe000e400
	set $NVIC_IP4_7 = (unsigned int) *0xe000e404
	set $NVIC_IP8_11 = (unsigned int) *0xe000e408
	set $NVIC_IP12_15 = (unsigned int) *0xe000e40c
	set $NVIC_IP16_19 = (unsigned int) *0xe000e410
	set $NVIC_IP20_23 = (unsigned int) *0xe000e414
	set $NVIC_IP24_27 = (unsigned int) *0xe000e418
	set $NVIC_IP28_29 = (unsigned int) *0xe000e41c

	set $SCB_VTOR = (unsigned int) *0xe000ed08

	set $ST25DV_SYS_MB_MODE = (unsigned char) 0x00
	set $ST25DV_SYS_MB_WDG = (unsigned char) 0x00
	set $ST25DV_DYN_MB_CTRL = (unsigned char) 0x00

	set $SFH7776_SYSTEM_CONTROL = (unsigned int)0
	set $SFH7776_MODE_CONTROL = (unsigned int)0
	set $SFH7776_ALS_PS_CONTROL = (unsigned int)0
	set $SFH7776_PERSISTENCE = (unsigned int)0
	set $SFH7776_PS_DATA = (unsigned int)0
	set $SFH7776_ALS_VIS_DATA = (unsigned int)0
	set $SFH7776_ALS_IR_DATA = (unsigned int)0
	set $SFH7776_INTERRUPT_CONTROL = (unsigned int)0
	set $SFH7776_PS_TH = (unsigned int)0
	set $SFH7776_PS_TL = (unsigned int)0
	set $SFH7776_ALS_VIS_TH = (unsigned int)0
	set $SFH7776_ALS_VIS_TL = (unsigned int)0

	set $HDC2080_TEMP = (unsigned int)0
	set $HDC2080_HUMID = (unsigned int)0
	set $HDC2080_STATUS = (unsigned int)0
	set $HDC2080_MAX_TEMP = (unsigned int)0
	set $HDC2080_MAX_HUMID = (unsigned int)0
	set $HDC2080_CONFIG_INT_EN = (unsigned int)0
	set $HDC2080_OFFSET_TEMP = (unsigned int)0
	set $HDC2080_OFFSET_HUMID = (unsigned int)0
	set $HDC2080_THRES_TEMP_LOW = (unsigned int)0
	set $HDC2080_THRES_TEMP_HIGH = (unsigned int)0
	set $HDC2080_THRES_HUMID_LOW = (unsigned int)0
	set $HDC2080_THRES_HUMID_HIGH = (unsigned int)0
	set $HDC2080_CONFIG = (unsigned int)0
	set $HDC2080_MEASURE = (unsigned int)0
	set $HDC2080_ID_MANUFACTURER = (unsigned int)0
	set $HDC2080_ID_DEVICE = (unsigned int)0

	set $BMA400_CHIPID = (unsigned int)0
	set $BMA400_ERR_REG = (unsigned int)0
	set $BMA400_STATUS = (unsigned int)0
	set $BMA400_ACC_X = (unsigned int)0
	set $BMA400_ACC_Y = (unsigned int)0
	set $BMA400_ACC_Z = (unsigned int)0
	set $BMA400_SENSOR_TIME = (unsigned int)0
	set $BMA400_EVENT = (unsigned int)0
	set $BMA400_INT_STAT = (unsigned int)0
	set $BMA400_TEMP_DATA = (unsigned int)0
	set $BMA400_FIFO_LENGTH = (unsigned int)0
	set $BMA400_FIFO_DATA = (unsigned int)0
	set $BMA400_STEP_CNT = (unsigned int)0
	set $BMA400_STEP_STAT = (unsigned int)0
	set $BMA400_ACC_CONFIG = (unsigned int)0

	set $BMA400_INT_CONFIG = (unsigned int)0
	set $BMA400_INT1_MAP = (unsigned int)0
	set $BMA400_INT2_MAP = (unsigned int)0
	set $BMA400_INT12_MAP = (unsigned int)0
	set $BMA400_INT12_IO_CTRL = (unsigned int)0

	set $BMA400_FIFO_CONFIG = (unsigned int)0
	set $BMA400_FIFO_PWR_CONFIG = (unsigned int)0
	set $BMA400_AUTOLOWPOW = (unsigned int)0
	set $BMA400_AUTOWAKEUP = (unsigned int)0

	set $BMA400_WKUP_INT_CONFIG0 = (unsigned int)0
	set $BMA400_WKUP_INT_CONFIG1 = (unsigned int)0
	set $BMA400_WKUP_INT_CONFIG2 = (unsigned int)0
	set $BMA400_WKUP_INT_CONFIG3 = (unsigned int)0
	set $BMA400_WKUP_INT_CONFIG4 = (unsigned int)0

	set $BMA400_ORIENTCH_CONFIG0 = (unsigned int)0
	set $BMA400_ORIENTCH_CONFIG1 = (unsigned int)0
	set $BMA400_ORIENTCH_CONFIG3 = (unsigned int)0
	set $BMA400_ORIENTCH_CONFIG4_5 = (unsigned int)0
	set $BMA400_ORIENTCH_CONFIG6_7 = (unsigned int)0
	set $BMA400_ORIENTCH_CONFIG8_9 = (unsigned int)0
	set $BMA400_GEN1INT_CONFIG0 = (unsigned int)0
	set $BMA400_GEN1INT_CONFIG1 = (unsigned int)0
	set $BMA400_GEN1INT_CONFIG2 = (unsigned int)0
	set $BMA400_GEN1INT_CONFIG3 = (unsigned int)0
	set $BMA400_GEN1INT_CONFIG4_5 = (unsigned int)0
	set $BMA400_GEN1INT_CONFIG6_7 = (unsigned int)0
	set $BMA400_GEN1INT_CONFIG8_9 = (unsigned int)0

	set $BMA400_GEN2INT_CONFIG0 = (unsigned int)0
	set $BMA400_GEN2INT_CONFIG1 = (unsigned int)0
	set $BMA400_GEN2INT_CONFIG2 = (unsigned int)0
	set $BMA400_GEN2INT_CONFIG3 = (unsigned int)0
	set $BMA400_GEN2INT_CONFIG4_5 = (unsigned int)0
	set $BMA400_GEN2INT_CONFIG6_7 = (unsigned int)0
	set $BMA400_GEN2INT_CONFIG8_9 = (unsigned int)0

	set $BMA400_ACTCH_CONFIG = (unsigned int)0
	set $BMA400_TAP_CONFIG = (unsigned int)0
	set $BMA400_TAP_CONFIG1 = (unsigned int)0

	set $BMA400_IF_CONF = (unsigned int)0
	set $BMA400_SELF_TEST = (unsigned int)0
	set $BMA400_CMD = (unsigned int)0

	printf "addr        bitmask     |Type| REGNAME (register description).BITNAME (bits description).value: actual value\n"
	printf "------------------------+----+------------------------------------------------------------------------------\n"

	printf "0x1ff8_0000 0xffff_ffff | rw | OFLASH_OPTR_LSH (~FLASH_OPTR[15..0] then FLASH_OPTR[15..0] option bytes nvm).value: 0x%04x_%04x\n", $OFLASH_OPTR_LSH>>16&0xFFFF, $OFLASH_OPTR_LSH&0xFFFF
	printf "0x1ff8_0004 0xffff_ffff | rw | OFLASH_OPTR_MSH (~FLASH_OPTR[31..16] then FLASH_OPTR[31..16] option bytes nvm).value: 0x%04x_%04x\n", $OFLASH_OPTR_MSH>>16&0xFFFF, $OFLASH_OPTR_MSH&0xFFFF
	printf "0x1ff8_0008 0xffff_ffff | rw | OFLASH_WRPROT1_LSH (~FLASH_WRPROT1[15..0] then FLASH_WRPROT1[15..0] option bytes nvm).value: 0x%04x_%04x\n", $OFLASH_WRPROT1_LSH>>16&0xFFFF, $OFLASH_WRPROT1_LSH&0xFFFF
	printf "0x1ff8_000c 0xffff_ffff | rw | OFLASH_WRPROT1_MSH (~FLASH_WRPROT1[31..16] then FLASH_WRPROT1[31..16] option bytes nvm).value: 0x%04x_%04x\n", $OFLASH_WRPROT1_MSH>>16&0xFFFF, $OFLASH_WRPROT1_MSH&0xFFFF
	printf "0x1ff8_0010 0xffff_ffff | rw | OFLASH_WRPROT2_LSH (~FLASH_WRPROT1[15..0] then FLASH_WRPROT2[15..0] option bytes nvm).value: 0x%04x_%04x\n", $OFLASH_WRPROT2_LSH>>16&0xFFFF, $OFLASH_WRPROT2_LSH&0xFFFF

	printf "0x4000_2800 0x0000_000f | rw | RTC_TR (time shadow register).SU (second units BCD value bits): %x\n", $RTC_TR&0xF
	printf "0x4000_2800 0x0000_0070 | rw | RTC_TR (time shadow register).ST (second tens BCD value bits): %x\n", $RTC_TR>>4&0x7
	printf "0x4000_2800 0x0000_0f00 | rw | RTC_TR (time shadow register).MNU (minute units BCD value bits): %x\n", $RTC_TR>>8&0xF
	printf "0x4000_2800 0x0000_7000 | rw | RTC_TR (time shadow register).MNT (minute tens BCD value bits): %x\n", $RTC_TR>>12&0x7
	printf "0x4000_2800 0x000f_0000 | rw | RTC_TR (time shadow register).HU (hour units BCD value bits): %x\n", $RTC_TR>>16&0xF
	printf "0x4000_2800 0x0030_0000 | rw | RTC_TR (time shadow register).HT (hour tens BCD value bits): %x\n", $RTC_TR>>20&0x3
	printf "0x4000_2800 0x0040_0000 | rw | RTC_TR (time shadow register).PM (am or 24h/0 or pm/1 notation bit): %x\n", $RTC_TR>>22&0x1
	printf "0x4000_2800 0x007f_7f7f | rw | RTC_TR (time shadow register).value (w!INITF==1; r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_TR>>16&0xFFFF, $RTC_TR&0xFFFF

	printf "0x4000_2804 0x0000_000f | rw | RTC_DR (date shadow register).DU (date units BCD value bits): %x\n", $RTC_DR&0xF
	printf "0x4000_2804 0x0000_0030 | rw | RTC_DR (date shadow register).DT (date tens BCD value bits): %x\n", $RTC_DR>>4&0x3
	printf "0x4000_2804 0x0000_0f00 | rw | RTC_DR (date shadow register).MU (months units BCD value bits): %x\n", $RTC_DR>>8&0xF
	printf "0x4000_2804 0x0000_1000 | rw | RTC_DR (date shadow register).MT (months tens BCD value bits): %x\n", $RTC_DR>>12&0x1
	printf "0x4000_2804 0x0000_e000 | rw | RTC_DR (date shadow register).WDU (1/mon 2/tue 3/wed 4/thu 5/fri 6/sat 7/sun; week day units bits): %x\n", $RTC_DR>>13&0x7
	printf "0x4000_2804 0x000f_0000 | rw | RTC_DR (date shadow register).YU (year units BCD value bits): %x\n", $RTC_DR>>16&0xF
	printf "0x4000_2804 0x00f0_0000 | rw | RTC_DR (date shadow register).YT (year tens BCD value bits): %x\n", $RTC_DR>>20&0xF
	printf "0x4000_2804 0x00ff_ff3f | rw | RTC_DR (date shadow register).value (w!INITF==1; r=not_affected rtc=0x0000_2101): 0x%04x_%04x\n", $RTC_DR>>16&0xFFFF, $RTC_DR&0xFFFF

	printf "0x4000_2808 0x0000_0007 | rw | RTC_CR (control register).WUCKSEL (w!WUTE==0 w!WUTWF==1; rtc div by 16,8,4,2/0..3 or 1hz/4,5 or 1hz+18h to WUT/6,7; wakeup clock select bits): %x\n", $RTC_CR&0x7
	printf "0x4000_2808 0x0000_0008 | rw | RTC_CR (control register).TSEDGE (w!TSE==0; RTC_TS input rise/0 fall/1 edge generates timestamp event TSF bit): %x\n", $RTC_CR>>3&0x1
	printf "0x4000_2808 0x0000_0010 | rw | RTC_CR (control register).REFCKON (w!INITF==1 w!PREDIV_S==0xFF; RTC_REFIN input ref clock detect enable bit): %x\n", $RTC_CR>>4&0x1
	printf "0x4000_2808 0x0000_0020 | rw | RTC_CR (control register).BYPSHAD (shadows update each 2*rtcclk; must enable if apb1<7*rtc Hz; bypass shadow registers enable bit): %x\n", $RTC_CR>>5&0x1
	printf "0x4000_2808 0x0000_0040 | rw | RTC_CR (control register).FMT (w!INITF==1; 24hr/0 am,pm/1 hour format bit): %x\n", $RTC_CR>>6&0x1
	printf "0x4000_2808 0x0000_0100 | rw | RTC_CR (control register).ALRAE (alarm A enable bit): %x\n", $RTC_CR>>8&0x1
	printf "0x4000_2808 0x0000_0200 | rw | RTC_CR (control register).ALRAE (alarm B enable bit): %x\n", $RTC_CR>>9&0x1
	printf "0x4000_2808 0x0000_0400 | rw | RTC_CR (control register).WUTE (wakeup timer enable bit): %x\n", $RTC_CR>>10&0x1
	printf "0x4000_2808 0x0000_0800 | rw | RTC_CR (control register).TSE (timestamp enable bit): %x\n", $RTC_CR>>11&0x1
	printf "0x4000_2808 0x0000_1000 | rw | RTC_CR (control register).ALRAIE (alarm A interrupt enable bit): %x\n", $RTC_CR>>12&0x1
	printf "0x4000_2808 0x0000_2000 | rw | RTC_CR (control register).ALRBIE (alarm B interrupt enable bit): %x\n", $RTC_CR>>13&0x1
	printf "0x4000_2808 0x0000_4000 | rw | RTC_CR (control register).WUTIE (wakeup timer interrupt enable bit): %x\n", $RTC_CR>>14&0x1
	printf "0x4000_2808 0x0000_8000 | rw | RTC_CR (control register).TSIE (timestamp interrupt enable): %x\n", $RTC_CR>>15&0x1
	printf "0x4000_2808 0x0001_0000 |  w | RTC_CR (control register).ADD1H (summer time change without INIT mode; inc 1 hour on next second bit): N/A\n"
	printf "0x4000_2808 0x0002_0000 |  w | RTC_CR (control register).SUB1H (winter time change without INIT mode; dec 1 hour on next second bit): N/A\n"
	printf "0x4000_2808 0x0004_0000 | rw | RTC_CR (control register).BKP (does nothing, user may use to memorize whether DST was performed; backup bit): %x\n", $RTC_CR>>18&0x1
	printf "0x4000_2808 0x0008_0000 | rw | RTC_CR (control register).COSEL (512Hz/0 1Hz/1 w/ default prescaler setting; RTC_CALIB output select bit): %x\n", $RTC_CR>>19&0x1
	printf "0x4000_2808 0x0010_0000 | rw | RTC_CR (control register).POL (high/0 low/1 when ALRAF,ALRBF,WUTF are set; RTC_ALARM output polarity bit): %x\n", $RTC_CR>>20&0x1
	printf "0x4000_2808 0x0060_0000 | rw | RTC_CR (control register).OSEL (none/0 alarmA/1 alarmB/2 wakeup/3; RTC_ALARM output select bit): %x\n", $RTC_CR>>22&0x1
	printf "0x4000_2808 0x0080_0000 | rw | RTC_CR (control register).COE (RTC_CALIB output enable bit): %x\n", $RTC_CR>>23&0x1
	printf "0x4000_2808 0x00f7_ff7f | rw | RTC_CR (control register).value (r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_CR>>16&0xFFFF, $RTC_CR&0xFFFF

	printf "0x4000_280c 0x0000_0001 | r  | RTC_ISR (initialization and status register).ALRAWF (ALRAE==0; alarm A write allowed flag): %x\n", $RTC_ISR&0x1
	printf "0x4000_280c 0x0000_0002 | r  | RTC_ISR (initialization and status register).ALRBWF (ALRBE==0; alarm B write allowed flag): %x\n", $RTC_ISR>>1&0x1
	printf "0x4000_280c 0x0000_0004 | r  | RTC_ISR (initialization and status register).WUTWF (WUTE==0; delay of 2*rtcclk; wakeup timer write allowed flag): %x\n", $RTC_ISR>>2&0x1
	printf "0x4000_280c 0x0000_0008 | r  | RTC_ISR (initialization and status register).SHPF (shift operation pending flag): %x\n", $RTC_ISR>>3&0x1
	printf "0x4000_280c 0x0000_0010 | r  | RTC_ISR (initialization and status register).INITS (calendar date/time is initialized flag): %x\n", $RTC_ISR>>4&0x1
	printf "0x4000_280c 0x0000_0020 | rc0| RTC_ISR (initialization and status register).RSF (e!BYPSHAD==0&SHPF==0&INITF==0; hw synced shadow registers flag): %x\n", $RTC_ISR>>5&0x1
	printf "0x4000_280c 0x0000_0040 | r  | RTC_ISR (initialization and status register).INITF (RTC initialization mode active flag): %x\n", $RTC_ISR>>6&0x1
	printf "0x4000_280c 0x0000_0080 | rw | RTC_ISR (initialization and status register).INIT (stop counters and allow register writes; init mode enable bit): %x\n", $RTC_ISR>>7&0x1
	printf "0x4000_280c 0x0000_0100 | rc0| RTC_ISR (initialization and status register).ALRAF (hw0 after 2*apb1clk; RTC_TR RTC_DR match RTC_ALRMAR flag): %x\n", $RTC_ISR>>8&0x1
	printf "0x4000_280c 0x0000_0200 | rc0| RTC_ISR (initialization and status register).ALRBF (hw0 after 2*apb1clk; RTC_TR RTC_DR match RTC_ALRMBR flag): %x\n", $RTC_ISR>>9&0x1
	printf "0x4000_280c 0x0000_0400 | rc0| RTC_ISR (initialization and status register).WUTF (hw0 after 2*apb1clk; WUT downcounter reached 0 flag): %x\n", $RTC_ISR>>10&0x1
	printf "0x4000_280c 0x0000_0800 | rc0| RTC_ISR (initialization and status register).TSF (hw0 after 2*apb1clk; timestamp event flag): %x\n", $RTC_ISR>>11&0x1
	printf "0x4000_280c 0x0000_1000 | rc0| RTC_ISR (initialization and status register).TSOVF (TSF happened while TSF already set; timestamp overflow flag): %x\n", $RTC_ISR>>12&0x1
	printf "0x4000_280c 0x0000_2000 | rc0| RTC_ISR (initialization and status register).TAMP1F (RTC_TAMP1 detection event flag): %x\n", $RTC_ISR>>13&0x1
	printf "0x4000_280c 0x0000_4000 | rc0| RTC_ISR (initialization and status register).TAMP2F (RTC_TAMP2 detection event flag): %x\n", $RTC_ISR>>14&0x1
	printf "0x4000_280c 0x0000_8000 | rc0| RTC_ISR (initialization and status register).TAMP3F (RTC_TAMP3 detection event flag): %x\n", $RTC_ISR>>15&0x1
	printf "0x4000_280c 0x0001_0000 | r  | RTC_ISR (initialization and status register).RECALPF (when sw wrote to RTC_CALR; recalibration pending flag): %x\n", $RTC_ISR>>16&0x1
	printf "0x4000_280c 0x0001_7fff | rw | RTC_ISR (initialization and status register).value (r=INIT,INITF,RSF=0,N/A rtc=0x0000_0007): 0x%04x_%04x\n", $RTC_ISR>>16&0xFFFF, $RTC_ISR&0xFFFF

	printf "0x4000_2810 0x0000_7fff | rw | RTC_PRER (prescaler register).PREDIV_S (ck_spre=ck_apre/(.+1); synchronous prescaler factor bits): 0x%04x\n", $RTC_PRER&0x7FFF
	printf "0x4000_2810 0x007f_0000 | rw | RTC_PRER (prescaler register).PREDIV_A (ck_apre=rtcfreq/(.+1); asynchronous prescaler factor bits): 0x%04x\n", $RTC_PRER>>16&0x7F
	printf "0x4000_2810 0x007f_7fff | rw | RTC_PRER (prescaler register).value (r=not_affected rtc=0x007f_00ff): 0x%04x_%04x\n", $RTC_PRER>>16&0xFFFF, $RTC_PRER&0xFFFF

	printf "0x4000_2814 0x0000_ffff | rw | RTC_WUTR (wakeup timer register).WUT (wakeup downcounter autoreload value bits): 0x%04x\n", $RTC_WUTR&0xFFFF
	printf "0x4000_2814 0x0000_ffff | rw | RTC_WUTR (wakeup timer register).value (r=not_affected rtc=0x0000_ffff): 0x%04x_%04x\n", $RTC_WUTR>>16&0xFFFF, $RTC_WUTR&0xFFFF

	printf "0x4000_281c 0x0000_000f | rw | RTC_ALRMAR (alarm A register).SU (second units BCD value bits): %x\n", $RTC_ALRMAR&0xF
	printf "0x4000_281c 0x0000_0070 | rw | RTC_ALRMAR (alarm A register).ST (second tens BCD value bits): %x\n", $RTC_ALRMAR>>4&0x7
	printf "0x4000_281c 0x0000_0080 | rw | RTC_ALRMAR (alarm A register).MSK1 (seconds match/0 dont care/1 compare mask bit): %x\n", $RTC_ALRMAR>>7&0x1
	printf "0x4000_281c 0x0000_0f00 | rw | RTC_ALRMAR (alarm A register).MNU (minute units BCD value bits): %x\n", $RTC_ALRMAR>>8&0xF
	printf "0x4000_281c 0x0000_7000 | rw | RTC_ALRMAR (alarm A register).MNT (minute tens BCD value bits): %x\n", $RTC_ALRMAR>>12&0x7
	printf "0x4000_281c 0x0000_8000 | rw | RTC_ALRMAR (alarm A register).MSK2 (minutes match/0 dont care/1 compare mask bit): %x\n", $RTC_ALRMAR>>15&0x1
	printf "0x4000_281c 0x000f_0000 | rw | RTC_ALRMAR (alarm A register).HU (hour units BCD value bits): %x\n", $RTC_ALRMAR>>16&0xF
	printf "0x4000_281c 0x0030_0000 | rw | RTC_ALRMAR (alarm A register).HT (hour tens BCD value bits): %x\n", $RTC_ALRMAR>>20&0x3
	printf "0x4000_281c 0x0040_0000 | rw | RTC_ALRMAR (alarm A register).PM (am or 24h/0 or pm/1 notation bit): %x\n", $RTC_ALRMAR>>22&0x1
	printf "0x4000_281c 0x0080_8000 | rw | RTC_ALRMAR (alarm A register).MSK3 (hour match/0 dont care/1 compare mask bit): %x\n", $RTC_ALRMAR>>23&0x1
	printf "0x4000_281c 0x0f00_0000 | rw | RTC_ALRMAR (alarm A register).DU (date units BCD value bits): %x\n", $RTC_ALRMAR>>24&0xF
	printf "0x4000_281c 0x3000_0000 | rw | RTC_ALRMAR (alarm A register).DT (date tens BCD value bits): %x\n", $RTC_ALRMAR>>28&0x3
	printf "0x4000_281c 0x4000_0000 | rw | RTC_ALRMAR (alarm A register).WDSEL (DU represents day of month/0 week/1; date select mode bit): %x\n", $RTC_ALRMAR>>30&0x1
	printf "0x4000_281c 0x8000_0000 | rw | RTC_ALRMAR (alarm A register).MSK4 (date match/0 dont care/1 compare mask bit): %x\n", $RTC_ALRMAR>>31&0x1
	printf "0x4000_281c 0xffff_ffff | rw | RTC_ALRMAR (alarm A register).value (r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_ALRMAR>>16&0xFFFF, $RTC_ALRMAR&0xFFFF

	printf "0x4000_2820 0x0000_000f | rw | RTC_ALRMBR (alarm B register).SU (second units BCD value bits): %x\n", $RTC_ALRMBR&0xF
	printf "0x4000_2820 0x0000_0070 | rw | RTC_ALRMBR (alarm B register).ST (second tens BCD value bits): %x\n", $RTC_ALRMBR>>4&0x7
	printf "0x4000_2820 0x0000_0080 | rw | RTC_ALRMBR (alarm B register).MSK1 (seconds match/0 dont care/1 compare mask bit): %x\n", $RTC_ALRMBR>>7&0x1
	printf "0x4000_2820 0x0000_0f00 | rw | RTC_ALRMBR (alarm B register).MNU (minute units BCD value bits): %x\n", $RTC_ALRMBR>>8&0xF
	printf "0x4000_2820 0x0000_7000 | rw | RTC_ALRMBR (alarm B register).MNT (minute tens BCD value bits): %x\n", $RTC_ALRMBR>>12&0x7
	printf "0x4000_2820 0x0000_8000 | rw | RTC_ALRMBR (alarm B register).MSK2 (minutes match/0 dont care/1 compare mask bit): %x\n", $RTC_ALRMBR>>15&0x1
	printf "0x4000_2820 0x000f_0000 | rw | RTC_ALRMBR (alarm B register).HU (hour units BCD value bits): %x\n", $RTC_ALRMBR>>16&0xF
	printf "0x4000_2820 0x0030_0000 | rw | RTC_ALRMBR (alarm B register).HT (hour tens BCD value bits): %x\n", $RTC_ALRMBR>>20&0x3
	printf "0x4000_2820 0x0040_0000 | rw | RTC_ALRMBR (alarm B register).PM (am or 24h/0 or pm/1 notation bit): %x\n", $RTC_ALRMBR>>22&0x1
	printf "0x4000_2820 0x0080_8000 | rw | RTC_ALRMBR (alarm B register).MSK3 (hour match/0 dont care/1 compare mask bit): %x\n", $RTC_ALRMBR>>23&0x1
	printf "0x4000_2820 0x0f00_0000 | rw | RTC_ALRMBR (alarm B register).DU (date units BCD value bits): %x\n", $RTC_ALRMBR>>24&0xF
	printf "0x4000_2820 0x3000_0000 | rw | RTC_ALRMBR (alarm B register).DT (date tens BCD value bits): %x\n", $RTC_ALRMBR>>28&0x3
	printf "0x4000_2820 0x4000_0000 | rw | RTC_ALRMBR (alarm B register).WDSEL (DU represents day of month/0 week/1; date select mode bit): %x\n", $RTC_ALRMBR>>30&0x1
	printf "0x4000_2820 0x8000_0000 | rw | RTC_ALRMBR (alarm B register).MSK4 (date match/0 dont care/1 compare mask bit): %x\n", $RTC_ALRMBR>>31&0x1
	printf "0x4000_2820 0xffff_ffff | rw | RTC_ALRMBR (alarm B register).value (r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_ALRMBR>>16&0xFFFF, $RTC_ALRMBR&0xFFFF

	printf "0x4000_2824 0x0000_00ff |  w | RTC_WPR (write protection register).KEY (w!DBP==1; write protection key): N/A\n"
	printf "0x4000_2824 0x0000_00ff |  w | RTC_WPR (write protection register).value (r=0x0000_0000 k1=0xCA k2=0x53): N/A\n"

	printf "0x4000_2828 0x0000_ffff | r  | RTC_SSR (subsecond shadow register).SS (synchronous prescaler downcounter; subsecond value bits): 0x%04x\n", $RTC_SSR&0xFFFF
	printf "0x4000_2828 0x0000_ffff | r  | RTC_SSR (subsecond shadow register).value (r=0x0000_0000): 0x%04x_%04x\n", $RTC_SSR>>16&0xFFFF, $RTC_SSR&0xFFFF

	printf "0x4000_282c 0x8000_7fff |  w | RTC_SHIFTR (shift control register).SUBFS (w!SHPF==0&REFCKON==0; extend second, decreases seconds; e.g. 1.1 becomes 1.0; subtract fraction of a second value bits): NA\n"
	printf "0x4000_282c 0x8000_0000 |  w | RTC_SHIFTR (shift control register).ADD1S (w!SHPF==0&REFCKON==0; shrink second, increases seconds; e.g. 0.9 becomes 1.0; add one second prior to SUBFS): NA\n"
	printf "0x4000_282c 0x8000_7fff |  w | RTC_SHIFTR (shift control register).value (r=not_affected rtc=0x0000_0000): NA\n"

	printf "0x4000_2830 0x0000_000f | r  | RTC_TSTR (timestamp time register).SU (second units BCD value bits): %x\n", $RTC_TSTR&0xF
	printf "0x4000_2830 0x0000_0070 | r  | RTC_TSTR (timestamp time register).SU (second tens BCD value bits): %x\n", $RTC_TSTR>>4&0x7
	printf "0x4000_2830 0x0000_0f00 | r  | RTC_TSTR (timestamp time register).MNU (minute units BCD value bits): %x\n", $RTC_TSTR>>8&0xF
	printf "0x4000_2830 0x0000_7000 | r  | RTC_TSTR (timestamp time register).MNT (minute tens BCD value bits): %x\n", $RTC_TSTR>>12&0x7
	printf "0x4000_2830 0x000f_0000 | r  | RTC_TSTR (timestamp time register).HU (hour units BCD value bits): %x\n", $RTC_TSTR>>16&0xF
	printf "0x4000_2830 0x0030_0000 | r  | RTC_TSTR (timestamp time register).HT (hour tens BCD value bits): %x\n", $RTC_TSTR>>20&0x3
	printf "0x4000_2830 0x0040_0000 | r  | RTC_TSTR (timestamp time register).PM (am or 24h/0 or pm/1 notation bit): %x\n", $RTC_TSTR>>22&0x1
	printf "0x4000_2830 0x007f_7f7f | r  | RTC_TSTR (timestamp time register).value (e!TSF==1; r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_TSTR>>16&0xFFFF, $RTC_TSTR&0xFFFF

	printf "0x4000_2834 0x0000_000f | r  | RTC_TSDR (timestamp data register).DU (date units BCD value bits): %x\n", $RTC_TSDR&0xF
	printf "0x4000_2834 0x0000_0030 | r  | RTC_TSDR (timestamp data register).DT (date tens BCD value bits): %x\n", $RTC_TSDR>>4&0x3
	printf "0x4000_2834 0x0000_0f00 | r  | RTC_TSDR (timestamp data register).MU (months units BCD value bits): %x\n", $RTC_TSDR>>8&0xF
	printf "0x4000_2834 0x0000_1000 | r  | RTC_TSDR (timestamp data register).MT (months tens BCD value bits): %x\n", $RTC_TSDR>>12&0x1
	printf "0x4000_2834 0x0000_e000 | r  | RTC_TSDR (timestamp data register).WDU (1/mon 2/tue 3/wed 4/thu 5/fri 6/sat 7/sun; week day units bits): %x\n", $RTC_TSDR>>13&0x7
	printf "0x4000_2834 0x0000_ff3f | r  | RTC_TSDR (timestamp data register).value (e!TSF==1; r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_TSDR>>16&0xFFFF, $RTC_TSDR&0xFFFF

	printf "0x4000_2838 0x0000_ffff | r  | RTC_TSSSR (timestamp subsecond register).SS (synchronous prescaler downcounter; subsecond value bits): 0x%04x\n", $RTC_TSSSR&0xFFFF
	printf "0x4000_2838 0x0000_ffff | r  | RTC_TSSSR (timestamp subsecond register).value (e!TSF==1; r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_TSSSR>>16&0xFFFF, $RTC_TSSSR&0xFFFF

	printf "0x4000_283c 0x0000_01ff | rw | RTC_CALR (calibration register).CALM (calibration mask bits): 0x%03x\n", $RTC_CALR&0x1FF
	printf "0x4000_283c 0x0000_2000 | rw | RTC_CALR (calibration register).CALW16 (16 second calibration cycle period select bit): 0x%03x\n", $RTC_CALR>>13&0x1
	printf "0x4000_283c 0x0000_4000 | rw | RTC_CALR (calibration register).CALW8 (8 second calibration cycle period select bit): 0x%03x\n", $RTC_CALR>>14&0x1
	printf "0x4000_283c 0x0000_8000 | rw | RTC_CALR (calibration register).CALP (insert RTCCLK pulse every 2^11 pulse): 0x%03x\n", $RTC_CALR>>15&0x1
	printf "0x4000_283c 0x0000_e1ff | rw | RTC_CALR (calibration register).value (r=not_affected): 0x%04x_%04x\n", $RTC_CALR>>16&0xFFFF, $RTC_CALR&0xFFFF

	printf "0x4000_2840 0x0000_0001 | rw | RTC_TAMPCR (tamper configuration register).TAMP1E (RTC_TAMP1 enable bit): %x\n", $RTC_TAMPCR&0x1
	printf "0x4000_2840 0x0000_0002 | rw | RTC_TAMPCR (tamper configuration register).TAMP1TRG (RTC_TAMP1 active level is 0:low/rise 1:high/fall; triger bit): %x\n", $RTC_TAMPCR>>1&0x1
	printf "0x4000_2840 0x0000_0004 | rw | RTC_TAMPCR (tamper configuration register).TAMPIE (tamper interrupt enable bit): %x\n", $RTC_TAMPCR>>2&0x1
	printf "0x4000_2840 0x0000_0008 | rw | RTC_TAMPCR (tamper configuration register).TAMP2E (RTC_TAMP2 enable bit): %x\n", $RTC_TAMPCR>>3&0x1
	printf "0x4000_2840 0x0000_0010 | rw | RTC_TAMPCR (tamper configuration register).TAMP2TRG (RTC_TAMP2 active level is 0:low/rise 1:high/fall; triger bit): %x\n", $RTC_TAMPCR>>4&0x1
	printf "0x4000_2840 0x0000_0020 | rw | RTC_TAMPCR (tamper configuration register).TAMP3E (RTC_TAMP3 enable bit): %x\n", $RTC_TAMPCR>>5&0x1
	printf "0x4000_2840 0x0000_0040 | rw | RTC_TAMPCR (tamper configuration register).TAMP3TRG (RTC_TAMP3 active level is 0:low/rise 1:high/fall; triger bit): %x\n", $RTC_TAMPCR>>6&0x1
	printf "0x4000_2840 0x0000_0080 | rw | RTC_TAMPCR (tamper configuration register).TAMPTS (timestamp on tamper detection enable bit): %x\n", $RTC_TAMPCR>>7&0x1
	printf "0x4000_2840 0x0000_0700 | rw | RTC_TAMPCR (tamper configuration register).TAMPFREQ (0..7:'RTCCLK/2^15..8'; tamper sampling frequency bits): %x\n", $RTC_TAMPCR>>8&0x7
	printf "0x4000_2840 0x0000_1800 | rw | RTC_TAMPCR (tamper configuration register).TAMPFLT (0:'edge to active level' 1..3:'2,4,8 consecutive samples active level'; TAMPxTRG filter count): %x\n", $RTC_TAMPCR>>11&0x3
	printf "0x4000_2840 0x0000_6000 | rw | RTC_TAMPCR (tamper configuration register).TAMPPRCH (0..3:'1,2,4,8 RTCCLK cycles'; RTC_TAMPx pull-up duration before each sample; select bits): %x\n", $RTC_TAMPCR>>13&0x3
	printf "0x4000_2840 0x0000_8000 | rw | RTC_TAMPCR (tamper configuration register).TAMPPUDIS (RTC_TAMPx pull-up before each sample; disable bit): %x\n", $RTC_TAMPCR>>15&0x1
	printf "0x4000_2840 0x0001_0000 | rw | RTC_TAMPCR (tamper configuration register).TAMP1IE (tamper 1 interrupt enable bit): %x\n", $RTC_TAMPCR>>16&0x1
	printf "0x4000_2840 0x0002_0000 | rw | RTC_TAMPCR (tamper configuration register).TAMP1NOERASE (tamper 1 event erase backup registers disable bit): %x\n", $RTC_TAMPCR>>17&0x1
	printf "0x4000_2840 0x0004_0000 | rw | RTC_TAMPCR (tamper configuration register).TAMP1MF (TAMP1F disable bit): %x\n", $RTC_TAMPCR>>18&0x1
	printf "0x4000_2840 0x0008_0000 | rw | RTC_TAMPCR (tamper configuration register).TAMP2IE (tamper 2 interrupt enable bit): %x\n", $RTC_TAMPCR>>19&0x1
	printf "0x4000_2840 0x0010_0000 | rw | RTC_TAMPCR (tamper configuration register).TAMP2NOERASE (tamper 2 event erase backup registers disable bit): %x\n", $RTC_TAMPCR>>20&0x1
	printf "0x4000_2840 0x0020_0000 | rw | RTC_TAMPCR (tamper configuration register).TAMP2MF (TAMP2F disable bit): %x\n", $RTC_TAMPCR>>21&0x1
	printf "0x4000_2840 0x0040_0000 | rw | RTC_TAMPCR (tamper configuration register).TAMP3IE (tamper 3 interrupt enable bit): %x\n", $RTC_TAMPCR>>22&0x1
	printf "0x4000_2840 0x0080_0000 | rw | RTC_TAMPCR (tamper configuration register).TAMP3NOERASE (tamper 3 event erase backup registers disable bit): %x\n", $RTC_TAMPCR>>23&0x1
	printf "0x4000_2840 0x0100_0000 | rw | RTC_TAMPCR (tamper configuration register).TAMP3MF (TAMP3F disable bit): %x\n", $RTC_TAMPCR>>24&0x1
	printf "0x4000_2840 0x01ff_ffff | rw | RTC_TAMPCR (tamper configuration register).value (r=not_affected): 0x%04x_%04x\n", $RTC_TAMPCR>>16&0xFFFF, $RTC_TAMPCR&0xFFFF

	printf "0x4000_2844 0x0f00_0000 | rw | RTC_ALRMASSR (alarm A subsecond register).MASKSS (0:disable 1..15:'compare N least-significant bits'; SS bitmask): %x\n", $RTC_ALRMASSR>>24&0xF
	printf "0x4000_2844 0x0000_7fff | rw | RTC_ALRMASSR (alarm A subsecond register).SS (synchronous prescaler counter): 0x%04x\n", $RTC_ALRMASSR&0x7FFF
	printf "0x4000_2844 0x0f00_7fff | rw | RTC_ALRMASSR (alarm A subsecond register).value (r=not_affected): 0x%04x_%04x\n", $RTC_ALRMASSR>>16&0xFFFF, $RTC_ALRMASSR&0xFFFF

	printf "0x4000_2848 0x0f00_0000 | rw | RTC_ALRMBSSR (alarm B subsecond register).MASKSS (0:disable 1..15:'compare N least-significant bits'; SS bitmask): %x\n", $RTC_ALRMBSSR>>24&0xF
	printf "0x4000_2848 0x0000_7fff | rw | RTC_ALRMBSSR (alarm B subsecond register).SS (synchronous prescaler counter): 0x%04x\n", $RTC_ALRMBSSR&0x7FFF
	printf "0x4000_2848 0x0f00_7fff | rw | RTC_ALRMBSSR (alarm B subsecond register).value (r=not_affected): 0x%04x_%04x\n", $RTC_ALRMBSSR>>16&0xFFFF, $RTC_ALRMBSSR&0xFFFF

	printf "0x4000_284c 0x0000_0001 | rw | RTC_OR (option register).RTC_ALARM_TYPE (0:open-drain 1:push-pull; RTC_ALARM output pin type bit): %x\n", $RTC_OR&0x1
	printf "0x4000_284c 0x0000_0002 | rw | RTC_OR (option register).RTC_OUT_RMP (RTC_OUT from PB14 to PC13 remap bit): %x\n", $RTC_OR>>1&0x1
	printf "0x4000_284c 0x0000_0003 | rw | RTC_OR (option register).value (r=not_affected): 0x%04x_%04x\n", $RTC_OR>>16&0xFFFF, $RTC_OR&0xFFFF

	printf "0x4000_2850 0xffff_ffff | rw | RTC_BKP0R (backup register).value (r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_BKP0R>>16&0xFFFF, $RTC_BKP0R&0xFFFF
	printf "0x4000_2854 0xffff_ffff | rw | RTC_BKP1R (backup register).value (r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_BKP1R>>16&0xFFFF, $RTC_BKP1R&0xFFFF
	printf "0x4000_2858 0xffff_ffff | rw | RTC_BKP2R (backup register).value (r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_BKP2R>>16&0xFFFF, $RTC_BKP2R&0xFFFF
	printf "0x4000_285c 0xffff_ffff | rw | RTC_BKP3R (backup register).value (r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_BKP3R>>16&0xFFFF, $RTC_BKP3R&0xFFFF
	printf "0x4000_2860 0xffff_ffff | rw | RTC_BKP4R (backup register).value (r=not_affected rtc=0x0000_0000): 0x%04x_%04x\n", $RTC_BKP4R>>16&0xFFFF, $RTC_BKP4R&0xFFFF

	printf "0x4000_5400 0x0000_0001 | rw | I2C_CR1 (control register 1).PE (peripheral semi-reset/0 or enable/1 bit): %x\n", $I2C_CR1&0x1
	printf "0x4000_5400 0x0000_0002 | rw | I2C_CR1 (control register 1).TXIE (TXIS transmit interrupt enable bit): %x\n", $I2C_CR1>>1&0x1
	printf "0x4000_5400 0x0000_0004 | rw | I2C_CR1 (control register 1).RXIE (TXNE receive interrupt enable bit): %x\n", $I2C_CR1>>2&0x1
	printf "0x4000_5400 0x0000_0008 | rw | I2C_CR1 (control register 1).ADDRIE (ADDR address match interrupt enable bit): %x\n", $I2C_CR1>>3&0x1
	printf "0x4000_5400 0x0000_0010 | rw | I2C_CR1 (control register 1).NACKIE (NACKF not acknowledge received interrupt enable bit): %x\n", $I2C_CR1>>4&0x1
	printf "0x4000_5400 0x0000_0020 | rw | I2C_CR1 (control register 1).STOPIE (STOPF stop detected interrupt enable bit): %x\n", $I2C_CR1>>5&0x1
	printf "0x4000_5400 0x0000_0040 | rw | I2C_CR1 (control register 1).TCIE (TC,TCR transfer complete interrupt enable bit): %x\n", $I2C_CR1>>6&0x1
	printf "0x4000_5400 0x0000_0080 | rw | I2C_CR1 (control register 1).ERRIE (BERR,ARLO,OVR,PECER,TIMEOUT,ALERT error detected interrupt enable bit): %x\n", $I2C_CR1>>7&0x1
	printf "0x4000_5400 0x0000_0f00 | rw | I2C_CR1 (control register 1).DNF (w!PE==0, Tdnf=.*Ti2cclk; digital noise filter bits): %x\n", $I2C_CR1>>8&0xf
	printf "0x4000_5400 0x0000_1000 | rw | I2C_CR1 (control register 1).ANFOFF (w!PE==0; Taf=50ns; analog noise filter disable bit): %x\n", $I2C_CR1>>12&0x1
	printf "0x4000_5400 0x0000_4000 | rw | I2C_CR1 (control register 1).TXDMAEN (DMA mode enabled for transmission bit): %x\n", $I2C_CR1>>14&0x1
	printf "0x4000_5400 0x0000_8000 | rw | I2C_CR1 (control register 1).RXDMAEN (DMA mode enabled for reception bit): %x\n", $I2C_CR1>>15&0x1
	printf "0x4000_5400 0x0001_0000 | rw | I2C_CR1 (control register 1).SBC (slave mode w/ hw byte control enabled bit): %x\n", $I2C_CR1>>16&0x1
	printf "0x4000_5400 0x0002_0000 | rw | I2C_CR1 (control register 1).NOSTRETCH (w!PE==0; clock stretching disable bit): %x\n", $I2C_CR1>>17&0x1
	printf "0x4000_5400 0x0004_0000 | rw | I2C_CR1 (control register 1).WUPEN (w!DNF==0; wakeup from stop mode enable bit): %x\n", $I2C_CR1>>18&0x1
	printf "0x4000_5400 0x0008_0000 | rw | I2C_CR1 (control register 1).GCEN (general call enable bit): %x\n", $I2C_CR1>>19&0x1
	printf "0x4000_5400 0x0010_0000 | rw | I2C_CR1 (control register 1).SMBHEN (host/1 device/0 mode; SMBus host address enable bit): %x\n", $I2C_CR1>>20&0x1
	printf "0x4000_5400 0x0020_0000 | rw | I2C_CR1 (control register 1).SMBDEN (SMBus device default address enable bit): %x\n", $I2C_CR1>>21&0x1
	printf "0x4000_5400 0x0040_0000 | rw | I2C_CR1 (control register 1).ALERTEN (b!SMBHEN; SMBus alert enable bit): %x\n", $I2C_CR1>>22&0x1
	printf "0x4000_5400 0x0080_0000 | rw | I2C_CR1 (control register 1).PECEN (packet error correction enable bit): %x\n", $I2C_CR1>>23&0x1
	printf "0x4000_5400 0x00ff_dfff | rw | I2C_CR1 (control register 1).value (r=0x0000_0000): 0x%04x_%04x\n", $I2C_CR1>>16&0xFFFF, $I2C_CR1&0xFFFF

	printf "0x4000_5404 0x0000_03ff | rw | I2C_CR2 (control register 2).SADD (w!START==0; slave address bits): 0x%03x\n", $I2C_CR2&0x3FF
	printf "0x4000_5404 0x0000_0400 | rw | I2C_CR2 (control register 2).RD_WRN (w!START==0; master requests a write/0 read/1 transfer direction bit): %x\n", $I2C_CR2>>10&0x1
	printf "0x4000_5404 0x0000_0800 | rw | I2C_CR2 (control register 2).ADD10 (w!START==0; master operates in 7,10-bit/0,1 address mode bit): %x\n", $I2C_CR2>>11&0x1
	printf "0x4000_5404 0x0000_1000 | rw | I2C_CR2 (control register 2).HEAD10R (w!START==0; 10bit address header only read direction bit): %x\n", $I2C_CR2>>12&0x1
	printf "0x4000_5404 0x0000_2000 | rs1| I2C_CR2 (control register 2).START (w!; generate a re/start bit): %x\n", $I2C_CR2>>13&0x1
	printf "0x4000_5404 0x0000_4000 | rs1| I2C_CR2 (control register 2).STOP (generate a stop bit): %x\n", $I2C_CR2>>14&0x1
	printf "0x4000_5404 0x0000_8000 | rs1| I2C_CR2 (control register 2).NACK (ACK/0 NACK/1 is sent after current received byte bit): %x\n", $I2C_CR2>>15&0x1
	printf "0x4000_5404 0x00ff_0000 | rw | I2C_CR2 (control register 2).NBYTES (w!START==0 e!SBC==1; number of bytes): 0x%02x\n", $I2C_CR2>>16&0xff
	printf "0x4000_5404 0x0100_0000 | rw | I2C_CR2 (control register 2).RELOAD (NBYTES reload mode bit): %x\n", $I2C_CR2>>24&0x1
	printf "0x4000_5404 0x0200_0000 | rw | I2C_CR2 (control register 2).AUTOEND (e!RELOAD==0; software/0 automatic/1 end mode bit): %x\n", $I2C_CR2>>25&0x1
	printf "0x4000_5404 0x0400_0000 | rs1| I2C_CR2 (control register 2).PECBYTE (e!RELOAD==0; PEC tx/rx request/1 finished/0 bit): %x\n", $I2C_CR2>>26&0x1
	printf "0x4000_5404 0x07ff_ffff | rw | I2C_CR2 (control register 2).value (r=0x0000_0000): 0x%04x_%04x\n", $I2C_CR2>>16&0xFFFF, $I2C_CR2&0xFFFF

	printf "0x4000_5408 0x0000_03ff | rw | I2C_OAR1 (own address 1 register).OA1 (w!OA1EN==0; interface address): 0x%03x\n", $I2C_OAR1&0x3FF
	printf "0x4000_5408 0x0000_0400 | rw | I2C_OAR1 (own address 1 register).OA1MODE (w!OA1EN==0; 7,10-bit/0,1 address mode bit): %x\n", $I2C_OAR1>>10&0x1
	printf "0x4000_5408 0x0000_8000 | rw | I2C_OAR1 (own address 1 register).OA1EN (address enable bit): %x\n", $I2C_OAR1>>10&0x1
	printf "0x4000_5408 0x0000_87ff | rw | I2C_OAR1 (own address 1 register).value (r=0x0000_0000): 0x%04x_%04x\n", $I2C_OAR1>>16&0xFFFF, $I2C_OAR1&0xFFFF

	printf "0x4000_540c 0x0000_00fe | rw | I2C_OAR2 (own address 2 register).OA2 (w!OA2EN==0; interface address): 0x%02x\n", $I2C_OAR2>>1&0x7F
	printf "0x4000_540c 0x0000_0700 | rw | I2C_OAR2 (own address 2 register).OA2MSK (w!OA2EN==0; mask first 1..7-bits/1..7 or nomask/0 bits): 0x%02x\n", $I2C_OAR2>>8&0x7
	printf "0x4000_540c 0x0000_8000 | rw | I2C_OAR2 (own address 2 register).OA2EN (address enable bit): 0x%02x\n", $I2C_OAR2>>8&0x7
	printf "0x4000_540c 0x0000_87fe | rw | I2C_OAR2 (own address 2 register).value (r=0x0000_0000): 0x%04x_%04x\n", $I2C_OAR2>>16&0xFFFF, $I2C_OAR2&0xFFFF

	printf "0x4000_5410 0x0000_00ff | rw | I2C_TIMINGR (timing register).SCLL (w!PE==0; Tscll=(.+1)*Tpresc; SCL low period in master mode bits): 0x%02x\n", $I2C_TIMINGR&0xFF
	printf "0x4000_5410 0x0000_ff00 | rw | I2C_TIMINGR (timing register).SCLH (w!PE==0; Tsclh=(.+1)*Tpresc; SCL high period in master mode bits): 0x%02x\n", $I2C_TIMINGR>>8&0xFF
	printf "0x4000_5410 0x000f_0000 | rw | I2C_TIMINGR (timing register).SDADEL (w!PE==0; Tsdadel=.*Tpresc; Data hold time bits): %x\n", $I2C_TIMINGR>>16&0xF
	printf "0x4000_5410 0x00f0_0000 | rw | I2C_TIMINGR (timing register).SCLDEL (w!PE==0; Tscldel=(.+1)*Tpresc; Data setup time bits): %x\n", $I2C_TIMINGR>>20&0xF
	printf "0x4000_5410 0xf000_0000 | rw | I2C_TIMINGR (timing register).PRESC (w!PE==0; Tpresc=(.+1)*Ti2cclk): %x\n", $I2C_TIMINGR>>28&0xF
	printf "0x4000_5410 0xf0ff_ffff | rw | I2C_TIMINGR (timing register).value (r=0x0000_0000): 0x%04x_%04x\n", $I2C_TIMINGR>>16&0xFFFF, $I2C_TIMINGR&0xFFFF

	printf "0x4000_5414 0x0000_0fff | rw | I2C_TIMEOUTR (timeout register).TIMEOUTA (w!TIMEOUTEN==0, TIDLE ? Tidle=(.+1)*4*Ti2cclk : Ttimeout=(.+1)*2048*Ti2cclk; Bus Timeout A bits): 0x%03x\n", $I2C_TIMEOUTR&0xFFF
	printf "0x4000_5414 0x0000_1000 | rw | I2C_TIMEOUTR (timeout register).TIDLE (w!TIMEOUTEN==0, TIMEOUTA detects SCL low/0 or SCL&SDA high/1 timeout bit): %x\n", $I2C_TIMEOUTR>>12&0x1
	printf "0x4000_5414 0x0000_8000 | rw | I2C_TIMEOUTR (timeout register).TIMEOUTEN (ERR:=TIDLE ? Tsclhigh > Tidle : Tscllow > Ttimeout; SCL timeout detection enable bit): %x\n", $I2C_TIMEOUTR>>15&0x1
	printf "0x4000_5414 0x0fff_0000 | rw | I2C_TIMEOUTR (timeout register).TIMEOUTB (w!TEXTEN==0, Tlow:ext=(.+1)*2048*Ti2cclk; Bus Timeout B): 0x%03x\n", $I2C_TIMEOUTR>>16&0xFFF
	printf "0x4000_5414 0x8000_0000 | rw | I2C_TIMEOUTR (timeout register).TEXTEN (extended clock timeout detect enable bit): %x\n", $I2C_TIMEOUTR>>31&0x1
	printf "0x4000_5414 0x8fff_9fff | rw | I2C_TIMEOUTR (timeout register).value (r=0x0000_0000): 0x%04x_%04x\n", $I2C_TIMEOUTR>>16&0xFFFF, $I2C_TIMEOUTR&0xFFFF

	printf "0x4000_5418 0x0000_0001 | rs1| I2C_ISR (interrupt and status register).TXE (sw1 to flush TXDR; TXDR is empty and awaits data/1 or has data to be sent/0; tx data register empty bit): %x\n", $I2C_ISR>>0&0x1
	printf "0x4000_5418 0x0000_0002 | rs1| I2C_ISR (interrupt and status register).TXIS (sw1 to make TXIS event; TXDR is empty and must give data; tx interrupt status): %x\n", $I2C_ISR>>1&0x1
	printf "0x4000_5418 0x0000_0004 | r  | I2C_ISR (interrupt and status register).RXNE (RXDR is read/0 or rx data copy'd to RXDR/1; rx data reg not empty flag): %x\n", $I2C_ISR>>2&0x1
	printf "0x4000_5418 0x0000_0008 | r  | I2C_ISR (interrupt and status register).ADDR (rx slave address matched flag): %x\n", $I2C_ISR>>3&0x1
	printf "0x4000_5418 0x0000_0010 | r  | I2C_ISR (interrupt and status register).NACKF (after byte tx, not acknowledge received flag): %x\n", $I2C_ISR>>4&0x1
	printf "0x4000_5418 0x0000_0020 | r  | I2C_ISR (interrupt and status register).STOPF (stop detection flag): %x\n", $I2C_ISR>>5&0x1
	printf "0x4000_5418 0x0000_0040 | r  | I2C_ISR (interrupt and status register).TC (hw1 when RELOAD==0 & AUTOEND==0 & NBYTES tx'ed; sw0 by START:=1 or STOP:=1; transfer complete flag): %x\n", $I2C_ISR>>6&0x1
	printf "0x4000_5418 0x0000_0080 | r  | I2C_ISR (interrupt and status register).TCR (hw1 when RELOAD==1 & NBYTES tx'ed; sw0 by NBYTES:=!0; transfer complete reload flag): %x\n", $I2C_ISR>>7&0x1
	printf "0x4000_5418 0x0000_0100 | r  | I2C_ISR (interrupt and status register).BERR (hw1 when stop/start while tx; bus error flag): %x\n", $I2C_ISR>>8&0x1
	printf "0x4000_5418 0x0000_0200 | r  | I2C_ISR (interrupt and status register).ARLO (hw1 when arb'n loss; arbitration lost flag): %x\n", $I2C_ISR>>9&0x1
	printf "0x4000_5418 0x0000_0400 | r  | I2C_ISR (interrupt and status register).OVR (hw1 when over/underrun error occured flag): %x\n", $I2C_ISR>>10&0x1
	printf "0x4000_5418 0x0000_0800 | r  | I2C_ISR (interrupt and status register).PECERR (PEC error w/ rx flag): %x\n", $I2C_ISR>>11&0x1
	printf "0x4000_5418 0x0000_1000 | r  | I2C_ISR (interrupt and status register).TIMEOUT (timeout or extended clock timeout occured flag): %x\n", $I2C_ISR>>12&0x1
	printf "0x4000_5418 0x0000_2000 | r  | I2C_ISR (interrupt and status register).ALERT (SMBus alert detected on SMBA pin flag): %x\n", $I2C_ISR>>13&0x1
	printf "0x4000_5418 0x0000_8000 | r  | I2C_ISR (interrupt and status register).BUSY (hw1 when start, sw0 when stop; bus busy flag): %x\n", $I2C_ISR>>15&0x1
	printf "0x4000_5418 0x0001_0000 | r  | I2C_ISR (interrupt and status register).DIR (write/0 read/1 transfer; slave enters rx/0 tx/1 mode; transfer direction flag): %x\n", $I2C_ISR>>16&0x1
	printf "0x4000_5418 0x00fe_0000 | r  | I2C_ISR (interrupt and status register).ADDCODE (slave mode; recv addr when match occured bits): %x\n", $I2C_ISR>>17&0x7F
	printf "0x4000_5418 0x00ff_bfff | rs1| I2C_ISR (interrupt and status register).value (r=0x0000_0001): 0x%04x_%04x\n", $I2C_ISR>>16&0xFFFF, $I2C_ISR&0xFFFF
	printf "0x4000_541c 0x0000_0008 |  w | I2C_ICR (interrupt clear register).ADDRCF (ADDR, STOP flags clear bit): N/A\n"
	printf "0x4000_541c 0x0000_0010 |  w | I2C_ICR (interrupt clear register).NACKCF (NACKF flag clear bit): N/A\n"
	printf "0x4000_541c 0x0000_0020 |  w | I2C_ICR (interrupt clear register).STOPCF (STOPF flag clear bit): N/A\n"
	printf "0x4000_541c 0x0000_0100 |  w | I2C_ICR (interrupt clear register).BERRCF (BERRF flag clear bit): N/A\n"
	printf "0x4000_541c 0x0000_0010 |  w | I2C_ICR (interrupt clear register).ARLOCF (ARLO flag clear bit): N/A\n"
	printf "0x4000_541c 0x0000_0010 |  w | I2C_ICR (interrupt clear register).OVRCF (OVR flag clear bit): N/A\n"
	printf "0x4000_541c 0x0000_0010 |  w | I2C_ICR (interrupt clear register).PECCF (PECERR flag clear bit): N/A\n"
	printf "0x4000_541c 0x0000_0010 |  w | I2C_ICR (interrupt clear register).TIMEOUTCF (TIMOUT flag clear bit): N/A\n"
	printf "0x4000_541c 0x0000_0010 |  w | I2C_ICR (interrupt clear register).ALERTCF (ALERT flag clear bit): N/A\n"
	printf "0x4000_541c 0x0000_3f38 |  w | I2C_ICR (interrupt clear register).value: N/A\n"
	printf "0x4000_5420 0x0000_00ff | r  | I2C_PECR (packet error chcking register).PEC (clear when PE==0; internal PEC when PECEN==1): 0x%02x\n", $I2C_PECR&0xFF
	printf "0x4000_5420 0x0000_00ff | r  | I2C_PECR (packet error chcking register).value (r=0x0000_0000): 0x%04x_%04x\n", $I2C_PECR>>16&0xFFFF, $I2C_PECR&0xFFFF
	printf "0x4000_5424 0x0000_00ff | r  | I2C_RXDR (receive data register).RXDATA (data byte received from I2C bus): 0x%02x\n", $I2C_RXDR&0xFF
	printf "0x4000_5424 0x0000_00ff | r  | I2C_RXDR (receive data register).value (r=0x0000_0000): 0x%04x_%04x\n", $I2C_RXDR>>16&0xFFFF, $I2C_RXDR&0xFFFF
	printf "0x4000_5428 0x0000_00ff | rw | I2C_TXDR (transmit data register).TXDATA (TXE==1; byte to be transmitted to the I2C bus): 0x%02x\n", $I2C_TXDR&0xFF
	printf "0x4000_5428 0x0000_00ff | rw | I2C_TXDR (transmit data register).value (r=0x0000_0000): 0x%04x_%04x\n", $I2C_TXDR>>16&0xFFFF, $I2C_TXDR&0xFFFF
	printf "0x4000_7000 0x0000_0001 | rw | PWR_CR (power control register).LPSDSR (voltage Regulator kept On/0 or switched Low Power/1 when CPU Enters Sleep/Deep Sleep mode bit): %x\n", $PWR_CR&0x1
	printf "0x4000_7000 0x0000_0002 | rw | PWR_CR (power control register).PDDS (0/1 Enter Stop/Standby mode when CPU enters Deep Sleep; Power-Down Deep Sleep bit): %x\n", $PWR_CR>>1&0x1,
	printf "0x4000_7000 0x0000_0004 | rc1| PWR_CR (power control register).CWUF (nop/0 or Clear the WakeUp Flag after 2 sysclk cycles/1): %x\n", $PWR_CR>>2&0x1,
	printf "0x4000_7000 0x0000_0008 | rc1| PWR_CR (power control register).CSBF (nop/0 or Clear StandBy Flag/1): %x\n", $PWR_CR>>3&0x1,
	printf "0x4000_7000 0x0000_0010 | rw | PWR_CR (power control register).PVDE (Power Voltage Detector Enable bit): %x\n", $PWR_CR>>3&0x1,
	printf "0x4000_7000 0x0000_00e0 | rw | PWR_CR (power control register).PLS (1.9V/0 2.1V/1 2.3V/2 2.5V/3 2.7V/4 2.9V/5 3.1V/6 External/7; PVD Level Selection bits): %x\n", $PWR_CR>>5&0x7,
	printf "0x4000_7000 0x0000_0100 | rw | PWR_CR (power control register).DBP (Disable (RTC, RTC Backup, RCC CSR register) write Protection bit): %x\n", $PWR_CR>>8&0x1,
	printf "0x4000_7000 0x0000_0200 | rw | PWR_CR (power control register).ULP (0/1 Vrefint on/off LP mode; Ultra Low Power mode bit): %x\n", $PWR_CR>>9&0x1,
	printf "0x4000_7000 0x0000_0400 | rw | PWR_CR (power control register).FWU (Exit from LP mode 'wait until'/0 'skip'/1 Vrefint is ready; Fast Wake Up bit): %x\n", $PWR_CR>>10&0x1,
	printf "0x4000_7000 0x0000_1800 | rw | PWR_CR (power control register).VOS (forbid/0 1.8V/1 1.5V/2 1.2V/3; VOltage Scaling selection bit): %x\n", $PWR_CR>>11&0x3,
	printf "0x4000_7000 0x0000_2000 | rw | PWR_CR (power control register).DS_EE_KOFF (Exit from LP mode 'wake up'/0 'keep off'/1 non-volatiles; Deep Sleep exit, flash and EEPROM Kept OFF bit): %x\n", $PWR_CR>>13&0x1,
	printf "0x4000_7000 0x0000_4000 | rw | PWR_CR (power control register).LPRUN (0/1 Set VR to main/low-power mode in 'LP run mode'; Low Power RUN mode bit): %x\n", $PWR_CR>>14&0x1,
	printf "0x4000_7000 0x0001_0000 | rw | PWR_CR (power control register).LPDS (cat1 devices only; 0/1 Set VR main/low-power mode when CPU enters stop mode; Low-Power Deep Sleep mode bit): %x\n", $PWR_CR>>15&0x1,
	printf "0x4000_7000 0x0001_7fff | rw | PWR_CR (power control register).value (r=0x000_1000): 0x%04x_%04x\n", $PWR_CR>>16&0xFFFF, $PWR_CR&0xFFFF

	printf "0x4000_7004 0x0000_0001 | r  | PWR_CSR (power control/status register).WUF (wakeup occured flag): %x\n", $PWR_CSR&0x1
	printf "0x4000_7004 0x0000_0002 | r  | PWR_CSR (power control/status register).SBF (instead of stop mode, device was in standby flag): %x\n", $PWR_CSR>>1&0x1
	printf "0x4000_7004 0x0000_0004 | r  | PWR_CSR (power control/status register).PVDO (e!PVDE==1; Vdd is higher/0 lower/1 than PVD threshold of PLS flag): %x\n", $PWR_CSR>>2&0x1
	printf "0x4000_7004 0x0000_0008 | r  | PWR_CSR (power control/status register).VREFINTRDYF (internal voltage reference Vrefint ready flag): %x\n", $PWR_CSR>>3&0x1
	printf "0x4000_7004 0x0000_0010 | r  | PWR_CSR (power control/status register).VOSF (internal regulator voltage output changing to VOS level flag): %x\n", $PWR_CSR>>4&0x1
	printf "0x4000_7004 0x0000_0020 | r  | PWR_CSR (power control/status register).REGLPF (regulator voltage is in main/0 low-power/1 mode flag): %x\n", $PWR_CSR>>5&0x1
	printf "0x4000_7004 0x0000_0100 | rw | PWR_CSR (power control/status register).EWUP1 (WKUP1 pin enable bit): %x\n", $PWR_CSR>>8&0x1
	printf "0x4000_7004 0x0000_0200 | rw | PWR_CSR (power control/status register).EWUP2 (WKUP2 pin enable bit): %x\n", $PWR_CSR>>9&0x1
	printf "0x4000_7004 0x0000_0400 | rw | PWR_CSR (power control/status register).EWUP3 (WKUP3 pin enable bit): %x\n", $PWR_CSR>>10&0x1
	printf "0x4000_7004 0x0000_073f | rw | PWR_CSR (power control/status register).value (r=0x0000_0008): 0x%04x_%04x\n", $PWR_CSR>>16&0xFFFF, $PWR_CSR&0xFFFF

	printf "0x4000_7c00 0x0000_0001 | r  | LPTIM_ISR (interrupt and status register).CMPM (LPTIM_CNT == LPTIM_CMP; compare match bit): %x\n", $LPTIM_ISR&0x1,
	printf "0x4000_7c00 0x0000_0002 | r  | LPTIM_ISR (interrupt and status register).ARRM (LPTIM_CNT == LPTIM_ARR; autoreload match bit): %x\n", $LPTIM_ISR>>1&0x1,
	printf "0x4000_7c00 0x0000_0004 | r  | LPTIM_ISR (interrupt and status register).EXTTRIG (selected external input reached valid edge; external trigger bit): %x\n", $LPTIM_ISR>>2&0x1,
	printf "0x4000_7c00 0x0000_0008 | r  | LPTIM_ISR (interrupt and status register).CMPOK (APB bus write to LPTIM_CMP complete; CoMPare register update OK bit): %x\n", $LPTIM_ISR>>3&0x1,
	printf "0x4000_7c00 0x0000_0010 | r  | LPTIM_ISR (interrupt and status register).ARROK (APB bus write to LPTIM_ARR complete; AutoReload Register update OK bit): %x\n", $LPTIM_ISR>>4&0x1,
	printf "0x4000_7c00 0x0000_0020 | r  | LPTIM_ISR (interrupt and status register).UP (ENC==1; encoder mode; Counter direction changed from down to up): %x\n", $LPTIM_ISR>>5&0x1,
	printf "0x4000_7c00 0x0000_0040 | r  | LPTIM_ISR (interrupt and status register).DOWN (ENC==1; encoder mode; Counter direction changed from up to down): %x\n", $LPTIM_ISR>>6&0x1,
	printf "0x4000_7c00 0x0000_007f | r  | LPTIM_ISR (interrupt and status register).value (r=0x0000_0000): 0x%04x_%04x\n", $LPTIM_ISR>>16&0xFFFF, $LPTIM_ISR&0xFFFF,
	printf "0x4000_7c04 0x0000_007f |  w | LPTIM_ICR (interrupt clear register).value (r=0x0000_0000): N/A\n"
	printf "0x4000_7c08 0x0000_0001 | rw | LPTIM_IER (interrupt enable register).CMPMIE (compare match interrupt enable bit): %x\n", $LPTIM_IER&0x1,
	printf "0x4000_7c08 0x0000_0002 | rw | LPTIM_IER (interrupt enable register).ARRMIE (autoreload match interrupt enable bit): %x\n", $LPTIM_IER>>1&0x1,
	printf "0x4000_7c08 0x0000_0004 | rw | LPTIM_IER (interrupt enable register).EXTRIGIE (external trigger active edge interrupt enable bit): %x\n", $LPTIM_IER>>2&0x1,
	printf "0x4000_7c08 0x0000_0008 | rw | LPTIM_IER (interrupt enable register).CMPOKIE (compare register update OK interrupt enable bit): %x\n", $LPTIM_IER>>3&0x1,
	printf "0x4000_7c08 0x0000_0010 | rw | LPTIM_IER (interrupt enable register).ARROKIE (autoreload register update OK interrupt enable bit): %x\n", $LPTIM_IER>>4&0x1,
	printf "0x4000_7c08 0x0000_0020 | rw | LPTIM_IER (interrupt enable register).UPIE (direction change to up interrupt enable bit): %x\n", $LPTIM_IER>>5&0x1,
	printf "0x4000_7c08 0x0000_0040 | rw | LPTIM_IER (interrupt enable register).DOWNIE (direction change to down interrupt enable bit): %x\n", $LPTIM_IER>>6&0x1,
	printf "0x4000_7c08 0x0000_007f | rw | LPTIM_IER (interrupt enable register).value (ENABLE==0; r=0x0000_0000): 0x%04x_%04x\n", $LPTIM_IER>>16&0xFFFF, $LPTIM_IER&0xFFFF,
	printf "0x4000_7c0c 0x0000_0001 | rw | LPTIM_CFGR (configuration register).CKSEL (0/1 internal/external clock source; clock select bit): %x\n", $LPTIM_CFGR&0x1
	printf "0x4000_7c0c 0x0000_0006 | rw | LPTIM_CFGR (configuration register).CKPOL (ext clock; active edge is rising/0, falling/1, both/2 else if ENCODER MODE a sub-mode1,2,3 of 0/1/2; clock polarity bits): %x\n", $LPTIM_CFGR>>1&0x3
	printf "0x4000_7c0c 0x0000_0018 | rw | LPTIM_CFGR (configuration register).CKFLT (ext clock; any/0 signal change or stable for 2/1 4/2 8/3 clocks means valid edge; filter bits): %x\n", $LPTIM_CFGR>>3&0x3
	printf "0x4000_7c0c 0x0000_00c0 | rw | LPTIM_CFGR (configuration register).TRGFLT (any/0 level change or stable for 2/1 4/2 8/3 clocks means valid trigger; internal trigger filter bits): %x\n", $LPTIM_CFGR>>6&0x3
	printf "0x4000_7c0c 0x0000_0e00 | rw | LPTIM_CFGR (configuration register).PRESC (division factor 1/2/4/8/16/32/64/128; clock prescaler bitfield): %x\n", $LPTIM_CFGR>>9&0x7
	printf "0x4000_7c0c 0x0000_e000 | rw | LPTIM_CFGR (configuration register).TRIGSEL (ext clock; TRIGEN!=0; GPIO_af_LPTIM_ETR/0 RTCalarmA,B/1,2 RTC_TAMP1,2,3/3,4,5 COMP1,2/6,7; _external_ trigger source select bitfield): %x\n", $LPTIM_CFGR>>13&0x7
	printf "0x4000_7c0c 0x0006_0000 | rw | LPTIM_CFGR (configuration register).TRIGEN (counter started by sw/0 rise/1 fall/2 both/3; trigger enable bits): %x\n", $LPTIM_CFGR>>17&0x3
	printf "0x4000_7c0c 0x0008_0000 | rw | LPTIM_CFGR (configuration register).TIMOUT (if timer already started, trigev ignored/0 or timer restart/1; timeout enable bit): %x\n", $LPTIM_CFGR>>19&0x1
	printf "0x4000_7c0c 0x0010_0000 | rw | LPTIM_CFGR (configuration register).WAVE (0/1 de/activate set-once mode; waveform output shape bit): %x\n", $LPTIM_CFGR>>20&0x1
	printf "0x4000_7c0c 0x0020_0000 | rw | LPTIM_CFGR (configuration register).WAVPOL (compare results between LPTIM_ARR and LPTIM_CMP/0 or its inverse/1; waveform output shape polarity bit): %x\n", $LPTIM_CFGR>>21&0x1
	printf "0x4000_7c0c 0x0040_0000 | rw | LPTIM_CFGR (configuration register).PRELOAD (up regs on each APBbus write/0 or end of current LPTIM period/1; LPTIM_ARR,CMP regs update mode bit): %x\n", $LPTIM_CFGR>>22&0x1
	printf "0x4000_7c0c 0x0080_0000 | rw | LPTIM_CFGR (configuration register).COUNTMODE (CKSEL==0; counter incremented on each internal/0 or external valid/1 clock pulse; counter mode bit): %x\n", $LPTIM_CFGR>>23&0x1
	printf "0x4000_7c0c 0x0100_0000 | rw | LPTIM_CFGR (configuration register).ENC (CNTSTRT==1 CKSEL==0 PRESC==0; encoder mode enable bit): %x\n", $LPTIM_CFGR>>24&0x1
	printf "0x4000_7c0c 0x01fe_eedf | rw | LPTIM_CFGR (configuration register).value (ENABLE==0; r=0x0000_0000): 0x%04x_%04x\n", $LPTIM_CFGR>>16&0xFFFF, $LPTIM_CFGR&0xFFFF,
	printf "0x4000_7c10 0x0000_0001 | rw | LPTIM_CR (control register).ENABLE (LPTIM enable bit): %x\n", $LPTIM_CR&0x1,
	printf "0x4000_7c10 0x0000_0002 | rw | LPTIM_CR (control register).SNGSTRT (ENABLE==1; LPTIM start in single pulse mode bit): %x\n", $LPTIM_CR>>1&0x1,
	printf "0x4000_7c10 0x0000_0004 | rw | LPTIM_CR (control register).CNTSTRT (ENABLE==1; LPTIM start in continuous mode bit): %x\n", $LPTIM_CR>>2&0x1,
	printf "0x4000_7c10 0x0000_0007 | rw | LPTIM_CR (control register).value (r=0x0000_0000): 0x%04x_%04x\n", $LPTIM_CR>>16&0xFFFF, $LPTIM_CR&0xFFFF,
	printf "0x4000_7c14 0x0000_ffff | rw | LPTIM_CMP (compare register).CMP (used by LPTIM; compare value bitfiled): dec %d\n", $LPTIM_CMP&0xFFFF,
	printf "0x4000_7c14 0x0000_ffff | rw | LPTIM_CMP (compare register).value (r=0x0000_0000): 0x%04x_%04x\n", $LPTIM_CMP>>16&0xFFFF, $LPTIM_CMP&0xFFFF,
	printf "0x4000_7c18 0x0000_ffff | rw | LPTIM_ARR (autoreload register).ARR (autoreload value bitfiled): dec %d\n", $LPTIM_ARR&0xFFFF,
	printf "0x4000_7c18 0x0000_ffff | rw | LPTIM_ARR (autoreload register).value (r=0x0000_0001): 0x%04x_%04x\n", $LPTIM_ARR>>16&0xFFFF, $LPTIM_ARR&0xFFFF,
	printf "0x4000_7c1c 0x0000_ffff | r  | LPTIM_CNT (counter register).CNT (the 16bit counter itself, may be unreliable with async clocks; counter value bitfield): dec %d\n", $LPTIM_CNT&0xFFFF,
	printf "0x4000_7c1c 0x0000_ffff | r  | LPTIM_CNT (counter register).value (r=0x0000_0000): 0x%04x_%04x\n", $LPTIM_CNT>>16&0xFFFF, $LPTIM_CNT&0xFFFF,
	printf "0x4001_0000 0x0000_0003 | rw | SYSCFG_CFGR1 (memory remap register).MEM_MODE (MainFlash/0 SysFlash/1 res/2 SRAM/3; 0x0000_0000 memory map select bits): %x\n", $SYSCFG_CFGR1&0x3,
	printf "0x4001_0000 0x0000_0008 | rw | SYSCFG_CFGR1 (memory remap register).UFB (0x080{1,2}_0000 Flash and 0x0808{0c,18}00 EEPROM user bank swapping bit): %x\n", $SYSCFG_CFGR1>>3&0x1,
	printf "0x4001_0000 0x0000_0300 | r  | SYSCFG_CFGR1 (memory remap register).BOOT_MODE (MainFlash/0 SysFlash/1 res/2 SRAM/3; selected by boot pin status bits): %x\n", $SYSCFG_CFGR1>>8&0x3,
	printf "0x4001_0000 0x0000_030b | rw | SYSCFG_CFGR1 (memory remap register).value (r=0x000X_000X): 0x%04x_%04x\n", $SYSCFG_CFGR1>>16&0xFFFF, $SYSCFG_CFGR1&0xFFFF,

	printf "0x4001_0004 0x0000_0001 | rw | SYSCFG_CFGR2 (peripheral mode register).FWDIS (firewall disable bit): %x\n", $SYSCFG_CFGR2&0x1,
	printf "0x4001_0004 0x0000_0f00 | rw | SYSCFG_CFGR2 (peripheral mode register).I2C_PBXFMP (PB9/8 PB8/4 PB7/2 PB6/1; Fm+ enable bitmask): %x\n", $SYSCFG_CFGR2>>8&0xf,
	printf "0x4001_0004 0x0000_7000 | rw | SYSCFG_CFGR2 (peripheral mode register).I2CX_FMP (I2C3/4 I2C2/2 I2C1/1; Fm+ enable bitmask): %x\n", $SYSCFG_CFGR2>>12&0xf,
	printf "0x4001_0004 0x0000_3f01 | rw | SYSCFG_CFGR2 (peripheral mode register).value (r=0x0000_0001): 0x%04x_%04x\n", $SYSCFG_CFGR2>>16&0xFFFF, $SYSCFG_CFGR2&0xFFFF,

	printf "0x4001_0008 0x0000_000f | rw | SYSCFG_EXTICR1 (external interrupt config register).EXTI0 (PH/5 PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR1&0xf,
	printf "0x4001_0008 0x0000_00f0 | rw | SYSCFG_EXTICR1 (external interrupt config register).EXTI1 (PH/5 PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR1>>4&0xf,
	printf "0x4001_0008 0x0000_0f00 | rw | SYSCFG_EXTICR1 (external interrupt config register).EXTI2 (PH/5 PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR1>>8&0xf,
	printf "0x4001_0008 0x0000_f000 | rw | SYSCFG_EXTICR1 (external interrupt config register).EXTI3 (PH/5 PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR1>>12&0xf,
	printf "0x4001_0008 0x0000_ffff | rw | SYSCFG_EXTICR1 (external interrupt config register).value (r=0x0000_0000): 0x%04x_%04x\n", $SYSCFG_EXTICR1>>16&0xFFFF, $SYSCFG_EXTICR1&0xFFFF,

	printf "0x4001_000c 0x0000_000f | rw | SYSCFG_EXTICR2 (external interrupt config register).EXTI4 (PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR2&0xf,
	printf "0x4001_000c 0x0000_00f0 | rw | SYSCFG_EXTICR2 (external interrupt config register).EXTI5 (PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR2>>4&0xf,
	printf "0x4001_000c 0x0000_0f00 | rw | SYSCFG_EXTICR2 (external interrupt config register).EXTI6 (PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR2>>8&0xf,
	printf "0x4001_000c 0x0000_f000 | rw | SYSCFG_EXTICR2 (external interrupt config register).EXTI7 (PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR2>>12&0xf,
	printf "0x4001_000c 0x0000_ffff | rw | SYSCFG_EXTICR2 (external interrupt config register).value (r=0x0000_0000): 0x%04x_%04x\n", $SYSCFG_EXTICR2>>16&0xFFFF, $SYSCFG_EXTICR2&0xFFFF,

	printf "0x4001_0010 0x0000_000f | rw | SYSCFG_EXTICR3 (external interrupt config register).EXTI8 (PH/5 PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR3&0xf,
	printf "0x4001_0010 0x0000_00f0 | rw | SYSCFG_EXTICR3 (external interrupt config register).EXTI9 (PH/5 PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR3>>4&0xf,
	printf "0x4001_0010 0x0000_0f00 | rw | SYSCFG_EXTICR3 (external interrupt config register).EXTI10 (PH/5 PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR3>>8&0xf,
	printf "0x4001_0010 0x0000_f000 | rw | SYSCFG_EXTICR3 (external interrupt config register).EXTI11 (PH/5 PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR3>>12&0xf,
	printf "0x4001_0010 0x0000_ffff | rw | SYSCFG_EXTICR3 (external interrupt config register).value (r=0x0000_0000): 0x%04x_%04x\n", $SYSCFG_EXTICR3>>16&0xFFFF, $SYSCFG_EXTICR3&0xFFFF,

	printf "0x4001_0014 0x0000_000f | rw | SYSCFG_EXTICR4 (external interrupt config register).EXTI12 (PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR4&0xf,
	printf "0x4001_0014 0x0000_00f0 | rw | SYSCFG_EXTICR4 (external interrupt config register).EXTI13 (PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR4>>4&0xf,
	printf "0x4001_0014 0x0000_0f00 | rw | SYSCFG_EXTICR4 (external interrupt config register).EXTI14 (PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR4>>8&0xf,
	printf "0x4001_0014 0x0000_f000 | rw | SYSCFG_EXTICR4 (external interrupt config register).EXTI15 (PE/4 PD/3 PC/2 PB/1 PA/0; external interrupt source pin select bit): %x\n", $SYSCFG_EXTICR4>>12&0xf,
	printf "0x4001_0014 0x0000_ffff | rw | SYSCFG_EXTICR4 (external interrupt config register).value (r=0x0000_0000): 0x%04x_%04x\n", $SYSCFG_EXTICR4>>16&0xFFFF, $SYSCFG_EXTICR4&0xFFFF,

	printf "0x4001_0020 0x0000_0001 | rw | SYSCFG_CFGR3 (reference control and status register).EN_VREFINT (VREFINT and COMP2 scaler enable bit): %x\n", $SYSCFG_CFGR3&0x1,
	printf "0x4001_0020 0x0000_0030 | rw | SYSCFG_CFGR3 (reference control and status register).SEL_VREF_OUT (PB1/2 PB0/1; VREFINT_ADC connect pin select bitmask): %x\n", $SYSCFG_CFGR3>>4&0x3,
	printf "0x4001_0020 0x0000_0100 | rw | SYSCFG_CFGR3 (reference control and status register).ENBUF_VREFINT_ADC (buffer generate VREFINT reference for ADC enable bit): %x\n", $SYSCFG_CFGR3>>8&0x1,
	printf "0x4001_0020 0x0000_0200 | rw | SYSCFG_CFGR3 (reference control and status register).ENBUF_SENSOR_ADC (buffer generate VREFINT reference for ADC temperature sensor enable bit): %x\n", $SYSCFG_CFGR3>>9&0x1,
	printf "0x4001_0020 0x0000_1000 | rw | SYSCFG_CFGR3 (reference control and status register).ENBUF_VREFINT_COMP2 (buffer generate VERFINT reference for COMP2 scaler enable bit): %x\n", $SYSCFG_CFGR3>>12&0x1,
	printf "0x4001_0020 0x4000_0000 | r  | SYSCFG_CFGR3 (reference control and status register).VREFINT_RDYF (internal voltage reference available for BOR, PVD status bit): %x\n", $SYSCFG_CFGR3>>30&0x1,
	printf "0x4001_0020 0x8000_0000 | rs1| SYSCFG_CFGR3 (reference control and status register).REF_LOCK (lock this register until reset, enable bit): %x\n", $SYSCFG_CFGR3>>31&0x1,
	printf "0x4001_0020 0xc000_1331 | rw | SYSCFG_CFGR3 (reference control and status register).value (r=0x0000_0000): 0x%04x_%04x\n", $SYSCFG_CFGR3>>16&0xFFFF, $SYSCFG_CFGR3&0xFFFF,

	printf "0x4001_04xx 0x0000_0001 |mux | _EXTI_GPIO0 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x1)>>0<<5 | ($EXTI_SWIER&0x1)>>0<<4 | ($EXTI_FTSR&0x1)>>0<<3 | ($EXTI_RTSR&0x1)>>0<<2 | ($EXTI_EMR&0x1)>>0<<1 | ($EXTI_IMR&0x1)>>0
	printf "0x4001_04xx 0x0000_0002 |mux | _EXTI_GPIO1 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x2)>>1<<5 | ($EXTI_SWIER&0x2)>>1<<4 | ($EXTI_FTSR&0x2)>>1<<3 | ($EXTI_RTSR&0x2)>>1<<2 | ($EXTI_EMR&0x2)>>1<<1 | ($EXTI_IMR&0x2)>>1
	printf "0x4001_04xx 0x0000_0004 |mux | _EXTI_GPIO2 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x4)>>2<<5 | ($EXTI_SWIER&0x4)>>2<<4 | ($EXTI_FTSR&0x4)>>2<<3 | ($EXTI_RTSR&0x4)>>2<<2 | ($EXTI_EMR&0x4)>>2<<1 | ($EXTI_IMR&0x4)>>2
	printf "0x4001_04xx 0x0000_0008 |mux | _EXTI_GPIO3 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x8)>>3<<5 | ($EXTI_SWIER&0x8)>>3<<4 | ($EXTI_FTSR&0x8)>>3<<3 | ($EXTI_RTSR&0x8)>>3<<2 | ($EXTI_EMR&0x8)>>3<<1 | ($EXTI_IMR&0x8)>>3
	printf "0x4001_04xx 0x0000_0010 |mux | _EXTI_GPIO4 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x10)>>4<<5 | ($EXTI_SWIER&0x10)>>4<<4 | ($EXTI_FTSR&0x10)>>4<<3 | ($EXTI_RTSR&0x10)>>4<<2 | ($EXTI_EMR&0x10)>>4<<1 | ($EXTI_IMR&0x10)>>4
	printf "0x4001_04xx 0x0000_0020 |mux | _EXTI_GPIO5 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x20)>>5<<5 | ($EXTI_SWIER&0x20)>>5<<4 | ($EXTI_FTSR&0x20)>>5<<3 | ($EXTI_RTSR&0x20)>>5<<2 | ($EXTI_EMR&0x20)>>5<<1 | ($EXTI_IMR&0x20)>>5
	printf "0x4001_04xx 0x0000_0040 |mux | _EXTI_GPIO6 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x40)>>6<<5 | ($EXTI_SWIER&0x40)>>6<<4 | ($EXTI_FTSR&0x40)>>6<<3 | ($EXTI_RTSR&0x40)>>6<<2 | ($EXTI_EMR&0x40)>>6<<1 | ($EXTI_IMR&0x40)>>6
	printf "0x4001_04xx 0x0000_0080 |mux | _EXTI_GPIO7 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x80)>>7<<5 | ($EXTI_SWIER&0x80)>>7<<4 | ($EXTI_FTSR&0x80)>>7<<3 | ($EXTI_RTSR&0x80)>>7<<2 | ($EXTI_EMR&0x80)>>7<<1 | ($EXTI_IMR&0x80)>>7
	printf "0x4001_04xx 0x0000_0100 |mux | _EXTI_GPIO8 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x100)>>8<<5 | ($EXTI_SWIER&0x100)>>8<<4 | ($EXTI_FTSR&0x100)>>8<<3 | ($EXTI_RTSR&0x100)>>8<<2 | ($EXTI_EMR&0x100)>>8<<1 | ($EXTI_IMR&0x100)>>8
	printf "0x4001_04xx 0x0000_0200 |mux | _EXTI_GPIO9 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x200)>>9<<5 | ($EXTI_SWIER&0x200)>>9<<4 | ($EXTI_FTSR&0x200)>>9<<3 | ($EXTI_RTSR&0x200)>>9<<2 | ($EXTI_EMR&0x200)>>9<<1 | ($EXTI_IMR&0x200)>>9
	printf "0x4001_04xx 0x0000_0400 |mux | _EXTI_GPIO10 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x400)>>10<<5 | ($EXTI_SWIER&0x400)>>10<<4 | ($EXTI_FTSR&0x400)>>10<<3 | ($EXTI_RTSR&0x400)>>10<<2 | ($EXTI_EMR&0x400)>>10<<1 | ($EXTI_IMR&0x400)>>10
	printf "0x4001_04xx 0x0000_0800 |mux | _EXTI_GPIO11 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x800)>>11<<5 | ($EXTI_SWIER&0x800)>>11<<4 | ($EXTI_FTSR&0x800)>>11<<3 | ($EXTI_RTSR&0x800)>>11<<2 | ($EXTI_EMR&0x800)>>11<<1 | ($EXTI_IMR&0x800)>>11
	printf "0x4001_04xx 0x0000_1000 |mux | _EXTI_GPIO12 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x1000)>>12<<5 | ($EXTI_SWIER&0x1000)>>12<<4 | ($EXTI_FTSR&0x1000)>>12<<3 | ($EXTI_RTSR&0x1000)>>12<<2 | ($EXTI_EMR&0x1000)>>12<<1 | ($EXTI_IMR&0x1000)>>12
	printf "0x4001_04xx 0x0000_2000 |mux | _EXTI_GPIO13 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x2000)>>13<<5 | ($EXTI_SWIER&0x2000)>>13<<4 | ($EXTI_FTSR&0x2000)>>13<<3 | ($EXTI_RTSR&0x2000)>>13<<2 | ($EXTI_EMR&0x2000)>>13<<1 | ($EXTI_IMR&0x2000)>>13
	printf "0x4001_04xx 0x0000_4000 |mux | _EXTI_GPIO14 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x4000)>>14<<5 | ($EXTI_SWIER&0x4000)>>14<<4 | ($EXTI_FTSR&0x4000)>>14<<3 | ($EXTI_RTSR&0x4000)>>14<<2 | ($EXTI_EMR&0x4000)>>14<<1 | ($EXTI_IMR&0x4000)>>14
	printf "0x4001_04xx 0x0000_8000 |mux | _EXTI_GPIO15 (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x8000)>>15<<5 | ($EXTI_SWIER&0x8000)>>15<<4 | ($EXTI_FTSR&0x8000)>>15<<3 | ($EXTI_RTSR&0x8000)>>15<<2 | ($EXTI_EMR&0x8000)>>15<<1 | ($EXTI_IMR&0x8000)>>15
	printf "0x4001_04xx 0x0001_0000 |mux | _EXTI_PVD (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x10000)>>16<<5 | ($EXTI_SWIER&0x10000)>>16<<4 | ($EXTI_FTSR&0x10000)>>16<<3 | ($EXTI_RTSR&0x10000)>>16<<2 | ($EXTI_EMR&0x10000)>>16<<1 | ($EXTI_IMR&0x10000)>>16
	printf "0x4001_04xx 0x0002_0000 |mux | _EXTI_RTCalarm (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x20000)>>17<<5 | ($EXTI_SWIER&0x20000)>>17<<4 | ($EXTI_FTSR&0x20000)>>17<<3 | ($EXTI_RTSR&0x20000)>>17<<2 | ($EXTI_EMR&0x20000)>>17<<1 | ($EXTI_IMR&0x20000)>>17
	printf "0x4001_04xx 0x0008_0000 |mux | _EXTI_RTC{timer,timestamp,CSS_LSE} (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x80000)>>19<<5 | ($EXTI_SWIER&0x80000)>>19<<4 | ($EXTI_FTSR&0x80000)>>19<<3 | ($EXTI_RTSR&0x80000)>>19<<2 | ($EXTI_EMR&0x80000)>>19<<1 | ($EXTI_IMR&0x80000)>>19
	printf "0x4001_04xx 0x0010_0000 |mux | _EXTI_RTCwakeup (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x100000)>>20<<5 | ($EXTI_SWIER&0x100000)>>20<<4 | ($EXTI_FTSR&0x100000)>>20<<3 | ($EXTI_RTSR&0x100000)>>20<<2 | ($EXTI_EMR&0x100000)>>20<<1 | ($EXTI_IMR&0x100000)>>20
	printf "0x4001_04xx 0x0020_0000 |mux | _EXTI_COMP1out (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x200000)>>21<<5 | ($EXTI_SWIER&0x200000)>>21<<4 | ($EXTI_FTSR&0x200000)>>21<<3 | ($EXTI_RTSR&0x200000)>>21<<2 | ($EXTI_EMR&0x200000)>>21<<1 | ($EXTI_IMR&0x200000)>>21
	printf "0x4001_04xx 0x0040_0000 |mux | _EXTI_COMP2out (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x400000)>>22<<5 | ($EXTI_SWIER&0x400000)>>22<<4 | ($EXTI_FTSR&0x400000)>>22<<3 | ($EXTI_RTSR&0x400000)>>22<<2 | ($EXTI_EMR&0x400000)>>22<<1 | ($EXTI_IMR&0x400000)>>22
	printf "0x4001_04xx 0x0080_0000 |mux | _EXTI_I2C1wakeup (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x800000)>>23<<5 | ($EXTI_SWIER&0x800000)>>23<<4 | ($EXTI_FTSR&0x800000)>>23<<3 | ($EXTI_RTSR&0x800000)>>23<<2 | ($EXTI_EMR&0x800000)>>23<<1 | ($EXTI_IMR&0x800000)>>23
	printf "0x4001_04xx 0x0100_0000 |mux | _EXTI_I2C3wakeup (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x1000000)>>24<<5 | ($EXTI_SWIER&0x1000000)>>24<<4 | ($EXTI_FTSR&0x1000000)>>24<<3 | ($EXTI_RTSR&0x1000000)>>24<<2 | ($EXTI_EMR&0x1000000)>>24<<1 | ($EXTI_IMR&0x1000000)>>24
	printf "0x4001_04xx 0x0200_0000 |mux | _EXTI_USART1wakeup (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x2000000)>>25<<5 | ($EXTI_SWIER&0x2000000)>>25<<4 | ($EXTI_FTSR&0x2000000)>>25<<3 | ($EXTI_RTSR&0x2000000)>>25<<2 | ($EXTI_EMR&0x2000000)>>25<<1 | ($EXTI_IMR&0x2000000)>>25
	printf "0x4001_04xx 0x0400_0000 |mux | _EXTI_USART2wakeup (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x4000000)>>26<<5 | ($EXTI_SWIER&0x4000000)>>26<<4 | ($EXTI_FTSR&0x4000000)>>26<<3 | ($EXTI_RTSR&0x4000000)>>26<<2 | ($EXTI_EMR&0x4000000)>>26<<1 | ($EXTI_IMR&0x4000000)>>26
	printf "0x4001_04xx 0x1000_0000 |mux | _EXTI_LPUART1wakeup (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x10000000)>>28<<5 | ($EXTI_SWIER&0x10000000)>>28<<4 | ($EXTI_FTSR&0x10000000)>>28<<3 | ($EXTI_RTSR&0x10000000)>>28<<2 | ($EXTI_EMR&0x10000000)>>28<<1 | ($EXTI_IMR&0x10000000)>>28
	printf "0x4001_04xx 0x2000_0000 |mux | _EXTI_LPTIM1wakeup (PR, SWIER, FTSR, RTSR, EMR, IMR 6 bits): %02x\n", ($EXTI_PR&0x20000000)>>29<<5 | ($EXTI_SWIER&0x20000000)>>29<<4 | ($EXTI_FTSR&0x20000000)>>29<<3 | ($EXTI_RTSR&0x20000000)>>29<<2 | ($EXTI_EMR&0x20000000)>>29<<1 | ($EXTI_IMR&0x20000000)>>29
	printf "0x4001_0400 0x37fb_ffff | rw | EXTI_IMR (interrupt mask register).IM (1/0 irq request un/masked bit): 0x%04x_%04x\n", $EXTI_IMR>>16&0x37fb, $EXTI_IMR&0xFFFF
	printf "0x4001_0400 0x37fb_ffff | rw | EXTI_IMR (interrupt mask register).value (r=0x3F84_0000): 0x%04x_%04x\n", $EXTI_IMR>>16&0xFFFF, $EXTI_IMR&0xFFFF
	printf "0x4001_0404 0x37fb_ffff | rw | EXTI_EMR (event mask register).EM (1/0 event request un/masked bit): 0x%04x_%04x\n", $EXTI_EMR>>16&0x37ff, $EXTI_EMR&0xFFFF
	printf "0x4001_0404 0x37fb_ffff | rw | EXTI_EMR (event mask register).value (r=0x0000_0000): 0x%04x_%04x\n", $EXTI_EMR>>16&0xFFFF, $EXTI_EMR&0xFFFF
	printf "0x4001_0408 0x007b_ffff | rw | EXTI_RTSR (rising edge trigger selection register).RT (rising trigger enabled bits): 0x%04x_%04x\n", $EXTI_RTSR>>16&0x007B, $EXTI_RTSR&0xFFFF
	printf "0x4001_0408 0x007b_ffff | rw | EXTI_RTSR (rising edge trigger selection register).value (r=0x0000_0000): 0x%04x_%04x\n", $EXTI_RTSR>>16&0xFFFF, $EXTI_RTSR&0xFFFF
	printf "0x4001_040c 0x007b_ffff | rw | EXTI_FTSR (falling edge trigger selection register).FT (falling trigger enabled bits): 0x%04x_%04x\n", $EXTI_FTSR>>16&0x007B, $EXTI_FTSR&0xFFFF
	printf "0x4001_040c 0x007b_ffff | rw | EXTI_FTSR (falling edge trigger selection register).value (r=0x0000_0000): 0x%04x_%04x\n", $EXTI_FTSR>>16&0xFFFF, $EXTI_FTSR&0xFFFF
	printf "0x4001_0410 0x007b_ffff | rw | EXTI_SWIER (software interrupt event register).SWI (0->1 to generate irq req; software interrupt bits): 0x%04x_%04x\n", $EXTI_SWIER>>16&0x007B, $EXTI_SWIER&0xFFFF
	printf "0x4001_0410 0x007b_ffff | rw | EXTI_SWIER (software interrupt event register).value (r=0x0000_0000): 0x%04x_%04x\n", $EXTI_SWIER>>16&0xFFFF, $EXTI_SWIER&0xFFFF
	printf "0x4001_0414 0x007b_ffff | rc1| EXTI_PR (pending register).PIF (1 if edge event on irq line; pending interrupt flag): 0x%04x_%04x\n", $EXTI_PR>>16&0x00FB, $EXTI_PR&0xFFFF
	printf "0x4001_0414 0x007b_ffff | rc1| EXTI_PR (pending register).value (r=0xXXXX_XXXX): 0x%04x_%04x\n", $EXTI_PR>>16&0xFFFF, $EXTI_PR&0xFFFF


	printf "0x4002_1000 0x0000_0001 | rw | RCC_CR (clock control register).HSI16ON (16MHz High Speed Internal clock enable bit): %x\n", $RCC_CR&0x1
	printf "0x4002_1000 0x0000_0002 | rw | RCC_CR (clock control register).HSI16KERON (retain HSI16 in STOP MODE (for IP kernels, like USARTs, I2C1) enable bit): %x\n", $RCC_CR>>1&0x1
	printf "0x4002_1000 0x0000_0004 | r  | RCC_CR (clock control register).HSI16RDYF (HSI16 oscillator is stable bit): %x\n", $RCC_CR>>2&0x1
	printf "0x4002_1000 0x0000_0008 | rw | RCC_CR (clock control register).HSI16DIVEN (HSI16 division by 4 enable bit): %x\n", $RCC_CR>>3&0x1
	printf "0x4002_1000 0x0000_0010 | r  | RCC_CR (clock control register).HSI16DIVF (HSI16 is currently divided by 4 flag): %x\n", $RCC_CR>>4&0x1
	printf "0x4002_1000 0x0000_0020 | rw | RCC_CR (clock control register).HSI16OUTEN (HSI16 output enable bit): %x\n", $RCC_CR>>5&0x1
	printf "0x4002_1000 0x0000_0100 | rw | RCC_CR (clock control register).MSION (Multi-Speed Internal clock enable bit): %x\n", $RCC_CR>>8&0x1
	printf "0x4002_1000 0x0000_0200 | r  | RCC_CR (clock control register).MSIRDY (MSI oscillator is stable bit): %x\n", $RCC_CR>>8&0x1
	printf "0x4002_1000 0x0001_0000 | rw | RCC_CR (clock control register).HSEON (High-Speed External clock enable bit): %x\n", $RCC_CR>>16&0x1
	printf "0x4002_1000 0x0002_0000 | r  | RCC_CR (clock control register).HSERDY (HSE oscillator is stable bit): %x\n", $RCC_CR>>17&0x1
	printf "0x4002_1000 0x0004_0000 | rw | RCC_CR (clock control register).HSEBYP (use an external clock instead of an oscillator; HSE bypass bit): %x\n", $RCC_CR>>18&0x1
	printf "0x4002_1000 0x0008_0000 | rw | RCC_CR (clock control register).CSSHSEON (enables clock detector while HSERDY==1; Clock Security System on HSE enable bit): %x\n", $RCC_CR>>19&0x1
	printf "0x4002_1000 0x0030_0000 | rw | RCC_CR (clock control register).RTCPRE (HSE is divided by 2/4/8/16 for RTC clock; RTC prescaler bitfield): %x\n", $RCC_CR>>20&0x3
	printf "0x4002_1000 0x0100_0000 | rw | RCC_CR (clock control register).PLLON (Phase Locked Loop enable bit): %x\n", $RCC_CR>>24&0x1
	printf "0x4002_1000 0x0200_0000 | r  | RCC_CR (clock control register).PLLRDY (PLL is locked flag): %x\n", $RCC_CR>>25&0x1
	printf "0x4002_1000 0x033f_033f | rw | RCC_CR (clock control register).value (r=0x00{XX}{0X00}_0300): 0x%04x_%04x\n", $RCC_CR>>16&0xFFFF, $RCC_CR&0xFFFF

	printf "0x4002_1004 0x0000_00ff | r  | RCC_ICSCR (internal clock sources calibration register).HSI16CAL (HSI16 factory calibration value bits): %02x\n", $RCC_ICSCR&0xFF
	printf "0x4002_1004 0x0000_1f00 | rw | RCC_ICSCR (internal clock sources calibration register).HSI16TRIM (compensate variations due to volts or temps; HSI16 clock trimming bitfield): %02x\n", $RCC_ICSCR>>8&0x1F
	printf "0x4002_1004 0x0000_e000 | rw | RCC_ICSCR (internal clock sources calibration register).MSIRANGE (0..6 65.536/131.072/262.144/524.288 kHz, 1.048/2.097/4.194 MHz; 2^16*(2^.) Hz; MSI clock ranges bits): %x\n", $RCC_ICSCR>>13&0x7
	printf "0x4002_1004 0x00ff_0000 | r  | RCC_ICSCR (internal clock sources calibration register).MSICAL (MSI factory calibration value bits): %x\n", $RCC_ICSCR>>16&0xFF
	printf "0x4002_1004 0xff00_0000 | rw | RCC_ICSCR (internal clock sources calibration register).MSITRIM (compensate variations due to volts or temps; MSI clock trimming bits): %x\n", $RCC_ICSCR>>24&0xFF
	printf "0x4002_1004 0xffff_ffff |    | RCC_ICSCR (internal clock sources calibration register).value (r=0x00XX_b0XX): 0x%04x_%04x\n", $RCC_ICSCR>>16&0xFFFF, $RCC_ICSCR&0xFFFF

	printf "0x4002_100c 0x0000_0003 | rw | RCC_CFGR (clock configuration register).SW (switch to MSI/0 HSI16/1 HSE/2 PLL/3 as System clock bitfield): %x\n", $RCC_CFGR&0x3
	printf "0x4002_100c 0x0000_000c | r  | RCC_CFGR (clock configuration register).SWS (now MSI/0 HSI16/1 HSE/2 PLL/3 is System clock status): %x\n", $RCC_CFGR>>2&0x3
	printf "0x4002_100c 0x0000_00f0 | rw | RCC_CFGR (clock configuration register).HPRE (nodiv/0..7 div by 2,4,8,16,64,128,256,512/8..f; AHB prescaler bitfiled): %x\n", $RCC_CFGR>>4&0xf
	printf "0x4002_100c 0x0000_0700 | rw | RCC_CFGR (clock configuration register).PPRE1 (HCLK nodiv/0..3 div by 2,4,8,16/4..7; APB low-speed prescaler bitfield): %x\n", $RCC_CFGR>>8&0x7
	printf "0x4002_100c 0x0000_3800 | rw | RCC_CFGR (clock configuration register).PPRE2 (HCLK nodiv/0..3 div by 2,4,8,16/4..7; APB high-speed prescaler bitfield): %x\n", $RCC_CFGR>>11&0x7
	printf "0x4002_100c 0x0000_8000 | rw | RCC_CFGR (clock configuration register).STOPWUCK (use MSI/0 HSI16/1 after Wake-Up from Stop clock selection bit): %x\n", $RCC_CFGR>>15&0x1
	printf "0x4002_100c 0x0001_0000 | rw | RCC_CFGR (clock configuration register).PLLSRC (use HSI16/0 HSE/1 as PLL clock source bit): %x\n", $RCC_CFGR>>16&0x1
	printf "0x4002_100c 0x003c_0000 | rw | RCC_CFGR (clock configuration register).PLLMUL (PLLVCO = PLLsrc times 3,4,6,8,12,16,24,32,48/0..8 res/9..f; PLL multiplication factor bitfield): %x\n", $RCC_CFGR>>18&0xf
	printf "0x4002_100c 0x00c0_0000 | rw | RCC_CFGR (clock configuration register).PLLDIV (PLLout = PLLVCO / 2,3,4/1..3 res/0; PLL output division bits): %x\n", $RCC_CFGR>>22&0x3
	printf "0x4002_100c 0x0f00_0000 | rw | RCC_CFGR (clock configuration register).MCOSEL (disabled/0 SYSCLK/1 HSI16/2 MSI/3 HSE/4 PLL/5 LSI/6 LSE/7 res/8..f; MCU Clock Output selection bitfield): %x\n", $RCC_CFGR>>24&0xf
	printf "0x4002_100c 0x7000_0000 | rw | RCC_CFGR (clock configuration register).MCOPRE (MCO div by 1,2,4,8,16/0..4 tabu/5..7): %x\n", $RCC_CFGR>>28&0x7
	printf "0x4002_100c 0x77fd_bfff | rw | RCC_CFGR (clock configuration register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_CFGR>>16&0xFFFF, $RCC_CFGR&0xFFFF

	printf "0x4002_1010 0x0000_0001 | r  | RCC_CIER (clock interrupt enabled register).LSIRDYIE (LSI ready interrupt enabled flag): %x\n", $RCC_CIER&0x1
	printf "0x4002_1010 0x0000_0002 | r  | RCC_CIER (clock interrupt enabled register).LSERDYIE (LSE ready interrupt enabled flag): %x\n", $RCC_CIER>>1&0x1
	printf "0x4002_1010 0x0000_0004 | r  | RCC_CIER (clock interrupt enabled register).HSI16RDYIE (HSI16 ready interrupt enabled flag): %x\n", $RCC_CIER>>2&0x1
	printf "0x4002_1010 0x0000_0008 | r  | RCC_CIER (clock interrupt enabled register).HSERDYIE (HSE ready interrupt enabled flag): %x\n", $RCC_CIER>>3&0x1
	printf "0x4002_1010 0x0000_0010 | r  | RCC_CIER (clock interrupt enabled register).PLLRDYIE (PLL ready interrupt enabled flag): %x\n", $RCC_CIER>>4&0x1
	printf "0x4002_1010 0x0000_0020 | r  | RCC_CIER (clock interrupt enabled register).MSIRDYIE (MSI ready interrupt enabled flag): %x\n", $RCC_CIER>>5&0x1
	printf "0x4002_1010 0x0000_0080 | r  | RCC_CIER (clock interrupt enabled register).CSSLSE (LSE CSS interrupt enabled flag): %x\n", $RCC_CIER>>6&0x1
	printf "0x4002_1010 0x0000_00bf | r  | RCC_CIER (clock interrupt enabled register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_CIER>>16&0xFFFF, $RCC_CIER&0xFFFF

	printf "0x4002_1014 0x0000_0001 | r  | RCC_CIFR (clock interrupt flag register).LSIRDYF (LSIRDYIE==1; LSI clock became stable after failure status flag): %x\n", $RCC_CIFR&0x1
	printf "0x4002_1014 0x0000_0002 | r  | RCC_CIFR (clock interrupt flag register).LSERDYF (LSERDYIE==1; LSE clock became stable after failure status flag): %x\n", $RCC_CIFR>>1&0x1
	printf "0x4002_1014 0x0000_0004 | r  | RCC_CIFR (clock interrupt flag register).HSI16RDYF (HSI16RDYIE==1; HSI16 clock became stable after failure status flag): %x\n", $RCC_CIFR>>2&0x1
	printf "0x4002_1014 0x0000_0008 | r  | RCC_CIFR (clock interrupt flag register).HSERDYF (HSERDYIE==1; HSE clock became stable after failure status flag): %x\n", $RCC_CIFR>>3&0x1
	printf "0x4002_1014 0x0000_0010 | r  | RCC_CIFR (clock interrupt flag register).PLLRDYF (PLLRDYIE==1; PLL clock became stable after failure status flag): %x\n", $RCC_CIFR>>4&0x1
	printf "0x4002_1014 0x0000_0020 | r  | RCC_CIFR (clock interrupt flag register).MSIRDYF (MSIRDYIE==1; MSI clock became stable after failure status flag): %x\n", $RCC_CIFR>>5&0x1
	printf "0x4002_1014 0x0000_0080 | r  | RCC_CIFR (clock interrupt flag register).CSSLSEF (CSSLSE==1; LSE clock failure detected status flag): %x\n", $RCC_CIFR>>7&0x1
	printf "0x4002_1014 0x0000_0100 | r  | RCC_CIFR (clock interrupt flag register).CSSHSEF (CSS HSE clock failure detected status flag): %x\n", $RCC_CIFR>>8&0x1
	printf "0x4002_1014 0x0000_01bf | r  | RCC_CIFR (clock interrupt flag register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_CIFR>>16&0xFFFF, $RCC_CIFR&0xFFFF

	printf "0x4002_1018 0x0000_01bf |  w | RCC_CICR (clock interrupt clear register).value (r=0x0000_0000; ditto RC_CIFR): N/A\n"

	printf "0x4002_101c 0x0000_0001 | rw | RCC_IOPRSTR (GPIO reset register).IOPARST (I/O port A reset bit): %x\n", $RCC_IOPRSTR&0x1
	printf "0x4002_101c 0x0000_0002 | rw | RCC_IOPRSTR (GPIO reset register).IOPBRST (I/O port B reset bit): %x\n", $RCC_IOPRSTR>>1&0x1
	printf "0x4002_101c 0x0000_0004 | rw | RCC_IOPRSTR (GPIO reset register).IOPCRST (I/O port C reset bit): %x\n", $RCC_IOPRSTR>>2&0x1
	printf "0x4002_101c 0x0000_0008 | rw | RCC_IOPRSTR (GPIO reset register).IOPDRST (I/O port D reset bit): %x\n", $RCC_IOPRSTR>>3&0x1
	printf "0x4002_101c 0x0000_0010 | rw | RCC_IOPRSTR (GPIO reset register).IOPERST (I/O port E reset bit): %x\n", $RCC_IOPRSTR>>4&0x1
	printf "0x4002_101c 0x0000_0080 | rw | RCC_IOPRSTR (GPIO reset register).IOPHRST (I/O port H reset bit): %x\n", $RCC_IOPRSTR>>7&0x1
	printf "0x4002_101c 0x0000_009f | rw | RCC_IOPRSTR (GPIO reset register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_IOPRSTR>>16&0xFFFF, $RCC_IOPRSTR&0xFFFF

	printf "0x4002_1020 0x0000_0001 | rw | RCC_AHBRSTR (AHB peripheral reset register).DMARST (Direct Memory Access reset bit): %x\n", $RCC_AHBRSTR&0x1
	printf "0x4002_1020 0x0000_0100 | rw | RCC_AHBRSTR (AHB peripheral reset register).MIFRST (NVM Interface reset bit): %x\n", $RCC_AHBRSTR>>8&0x1
	printf "0x4002_1020 0x0000_1000 | rw | RCC_AHBRSTR (AHB peripheral reset register).CRCRST (test integration module reset bit): %x\n", $RCC_AHBRSTR>>12&0x1
	printf "0x4002_1020 0x0100_0000 | rw | RCC_AHBRSTR (AHB peripheral reset register).CRYPTRST (crypto module reset bit): %x\n", $RCC_AHBRSTR>>24&0x1
	printf "0x4002_1020 0x0100_1101 | rw | RCC_AHBRSTR (AHB peripheral reset register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_AHBRSTR>>16&0xFFFF, $RCC_AHBRSTR&0xFFFF

	printf "0x4002_1024 0x0000_0001 | rw | RCC_APB2RSTR (APB2 peripheral reset register).SYSCFGRST (System configuration controller reset): %x\n", $RCC_APB2RSTR&0x1
	printf "0x4002_1024 0x0000_0004 | rw | RCC_APB2RSTR (APB2 peripheral reset register).TIM21RST (TIM21 timer reset bit): %x\n", $RCC_APB2RSTR>>2&0x1
	printf "0x4002_1024 0x0000_0020 | rw | RCC_APB2RSTR (APB2 peripheral reset register).TIM22RST (TIM22 timer reset bit): %x\n", $RCC_APB2RSTR>>5&0x1
	printf "0x4002_1024 0x0000_0200 | rw | RCC_APB2RSTR (APB2 peripheral reset register).ADCRST (ADC interface reset bit): %x\n", $RCC_APB2RSTR>>9&0x1
	printf "0x4002_1024 0x0000_1000 | rw | RCC_APB2RSTR (APB2 peripheral reset register).SPI1RST (SPI1 reset bit): %x\n", $RCC_APB2RSTR>>12&0x1
	printf "0x4002_1024 0x0000_4000 | rw | RCC_APB2RSTR (APB2 peripheral reset register).USART1RST (USART1 reset bit): %x\n", $RCC_APB2RSTR>>14&0x1
	printf "0x4002_1024 0x0040_0000 | rw | RCC_APB2RSTR (APB2 peripheral reset register).DBGRST (DBG reset bit): %x\n", $RCC_APB2RSTR>>22&0x1
	printf "0x4002_1024 0x0040_5225 | rw | RCC_APB2RSTR (APB2 peripheral reset register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_APB2RSTR>>16&0xFFFF, $RCC_APB2RSTR&0xFFFF

	printf "0x4002_1028 0x0000_0001 | rw | RCC_APB1RSTR (APB1 peripheral reset register).TIM2RST (TIM2 reset bit): %x\n", $RCC_APB1RSTR&0x1
	printf "0x4002_1028 0x0000_0002 | rw | RCC_APB1RSTR (APB1 peripheral reset register).TIM3RST (TIM3 reset bit): %x\n", $RCC_APB1RSTR>>1&0x1
	printf "0x4002_1028 0x0000_0010 | rw | RCC_APB1RSTR (APB1 peripheral reset register).TIM6RST (TIM6 reset bit): %x\n", $RCC_APB1RSTR>>4&0x1
	printf "0x4002_1028 0x0000_0020 | rw | RCC_APB1RSTR (APB1 peripheral reset register).TIM7RST (TIM7 reset bit): %x\n", $RCC_APB1RSTR>>5&0x1
	printf "0x4002_1028 0x0000_0800 | rw | RCC_APB1RSTR (APB1 peripheral reset register).WWDGRST (window watchdog reset bit): %x\n", $RCC_APB1RSTR>>11&0x1
	printf "0x4002_1028 0x0000_4000 | rw | RCC_APB1RSTR (APB1 peripheral reset register).SPI2RST (SPI2 reset bit): %x\n", $RCC_APB1RSTR>>14&0x1
	printf "0x4002_1028 0x0002_0000 | rw | RCC_APB1RSTR (APB1 peripheral reset register).USART2RST (USART2 reset bit): %x\n", $RCC_APB1RSTR>>17&0x1
	printf "0x4002_1028 0x0004_0000 | rw | RCC_APB1RSTR (APB1 peripheral reset register).LPUART1RST (LPUART1 reset bit): %x\n", $RCC_APB1RSTR>>18&0x1
	printf "0x4002_1028 0x0008_0000 | rw | RCC_APB1RSTR (APB1 peripheral reset register).USART4RST (USART4 reset bit): %x\n", $RCC_APB1RSTR>>19&0x1
	printf "0x4002_1028 0x0010_0000 | rw | RCC_APB1RSTR (APB1 peripheral reset register).USART5RST (USART5 reset bit): %x\n", $RCC_APB1RSTR>>20&0x1
	printf "0x4002_1028 0x0020_0000 | rw | RCC_APB1RSTR (APB1 peripheral reset register).I2C1RST (I2C1 reset bit): %x\n", $RCC_APB1RSTR>>21&0x1
	printf "0x4002_1028 0x0040_0000 | rw | RCC_APB1RSTR (APB1 peripheral reset register).I2C2RST (I2C2 reset bit): %x\n", $RCC_APB1RSTR>>22&0x1
	printf "0x4002_1028 0x1000_0000 | rw | RCC_APB1RSTR (APB1 peripheral reset register).PWRRST (power interface reset bit): %x\n", $RCC_APB1RSTR>>28&0x1
	printf "0x4002_1028 0x4000_0000 | rw | RCC_APB1RSTR (APB1 peripheral reset register).I2C3RST (I2C3 reset bit): %x\n", $RCC_APB1RSTR>>30&0x1
	printf "0x4002_1028 0x8000_0000 | rw | RCC_APB1RSTR (APB1 peripheral reset register).LPTIM1RST (Low-Power Timer reset bit): %x\n", $RCC_APB1RSTR>>31&0x1
	printf "0x4002_1028 0xd07e_4833 | rw | RCC_APB1RSTR (APB1 peripheral reset register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_APB1RSTR>>16&0xFFFF, $RCC_APB1RSTR&0xFFFF

	printf "0x4002_102c 0x0000_0001 | rw | RCC_IOPENR (GPIO clock enable register).IOPAEN (IO Port A clock enable bit): %x\n", $RCC_IOPENR&0x1
	printf "0x4002_102c 0x0000_0002 | rw | RCC_IOPENR (GPIO clock enable register).IOPBEN (IO Port B clock enable bit): %x\n", $RCC_IOPENR>>1&0x1
	printf "0x4002_102c 0x0000_0004 | rw | RCC_IOPENR (GPIO clock enable register).IOPCEN (IO Port C clock enable bit): %x\n", $RCC_IOPENR>>2&0x1
	printf "0x4002_102c 0x0000_0008 | rw | RCC_IOPENR (GPIO clock enable register).IOPDEN (IO Port D clock enable bit): %x\n", $RCC_IOPENR>>3&0x1
	printf "0x4002_102c 0x0000_0010 | rw | RCC_IOPENR (GPIO clock enable register).IOPEEN (IO Port E clock enable bit): %x\n", $RCC_IOPENR>>4&0x1
	printf "0x4002_102c 0x0000_0080 | rw | RCC_IOPENR (GPIO clock enable register).IOPHEN (IO Port H clock enable bit): %x\n", $RCC_IOPENR>>7&0x1
	printf "0x4002_102c 0x0000_009f | rw | RCC_IOPENR (GPIO clock enable register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_IOPENR>>16&0xFFFF, $RCC_IOPENR>>1&0xFFFF

	printf "0x4002_1030 0x0000_0001 | rw | RCC_AHBENR (AHB peripheral clock enable register).DMAEN (DMA clock enable bit): %x\n", $RCC_AHBENR&0x1
	printf "0x4002_1030 0x0000_0100 | rw | RCC_AHBENR (AHB peripheral clock enable register).MIFEN (NVM interface clock enable bit): %x\n", $RCC_AHBENR>>8&0x1
	printf "0x4002_1030 0x0000_1000 | rw | RCC_AHBENR (AHB peripheral clock enable register).CRCEN (test integration module clock enable bit): %x\n", $RCC_AHBENR>>12&0x1
	printf "0x4002_1030 0x0100_0000 | rw | RCC_AHBENR (AHB peripheral clock enable register).CRYPEN (crypto clock enable bit): %x\n", $RCC_AHBENR>>24&0x1
	printf "0x4002_1030 0x0100_1101 | rw | RCC_AHBENR (AHB peripheral clock enable register).value (r=0x0000_0100): 0x%04x_%04x\n", $RCC_AHBENR>>16&0xFFFF, $RCC_AHBENR&0xFFFF

	printf "0x4002_1034 0x0000_0001 | rw | RCC_APB2ENR (APB2 peripheral clock enable register).SYSCFGEN (system configuration controller clock enable bit): %x\n", $RCC_APB2ENR&0x1
	printf "0x4002_1034 0x0000_0004 | rw | RCC_APB2ENR (APB2 peripheral clock enable register).TIM21EN (TIM21 timer clock enable bit): %x\n", $RCC_APB2ENR>>2&0x1
	printf "0x4002_1034 0x0000_0020 | rw | RCC_APB2ENR (APB2 peripheral clock enable register).TIM22EN (TIM22 timer clock enable bit): %x\n", $RCC_APB2ENR>>5&0x1
	printf "0x4002_1034 0x0000_0080 | rs | RCC_APB2ENR (APB2 peripheral clock enable register).FWEN (firewall clock enable bit): %x\n", $RCC_APB2ENR>>7&0x1
	printf "0x4002_1034 0x0000_0200 | rw | RCC_APB2ENR (APB2 peripheral clock enable register).ADCEN (ADC clock enable bit): %x\n", $RCC_APB2ENR>>9&0x1
	printf "0x4002_1034 0x0000_1000 | rw | RCC_APB2ENR (APB2 peripheral clock enable register).SPI1EN (SPI1 clock enable bit): %x\n", $RCC_APB2ENR>>12&0x1
	printf "0x4002_1034 0x0000_4000 | rw | RCC_APB2ENR (APB2 peripheral clock enable register).USART1EN (USART1 clock enable bit): %x\n", $RCC_APB2ENR>>14&0x1
	printf "0x4002_1034 0x0040_0000 | rw | RCC_APB2ENR (APB2 peripheral clock enable register).DBGEN (DBG clock enable bit): %x\n", $RCC_APB2ENR>>22&0x1
	printf "0x4002_1034 0x0040_52a5 | rw | RCC_APB2ENR (APB2 peripheral clock enable register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_APB2ENR>>16&0xFFFF, $RCC_APB2ENR&0xFFFF

	printf "0x4002_1038 0x0000_0001 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).TIM2EN (TIM2 clock enable bit): %x\n", $RCC_APB1ENR&0x1
	printf "0x4002_1038 0x0000_0002 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).TIM3EN (TIM3 clock enable bit): %x\n", $RCC_APB1ENR>>1&0x1
	printf "0x4002_1038 0x0000_0010 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).TIM6EN (TIM6 clock enable bit): %x\n", $RCC_APB1ENR>>4&0x1
	printf "0x4002_1038 0x0000_0020 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).TIM7EN (TIM7 clock enable bit): %x\n", $RCC_APB1ENR>>5&0x1
	printf "0x4002_1038 0x0000_0800 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).WWDGEN (window watchdog clock enable bit): %x\n", $RCC_APB1ENR>>11&0x1
	printf "0x4002_1038 0x0000_4000 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).SPI2EN (SPI2 clock enable bit): %x\n", $RCC_APB1ENR>>14&0x1
	printf "0x4002_1038 0x0002_0000 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).USART2EN (USART2 clock enable bit): %x\n", $RCC_APB1ENR>>17&0x1
	printf "0x4002_1038 0x0004_0000 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).LPUART1EN (LPUART1 clock enable bit): %x\n", $RCC_APB1ENR>>18&0x1
	printf "0x4002_1038 0x0008_0000 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).USART4EN (USART4 clock enable bit): %x\n", $RCC_APB1ENR>>19&0x1
	printf "0x4002_1038 0x0010_0000 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).USART5EN (USART5 clock enable bit): %x\n", $RCC_APB1ENR>>20&0x1
	printf "0x4002_1038 0x0020_0000 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).I2C1EN (I2C1 clock enable bit): %x\n", $RCC_APB1ENR>>21&0x1
	printf "0x4002_1038 0x0040_0000 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).I2C2EN (I2C2 clock enable bit): %x\n", $RCC_APB1ENR>>22&0x1
	printf "0x4002_1038 0x1000_0000 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).PWREN (power interface clock enable bit): %x\n", $RCC_APB1ENR>>28&0x1
	printf "0x4002_1038 0x4000_0000 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).I2C3EN (I2C3 clock enable bit): %x\n", $RCC_APB1ENR>>30&0x1
	printf "0x4002_1038 0x8000_0000 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).LPTIM1EN (Low-power timer clock enable bit): %x\n", $RCC_APB1ENR>>31&0x1
	printf "0x4002_1038 0xd07e_4833 | rw | RCC_APB1ENR (APB1 peripheral clock enable register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_APB1ENR>>16&0xFFFF, $RCC_APB1ENR&0xFFFF

	printf "0x4002_103c 0x0000_0001 | rw | RCC_IOPSMEN (GPIO clock enable in SLEEP MODE register).IOPASMEN (IOPAEN==1; Port A clock enable in SLEEP MODE): %x\n", $RCC_IOPSMEN&0x1
	printf "0x4002_103c 0x0000_0002 | rw | RCC_IOPSMEN (GPIO clock enable in SLEEP MODE register).IOPBSMEN (IOPAEN==1; Port B clock enable in SLEEP MODE): %x\n", $RCC_IOPSMEN>>1&0x1
	printf "0x4002_103c 0x0000_0004 | rw | RCC_IOPSMEN (GPIO clock enable in SLEEP MODE register).IOPCSMEN (IOPAEN==1; Port C clock enable in SLEEP MODE): %x\n", $RCC_IOPSMEN>>2&0x1
	printf "0x4002_103c 0x0000_0008 | rw | RCC_IOPSMEN (GPIO clock enable in SLEEP MODE register).IOPDSMEN (IOPAEN==1; Port D clock enable in SLEEP MODE): %x\n", $RCC_IOPSMEN>>3&0x1
	printf "0x4002_103c 0x0000_0010 | rw | RCC_IOPSMEN (GPIO clock enable in SLEEP MODE register).IOPESMEN (IOPAEN==1; Port E clock enable in SLEEP MODE): %x\n", $RCC_IOPSMEN>>4&0x1
	printf "0x4002_103c 0x0000_0080 | rw | RCC_IOPSMEN (GPIO clock enable in SLEEP MODE register).IOPHSMEN (IOPAEN==1; Port H clock enable in SLEEP MODE): %x\n", $RCC_IOPSMEN>>7&0x1
	printf "0x4002_103c 0x0000_009f | rw | RCC_IOPSMEN (GPIO clock enable in SLEEP MODE register).value (r=0x0000_009f): 0x%04x_%04x\n", $RCC_IOPSMEN>>16&0xFFFF, $RCC_IOPSMEN&0xFFFF

	printf "0x4002_1040 0x0000_0001 | rw | RCC_AHBSMENR (AHB peripheral clock enable in SLEEP MODE register).DMASMEN (DMA clock enable in SLEEP MODE bit): %x\n", $RCC_AHBSMENR&0x1
	printf "0x4002_1040 0x0000_0100 | rw | RCC_AHBSMENR (AHB peripheral clock enable in SLEEP MODE register).MIFSMEN (NVM interface clock enable in SLEEP MODE bit): %x\n", $RCC_AHBSMENR>>8&0x1
	printf "0x4002_1040 0x0000_0200 | rw | RCC_AHBSMENR (AHB peripheral clock enable in SLEEP MODE register).SRAMSMEN (NVM interface clock enable in SLEEP MODE bit): %x\n", $RCC_AHBSMENR>>9&0x1
	printf "0x4002_1040 0x0000_1000 | rw | RCC_AHBSMENR (AHB peripheral clock enable in SLEEP MODE register).CRCSMEN (test integration module clock enable in SLEEP MODE bit): %x\n", $RCC_AHBSMENR>>12&0x1
	printf "0x4002_1040 0x0100_0000 | rw | RCC_AHBSMENR (AHB peripheral clock enable in SLEEP MODE register).CRYPSMEN (Crypto clock enable in SLEEP MODE bit): %x\n", $RCC_AHBSMENR>>24&0x1
	printf "0x4002_1040 0x0100_1301 | rw | RCC_AHBSMENR (AHB peripheral clock enable in SLEEP MODE register).value (r=0x0100_1301): 0x%04x_%04x\n", $RCC_AHBSMENR>>16&0xFFFF, $RCC_AHBSMENR&0xFFFF

	printf "0x4002_1044 0x0000_0001 | rw | RCC_APB2SMENR (APB2 peripheral clock enable in SLEEP MODE register).SYSCFGSMEN (system configuration controller clock enable in SLEEP MODE bit): %x\n", $RCC_APB2SMENR&0x1
	printf "0x4002_1044 0x0000_0004 | rw | RCC_APB2SMENR (APB2 peripheral clock enable in SLEEP MODE register).TIM21SMEN (TIM21EN==1; TIM21 timer clock enable in SLEEP MODE bit): %x\n", $RCC_APB2SMENR>>2&0x1
	printf "0x4002_1044 0x0000_0020 | rw | RCC_APB2SMENR (APB2 peripheral clock enable in SLEEP MODE register).TIM22SMEN (TIM22EN==1; TIM22 timer clock enable in SLEEP MODE bit): %x\n", $RCC_APB2SMENR>>5&0x1
	printf "0x4002_1044 0x0000_0200 | rw | RCC_APB2SMENR (APB2 peripheral clock enable in SLEEP MODE register).ADCSMEN (ADCEN==1; ADC clock enable in SLEEP MODE bit): %x\n", $RCC_APB2SMENR>>9&0x1
	printf "0x4002_1044 0x0000_1000 | rw | RCC_APB2SMENR (APB2 peripheral clock enable in SLEEP MODE register).SPI1SMEN (SPI1EN==1; SPI1 clock enable in SLEEP MODE bit): %x\n", $RCC_APB2SMENR>>12&0x1
	printf "0x4002_1044 0x0000_4000 | rw | RCC_APB2SMENR (APB2 peripheral clock enable in SLEEP MODE register).USART1SMEN (USART1EN==1; USART1 clock enable in SLEEP MODE bit): %x\n", $RCC_APB2SMENR>>14&0x1
	printf "0x4002_1044 0x0040_0000 | rw | RCC_APB2SMENR (APB2 peripheral clock enable in SLEEP MODE register).DBGSMEN (DBGEN==1; DBG clock enable in SLEEP MODE bit): %x\n", $RCC_APB2SMENR>>22&0x1
	printf "0x4002_1044 0x0040_5225 | rw | RCC_APB2SMENR (APB2 peripheral clock enable in SLEEP MODE register).value (r=0x0040_5225): 0x%04x_%04x\n", $RCC_APB2SMENR>>16&0xFFFF, $RCC_APB2SMENR&0xFFFF

	printf "0x4002_1048 0x0000_0001 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).TIM2SMEN (TIM2EN==1; Timer2 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR&0x1
	printf "0x4002_1048 0x0000_0002 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).TIM3SMEN (TIM3EN==1; Timer3 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>1&0x1
	printf "0x4002_1048 0x0000_0010 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).TIM6SMEN (TIM6EN==1; Timer6 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>4&0x1
	printf "0x4002_1048 0x0000_0020 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).TIM7SMEN (TIM7EN==1; Timer7 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>5&0x1
	printf "0x4002_1048 0x0000_0800 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).WWDGSMEN (WWDGEN==1; window watchdog clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>11&0x1
	printf "0x4002_1048 0x0000_4000 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).SPI2SMEN (SPI2EN==1; SPI2 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>14&0x1
	printf "0x4002_1048 0x0002_0000 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).USART2EN (USART2EN==1; USART2 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>17&0x1
	printf "0x4002_1048 0x0004_0000 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).LPUART1SMEN (LPUART1EN==1; LPUART1 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>18&0x1
	printf "0x4002_1048 0x0008_0000 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).USART4SMEN (USART4EN==1; USART4 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>19&0x1
	printf "0x4002_1048 0x0010_0000 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).USART5SMEN (USART5EN==1; USART5 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>20&0x1
	printf "0x4002_1048 0x0020_0000 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).I2C1SMEN (I2C1EN==1; I2C1 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>21&0x1
	printf "0x4002_1048 0x0040_0000 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).I2C2SMEN (I2C2EN==1; I2C2 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>22&0x1
	printf "0x4002_1048 0x1000_0000 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).PWRSMEN (PWREN==1; power interface clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>28&0x1
	printf "0x4002_1048 0x4000_0000 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).I2C3SMEN (I2C3EN==1; I2C3 clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>30&0x1
	printf "0x4002_1048 0x8000_0000 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).LPTIM1SMEN (LPTIM1EN==1; Low-Power timer clock enable in SLEEP MODE bit): %x\n", $RCC_APB1SMENR>>31&0x1
	printf "0x4002_1048 0xd07e_4833 | rw | RCC_APB1SMENR (APB1 peripheral clock enable in SLEEP MODE register).value (r=0xd07e_4833): 0x%04x_%04x\n", $RCC_APB1SMENR>>16&0xFFFF, $RCC_APB1SMENR&0xFFFF

	printf "0x4002_104c 0x0000_0003 | rw | RCC_CCIPR (clock configuration register).USART1SEL (APB/0 SYS/1 HSI16/2 LSE/3; USART1 clock source select bits): %x\n", $RCC_CCIPR&0x3
	printf "0x4002_104c 0x0000_000c | rw | RCC_CCIPR (clock configuration register).USART2SEL (APB/0 SYS/1 HSI16/2 LSE/3; USART2 clock source select bits): %x\n", $RCC_CCIPR>>2&0x3
	printf "0x4002_104c 0x0000_0c00 | rw | RCC_CCIPR (clock configuration register).LPUART1SEL (APB/0 SYS/1 HSI16/2 LSE/3; LPUART1 clock source select bits): %x\n", $RCC_CCIPR>>10&0x3
	printf "0x4002_104c 0x0000_3000 | rw | RCC_CCIPR (clock configuration register).I2C1SEL (APB/0 SYS/1 HSI16/2 nouse/3; I2C1 clock source select bits): %x\n", $RCC_CCIPR>>12&0x3
	printf "0x4002_104c 0x0003_0000 | rw | RCC_CCIPR (clock configuration register).I2C3SEL (APB/0 SYS/1 HSI16/2 nouse/3; I2C3 clock source select bits): %x\n", $RCC_CCIPR>>16&0x3
	printf "0x4002_104c 0x000c_0000 | rw | RCC_CCIPR (clock configuration register).LPTIM1SEL (APB/0 LSI/1 HSI16/2 LSE/3; LPTIM1 clock source select bits): %x\n", $RCC_CCIPR>>18&0x3
	printf "0x4002_104c 0x000f_3c0f | rw | RCC_CCIPR (clock configuration register).value (r=0x0000_0000): 0x%04x_%04x\n", $RCC_CCIPR>>16&0xFFFF, $RCC_CCIPR&0xFFFF

	# TODO system reset occured due to <firewall/option bytes loading/nRST pin/etc>
	printf "0x4002_1050 0x0000_0001 | rw | RCC_CSR (control/status register).LSION (internal low-speed oscillator enable bit): %x\n", $RCC_CSR&0x1
	printf "0x4002_1050 0x0000_0002 | r  | RCC_CSR (control/status register).LSIRDY (internal low-speed oscillator is stable flag): %x\n", $RCC_CSR>>1&0x1
	printf "0x4002_1050 0x0000_0100 | rw | RCC_CSR (control/status register).LSEON (external low-speed oscillator enable bit): %x\n", $RCC_CSR>>8&0x1
	printf "0x4002_1050 0x0000_0200 | r  | RCC_CSR (control/status register).LSERDY (external low-speed oscillator is stable flag): %x\n", $RCC_CSR>>9&0x1
	printf "0x4002_1050 0x0000_0400 | rw | RCC_CSR (control/status register).LSEBYP (external low-speed oscillator is bypassed bit): %x\n", $RCC_CSR>>10&0x1
	printf "0x4002_1050 0x0000_1800 | rw | RCC_CSR (control/status register).LSEDRV (drive is low/0 midlow/1 midhigh/2 high/3; external low-speed oscillator driving capability selection bits): %x\n", $RCC_CSR>>11&0x3
	printf "0x4002_1050 0x0000_2000 | rw | RCC_CSR (control/status register).CSSLSEON (LSEON,LSION,LSERDY,LSIRDY==1 RTCSEL!=0; CSS on LSE enable bit): %x\n", $RCC_CSR>>13&0x1
	printf "0x4002_1050 0x0000_4000 | r  | RCC_CSR (control/status register).CSSLSED (CSS on LSE failure detected flag): %x\n", $RCC_CSR>>14&0x1
	printf "0x4002_1050 0x0003_0000 | rw | RCC_CSR (control/status register).RTCSEL (none/0 LSE/1 LSI/2 HSE/3; RTC clock source selection bits): %x\n", $RCC_CSR>>16&0x3
	printf "0x4002_1050 0x0004_0000 | rw | RCC_CSR (control/status register).RTCEN (RTC clock enable bit): %x\n", $RCC_CSR>>18&0x1
	printf "0x4002_1050 0x0008_0000 | rw | RCC_CSR (control/status register).RTCRST (RTC peripheral software reset bit): %x\n", $RCC_CSR>>19&0x1
	printf "0x4002_1050 0x0080_0000 |  w | RCC_CSR (control/status register).RMVF (clear the reset flags bit): N/A\n"
	printf "0x4002_1050 0x0100_0000 | r  | RCC_CSR (control/status register).FWRSTF (firewall reset occured flag): %x\n", $RCC_CSR>>24&0x1
	printf "0x4002_1050 0x0200_0000 | r  | RCC_CSR (control/status register).OBLRSTF (option bytes loading caused system reset flag): %x\n", $RCC_CSR>>25&0x1
	printf "0x4002_1050 0x0400_0000 | r  | RCC_CSR (control/status register).PINRSTF (reset from NRST pin occured flag): %x\n", $RCC_CSR>>26&0x1
	printf "0x4002_1050 0x0800_0000 | r  | RCC_CSR (control/status register).PORRSTF (power-on/down caused power reset flag): %x\n", $RCC_CSR>>27&0x1
	printf "0x4002_1050 0x1000_0000 | r  | RCC_CSR (control/status register).SFTRSTF (software incurred system reset flag): %x\n", $RCC_CSR>>28&0x1
	printf "0x4002_1050 0x2000_0000 | r  | RCC_CSR (control/status register).IWDGRSTF (independent watchdog reset occured flag): %x\n", $RCC_CSR>>29&0x1
	printf "0x4002_1050 0x4000_0000 | r  | RCC_CSR (control/status register).WWDGRSTF (window watchdog reset occured flag): %x\n", $RCC_CSR>>30&0x1
	printf "0x4002_1050 0x8000_0000 | r  | RCC_CSR (control/status register).LPWRRSTF (low-power management reset occured flag): %x\n", $RCC_CSR>>31&0x1
	printf "0x4002_1050 0xff8f_7f03 | rw | RCC_CSR (control/status register).value (r=0x0c00_0000 por=0x0c00_0004): 0x%04x_%04x\n", $RCC_CSR>>16&0xFFFF, $RCC_CSR&0xFFFF

	printf "0x4002_2000 0x0000_0001 | rw | FLASH_ACR (access control register).LATENCY (wait state enable bit): %x\n", $FLASH_ACR & 0x1
	printf "0x4002_2000 0x0000_0002 | rw | FLASH_ACR (access control register).PRFTEN (internal buffers prefetch enable bit): %x\n", $FLASH_ACR >> 1 & 0x1
	printf "0x4002_2000 0x0000_0008 | rw | FLASH_ACR (access control register).SLEEP_PD (when device sleep mode, NVM power-down enable bit): %x\n", $FLASH_ACR >> 3 & 0x1
	printf "0x4002_2000 0x0000_0010 | rw | FLASH_ACR (access control register).RUN_PD (when device run mode, NVM power-down enable bit): %x\n", $FLASH_ACR >> 4 & 0x1
	printf "0x4002_2000 0x0000_0020 | rw | FLASH_ACR (access control register).DISAB_BUF (internal buffers disable bit): %x\n", $FLASH_ACR >> 5 & 0x1
	printf "0x4002_2000 0x0000_0040 | rw | FLASH_ACR (access control register).PRE_READ (internal buffers pre-read enable bit): %x\n", $FLASH_ACR >> 6 & 0x1
	printf "0x4002_2000 0x0000_007b | rw | FLASH_ACR (access control register).value (r=0x0000_0000): %x\n", $FLASH_ACR
	printf "0x4002_2004 0x0000_0001 | rw | FLASH_PECR (protect erase control register).PELOCK (protect erase/write all and EEPROM lock enable bit): %x\n", $FLASH_PECR & 0x1
	printf "0x4002_2004 0x0000_0002 | rw | FLASH_PECR (protect erase control register).PRGLOCK (protect erase/write FLASH PROGRAM lock enable bit): %x\n", $FLASH_PECR >> 1 & 0x1
	printf "0x4002_2004 0x0000_0004 | rw | FLASH_PECR (protect erase control register).OPTLOCK (protect erase/write OPTION BYTES lock enable bit): %x\n", $FLASH_PECR >> 2 & 0x1
	printf "0x4002_2004 0x0000_0008 | rw | FLASH_PECR (protect erase control register).PROG (FLASH PROGRAM half-page erase/write operation bit): %x\n", $FLASH_PECR >> 3 & 0x1
	printf "0x4002_2004 0x0000_0010 | rw | FLASH_PECR (protect erase control register).DATA (EEPROM DATA page erase operation bit): %x\n", $FLASH_PECR >> 4 & 0x1
	printf "0x4002_2004 0x0000_0100 | rw | FLASH_PECR (protect erase control register).FIX (force erase&write every word operation bit): %x\n", $FLASH_PECR >> 8 & 0x1
	printf "0x4002_2004 0x0000_0200 | rw | FLASH_PECR (protect erase control register).ERASE (erase operation bit): %x\n", $FLASH_PECR >> 9 & 0x1
	printf "0x4002_2004 0x0000_0400 | rw | FLASH_PECR (protect erase control register).FPRG (FLASH PROGRAM half-page write operation bit): %x\n", $FLASH_PECR >> 10 & 0x1
	printf "0x4002_2004 0x0000_8000 | rw | FLASH_PECR (protect erase control register).PARALLELBANK (2 Banks in-parallel FLASH PROGRAM half-page write operation bit): %x\n", $FLASH_PECR >> 15 & 0x1
	printf "0x4002_2004 0x0001_0000 | rw | FLASH_PECR (protect erase control register).EOPIE (end of programming (write success) interupt enable bit): %x\n", $FLASH_PECR >> 16 & 0x1
	printf "0x4002_2004 0x0002_0000 | rw | FLASH_PECR (protect erase control register).ERRIE (write error interrupt enable bit): %x\n", $FLASH_PECR >> 17 & 0x1
	printf "0x4002_2004 0x0004_0000 | rw | FLASH_PECR (protect erase control register).OBL_LAUNCH (OBLRSTF:=1; cause system reset, reload option bytes request bit): %x\n", $FLASH_PECR >> 18 & 0x1
	printf "0x4002_2004 0x0080_0000 | rw | FLASH_PECR (protect erase control register).NZDISABLE (NOTZEROERR and emit interrupt disable bit): %x\n", $FLASH_PECR >> 19 & 0x1
	printf "0x4002_2004 0x0087_871f | rw | FLASH_PECR (protect erase control register).value (r=0x0000_0007): %x\n", $FLASH_PECR
	printf "0x4002_2008 0xffff_ffff |  w | FLASH_PDKEYR (power-down key register).value (r=0x0000_0000): N/A\n"
	printf "0x4002_200c 0xffff_ffff |  w | FLASH_PEKEYR (protect erase any or EEPROM key register).value (r=0x0000_0000 k1=0x89AB_CDEF k2=0x0203_0405): N/A\n"
	printf "0x4002_2010 0xffff_ffff |  w | FLASH_PRGKEYR (protect erase FLASH PROGRAM key register).value (r=0x0000_0000 k1=0x8C9D_AEBF k2=0x1314_1516): N/A\n"
	printf "0x4002_2014 0xffff_ffff |  w | FLASH_OPTKEYR (protect erase OPTION BYTES key register).value (r=0x0000_0000 k1=0xFBEA_D9C8 k2=0x2425_2627): N/A\n"
	printf "0x4002_2018 0x0000_0001 | r  | FLASH_SR (status register).BSY (memory interface doing erase/write operation bit): %x\n", $FLASH_SR & 0x1
	printf "0x4002_2018 0x0000_0002 | rc1| FLASH_SR (status register).EOP (end of FLASH PROGRAM write bit): %x\n", $FLASH_SR >> 1 & 0x1
	printf "0x4002_2018 0x0000_0004 | r  | FLASH_SR (status register).ENDHV (no ongoing write/erase, high voltage disabled bit): %x\n", $FLASH_SR >> 2 & 0x1
	printf "0x4002_2018 0x0000_0008 | r  | FLASH_SR (status register).READY (read/write/erase operations doable bit): %x\n", $FLASH_SR >> 3 & 0x1
	printf "0x4002_2018 0x0000_0100 | rc1| FLASH_SR (status register).WRPERR (attempted protected write operation error bit): %x\n", $FLASH_SR >> 8 & 0x1
	printf "0x4002_2018 0x0000_0200 | rc1| FLASH_SR (status register).PGAERR (write not half-page aligned or alike error bit): %x\n", $FLASH_SR >> 9 & 0x1
	printf "0x4002_2018 0x0000_0400 | rc1| FLASH_SR (status register).SIZERR (provided invalid size to write operation bit): %x\n", $FLASH_SR >> 10 & 0x1
	printf "0x4002_2018 0x0000_0800 | rc1| FLASH_SR (status register).OPTVERR (option validity error bit): %x\n", $FLASH_SR >> 11 & 0x1
	printf "0x4002_2018 0x0000_2000 | rc1| FLASH_SR (status register).RDERR (attempted protected read \"FLASH sector w/ PcROP\" operation error bit): %x\n", $FLASH_SR >> 13 & 0x1
	printf "0x4002_2018 0x0001_0000 | rc1| FLASH_SR (status register).NOTZEROERR (attempted write to FLASH without prior erase error bit): %x\n", $FLASH_SR >> 16 & 0x1
	printf "0x4002_2018 0x0002_0000 | rc1| FLASH_SR (status register).FWWERR (fetch while write error bit): %x\n", $FLASH_SR >> 17 & 0x1
	printf "0x4002_2018 0x0003_2f0f | rw | FLASH_SR (status register).value (r=0x0000_000c): %x\n", $FLASH_SR
	printf "0x4002_201c 0x0000_00ff | r  | FLASH_OPTR (loaded option bytes register).RDPROT (read out proctection bitfield): %02x\n", $FLASH_OPTR&0xFF
	printf "0x4002_201c 0x0000_0100 | r  | FLASH_OPTR (loaded option bytes register).WPRMOD (WRPROT bitmask does w=0/r=1 protection mode bit): %x\n", $FLASH_OPTR>>8 & 0x1
	printf "0x4002_201c 0x000f_0000 | r  | FLASH_OPTR (loaded option bytes register).BOR_LEV (brownout reset threshold level bitfield): %x\n", $FLASH_OPTR>>16 & 0xF
	printf "0x4002_201c 0x0010_0000 | r  | FLASH_OPTR (loaded option bytes register).WDG_SW (watchdog hw=0/sw=1 mode bit): %x\n", $FLASH_OPTR>>20 & 0x1
	printf "0x4002_201c 0x0020_0000 | r  | FLASH_OPTR (loaded option bytes register).nRST_STOP (device stop mode, emit reset disable bit): %x\n", $FLASH_OPTR>>21 & 0x1
	printf "0x4002_201c 0x0040_0000 | r  | FLASH_OPTR (loaded option bytes register).nRST_STDBY (device standy mode, emit reset disable bit): %x\n", $FLASH_OPTR>>22 & 0x1
	printf "0x4002_201c 0x0080_0000 | r  | FLASH_OPTR (loaded option bytes register).BFB2 (map sysflash to 0x0 to boot from bank 2 bit): %x\n", $FLASH_OPTR>>23 & 0x1
	printf "0x4002_201c 0x8000_0000 | r  | FLASH_OPTR (loaded option bytes register).nBOOT1 (bit): %x\n", $FLASH_OPTR>>31 & 0x1
	printf "0x4002_201c 0x80ff_01ff | r  | FLASH_OPTR (loaded option bytes register).value (r=0xX0XX_0XXX d=0x8070_00aa mm=0x8*{111}8_*{1}00): 0x%04x_%04x\n", $FLASH_OPTR>>16&0xFFFF, $FLASH_OPTR&0xFFFF
	printf "0x4002_2020 0xffff_ffff | r  | FLASH_WRPROT1 (write protection register 1).value (r=0xXXXX_XXXX d=0x0000_0000): 0x%04x_%04x\n", $FLASH_WRPROT1>>16&0xFFFF, $FLASH_WRPROT1&0xFFFF
	printf "0x4002_2080 0x0000_ffff | r  | FLASH_WRPROT2 (write protection register 2).value (r=0x0000_XXXX d=0x0000_0000): 0x%04x_%04x\n", $FLASH_WRPROT2>>16&0xFFFF, $FLASH_WRPROT2&0xFFFF

	  printf "*********************** | ** | GPIOx_ PhyPinNr     MODER     OTYPER        OSPEEDR      PUPDR       IDR      ODR       LCKR        AFRL/H           Notes\n"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA0:  UFQFPN32_6   " 0 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[Button] Main Button"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA1:  UFQFPN32_7   " 1 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[NFC] NFC Chip (ST25DV04K UFDFPN8), Interrupt"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA2:  UFQFPN32_8   " 2 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[curio] ANT_SW, to some proxy SMC, tht connects LoRa IC"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA3:  UFQFPN32_9   " 3 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[curio] Floating"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA4:  UFQFPN32_10  " 4 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[LORA] LoRa Chip, SX_nSS"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA5:  UFQFPN32_11  " 5 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[LORA] LoRa Chip, SX_SCK"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA6:  UFQFPN32_12  " 6 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[LORA] LoRa Chip, SX_MISO"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA7:  UFQFPN32_13  " 7 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[LORA] LoRa Chip, SX_MOSI"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA8:  UFQFPN32_18  " 8 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[LED] LED_Green"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA9:  UFQFPN32_19  " 9 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[LED] LED_Red"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA10: UFQFPN32_20  " 10 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[curio] Floating"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA11: UFQFPN32_21  " 11 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[LORA] LoRa Chip, SX_BUSY"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA12: UFQFPN32_22  " 12 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[LORA] LoRa Chip, SX_DIO3"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA13: UFQFPN32_23  " 13 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[JTAG] HW Debugger lines, no touchy!"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA14: UFQFPN32_25  " 14 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' "[JTAG] HW Debugger lines, no touchy!"
	portdesc "0x5000_00XX 0xXXXX_XXXX |mux | _PA15: N/A          " 15 $GPIOA_MODER $GPIOA_OTYPER $GPIOA_OSPEEDR $GPIOA_PUPDR $GPIOA_IDR $GPIOA_ODR $GPIOA_LCKR $GPIOA_AFRL $GPIOA_AFRH 'A' ""
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB0:  UFQFPN32_14  " 0 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' "[curio] SMPS_Mode, I think it's some battery controlling IC"
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB1:  UFQFPN32_15  " 1 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' "[curio] Floating"
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB2:  N/A          " 2 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' ""
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB3:  N/A          " 3 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' ""
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB4:  UFQFPN32_26  " 4 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' "[LORA] LoRa Chip, SX_RESET"
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB5:  UFQFPN32_27  " 5 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' "[LORA] LoRa Chip, SX_DIO1"
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB6:  UFQFPN32_28  " 6 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' "[NFC] NFC Chip (ST25DV04K UFDFPN8), I2C Serial Clock"
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB7:  UFQFPN32_29  " 7 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' "[NFC] NFC Chip (ST25DV04K UFDFPN8), I2C Serial Data"
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB8:  N/A          " 8 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' ""
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB9:  N/A          " 9 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' ""
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB10: N/A          " 10 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' ""
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB11: N/A          " 11 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' ""
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB12: N/A          " 12 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' ""
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB13: N/A          " 13 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' ""
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB14: N/A          " 14 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' ""
	portdesc "0x5000_04XX 0xXXXX_XXXX |mux | _PB15: N/A          " 15 $GPIOB_MODER $GPIOB_OTYPER $GPIOB_OSPEEDR $GPIOB_PUPDR $GPIOB_IDR $GPIOB_ODR $GPIOB_LCKR $GPIOB_AFRL $GPIOB_AFRH 'B' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC0:  N/A          " 0 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC1:  N/A          " 1 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC2:  N/A          " 2 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC3:  N/A          " 3 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC4:  N/A          " 4 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC5:  N/A          " 5 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC6:  N/A          " 6 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC7:  N/A          " 7 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC8:  N/A          " 8 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC9:  N/A          " 9 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC10: N/A          " 10 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC11: N/A          " 11 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC12: N/A          " 12 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC13: N/A          " 13 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' ""
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC14: UFQFPN32_1   " 14 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' "[curio] Ground with resistor"
	portdesc "0x5000_08XX 0xXXXX_XXXX |mux | _PC15: UFQFPN32_2   " 15 $GPIOC_MODER $GPIOC_OTYPER $GPIOC_OSPEEDR $GPIOC_PUPDR $GPIOC_IDR $GPIOC_ODR $GPIOC_LCKR $GPIOC_AFRL $GPIOC_AFRH 'C' "[curio] Ground with resistor"
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD0:  N/A          " 0 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD1:  N/A          " 1 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD2:  N/A          " 2 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD3:  N/A          " 3 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD4:  N/A          " 4 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD5:  N/A          " 5 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD6:  N/A          " 6 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD7:  N/A          " 7 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD8:  N/A          " 8 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD9:  N/A          " 9 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD10: N/A          " 10 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD11: N/A          " 11 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD12: N/A          " 12 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD13: N/A          " 13 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD14: N/A          " 14 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_0cXX 0xXXXX_XXXX |mux | _PD15: N/A          " 15 $GPIOD_MODER $GPIOD_OTYPER $GPIOD_OSPEEDR $GPIOD_PUPDR $GPIOD_IDR $GPIOD_ODR $GPIOD_LCKR $GPIOD_AFRL $GPIOD_AFRH 'D' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE0:  N/A          " 0 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE1:  N/A          " 1 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE2:  N/A          " 2 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE3:  N/A          " 3 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE4:  N/A          " 4 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE5:  N/A          " 5 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE6:  N/A          " 6 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE7:  N/A          " 7 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE8:  N/A          " 8 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE9:  N/A          " 9 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE10: N/A          " 10 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE11: N/A          " 11 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE12: N/A          " 12 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE13: N/A          " 13 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE14: N/A          " 14 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_10XX 0xXXXX_XXXX |mux | _PE15: N/A          " 15 $GPIOE_MODER $GPIOE_OTYPER $GPIOE_OSPEEDR $GPIOE_PUPDR $GPIOE_IDR $GPIOE_ODR $GPIOE_LCKR $GPIOE_AFRL $GPIOE_AFRH 'E' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH0:  N/A          " 0 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH1:  N/A          " 1 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH2:  N/A          " 2 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH3:  N/A          " 3 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH4:  N/A          " 4 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH5:  N/A          " 5 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH6:  N/A          " 6 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH7:  N/A          " 7 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH8:  N/A          " 8 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH9:  N/A          " 9 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH10: N/A          " 10 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH11: N/A          " 11 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH12: N/A          " 12 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH13: N/A          " 13 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH14: N/A          " 14 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""
	portdesc "0x5000_14XX 0xXXXX_XXXX |mux | _PH15: N/A          " 15 $GPIOH_MODER $GPIOH_OTYPER $GPIOH_OSPEEDR $GPIOH_PUPDR $GPIOH_IDR $GPIOH_ODR $GPIOH_LCKR $GPIOH_AFRL $GPIOH_AFRH 'H' ""

#	printf "0x5000_0000 0x0000_0003 | rw | GPIOA_MODER (A port mode register).MODE0 (i/0, gpo/1, af/2, analog/3; PA0 config bits): %x\n", $GPIOA_MODER&0x3
#	printf "0x5000_0000 0x0000_000c | rw | GPIOA_MODER (A port mode register).MODE1 (i/0, gpo/1, af/2, analog/3; PA1 config bits): %x\n", ($GPIOA_MODER&0xc)>>2
#	printf "0x5000_0000 0x0000_0030 | rw | GPIOA_MODER (A port mode register).MODE2 (i/0, gpo/1, af/2, analog/3; PA2 config bits): %x\n", ($GPIOA_MODER&0x30)>>4
#	printf "0x5000_0000 0x0000_00c0 | rw | GPIOA_MODER (A port mode register).MODE3 (i/0, gpo/1, af/2, analog/3; PA3 config bits): %x\n", ($GPIOA_MODER&0xc0)>>6
#	printf "0x5000_0000 0x0000_0300 | rw | GPIOA_MODER (A port mode register).MODE4 (i/0, gpo/1, af/2, analog/3; PA4 config bits): %x\n", ($GPIOA_MODER&0x300)>>8
#	printf "0x5000_0000 0x0000_0c00 | rw | GPIOA_MODER (A port mode register).MODE5 (i/0, gpo/1, af/2, analog/3; PA5 config bits): %x\n", ($GPIOA_MODER&0xc00)>>10
#	printf "0x5000_0000 0x0000_3000 | rw | GPIOA_MODER (A port mode register).MODE6 (i/0, gpo/1, af/2, analog/3; PA6 config bits): %x\n", ($GPIOA_MODER&0x3000)>>12
#	printf "0x5000_0000 0x0000_c000 | rw | GPIOA_MODER (A port mode register).MODE7 (i/0, gpo/1, af/2, analog/3; PA7 config bits): %x\n", ($GPIOA_MODER&0xc000)>>14
#	printf "0x5000_0000 0x0003_0000 | rw | GPIOA_MODER (A port mode register).MODE8 (i/0, gpo/1, af/2, analog/3; PA8 config bits): %x\n", ($GPIOA_MODER&0x30000)>>16
#	printf "0x5000_0000 0x000c_0000 | rw | GPIOA_MODER (A port mode register).MODE9 (i/0, gpo/1, af/2, analog/3; PA9 config bits): %x\n", ($GPIOA_MODER&0xc0000)>>18
#	printf "0x5000_0000 0x0030_0000 | rw | GPIOA_MODER (A port mode register).MODE10 (i/0, gpo/1, af/2, analog/3; PA10 config bits): %x\n", ($GPIOA_MODER&0x300000)>>20
#	printf "0x5000_0000 0x00c0_0000 | rw | GPIOA_MODER (A port mode register).MODE11 (i/0, gpo/1, af/2, analog/3; PA11 config bits): %x\n", ($GPIOA_MODER&0xc00000)>>22
#	printf "0x5000_0000 0x0300_0000 | rw | GPIOA_MODER (A port mode register).MODE12 (i/0, gpo/1, af/2, analog/3; PA12 config bits): %x\n", ($GPIOA_MODER&0x3000000)>>24
#	printf "0x5000_0000 0x0c00_0000 | rw | GPIOA_MODER (A port mode register).MODE13 (i/0, gpo/1, af/2, analog/3; PA13 config bits): %x\n", ($GPIOA_MODER&0xc000000)>>26
#	printf "0x5000_0000 0x3000_0000 | rw | GPIOA_MODER (A port mode register).MODE14 (i/0, gpo/1, af/2, analog/3; PA14 config bits): %x\n", ($GPIOA_MODER&0x30000000)>>28
#	printf "0x5000_0000 0xc000_0000 | rw | GPIOA_MODER (A port mode register).MODE15 (i/0, gpo/1, af/2, analog/3; PA15 config bits): %x\n", ($GPIOA_MODER&0xc0000000)>>30
	printf "0x5000_0000 0xffff_ffff | rw | GPIOA_MODER (A port mode register).value (r=0xebff_fcff): 0x%04x_%04x\n", $GPIOA_MODER>>16&0xFFFF, $GPIOA_MODER&0xFFFF

#	printf "0x5000_0004 0x0000_ffff | rw | GPIOA_OTYPER (A port output type register).OTy (push-pull/0, open-drain/1; PA0..15 config bits): %04x\n", $GPIOA_OTYPER&0xFFFF
	printf "0x5000_0004 0x0000_ffff | rw | GPIOA_OTYPER (A port output type register).value (r=0x0000_0000): 0x%04x_%04x\n", $GPIOA_OTYPER>>16&0xFFFF, $GPIOA_OTYPER&0xFFFF

#	printf "0x5000_0008 0x0000_0003 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED0 (low/0, medium/1, high/2, very high/3; PA0 speed bits): %x\n", $GPIOA_OSPEEDR&0x3
#	printf "0x5000_0008 0x0000_000c | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED1 (low/0, medium/1, high/2, very high/3; PA1 speed bits): %x\n", ($GPIOA_OSPEEDR&0xc)>>2
#	printf "0x5000_0008 0x0000_0030 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED2 (low/0, medium/1, high/2, very high/3; PA2 speed bits): %x\n", ($GPIOA_OSPEEDR&0x30)>>4
#	printf "0x5000_0008 0x0000_00c0 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED3 (low/0, medium/1, high/2, very high/3; PA3 speed bits): %x\n", ($GPIOA_OSPEEDR&0xc0)>>6
#	printf "0x5000_0008 0x0000_0300 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED4 (low/0, medium/1, high/2, very high/3; PA4 speed bits): %x\n", ($GPIOA_OSPEEDR&0x300)>>8
#	printf "0x5000_0008 0x0000_0c00 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED5 (low/0, medium/1, high/2, very high/3; PA5 speed bits): %x\n", ($GPIOA_OSPEEDR&0xc00)>>10
#	printf "0x5000_0008 0x0000_3000 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED6 (low/0, medium/1, high/2, very high/3; PA6 speed bits): %x\n", ($GPIOA_OSPEEDR&0x3000)>>12
#	printf "0x5000_0008 0x0000_c000 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED7 (low/0, medium/1, high/2, very high/3; PA7 speed bits): %x\n", ($GPIOA_OSPEEDR&0xc000)>>14
#	printf "0x5000_0008 0x0003_0000 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED8 (low/0, medium/1, high/2, very high/3; PA8 speed bits): %x\n", ($GPIOA_OSPEEDR&0x30000)>>16
#	printf "0x5000_0008 0x000c_0000 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED9 (low/0, medium/1, high/2, very high/3; PA9 speed bits): %x\n", ($GPIOA_OSPEEDR&0xc0000)>>18
#	printf "0x5000_0008 0x0030_0000 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED10 (low/0, medium/1, high/2, very high/3; PA10 speed bits): %x\n", ($GPIOA_OSPEEDR&0x300000)>>20
#	printf "0x5000_0008 0x00c0_0000 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED11 (low/0, medium/1, high/2, very high/3; PA11 speed bits): %x\n", ($GPIOA_OSPEEDR&0xc00000)>>22
#	printf "0x5000_0008 0x0300_0000 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED12 (low/0, medium/1, high/2, very high/3; PA12 speed bits): %x\n", ($GPIOA_OSPEEDR&0x3000000)>>24
#	printf "0x5000_0008 0x0c00_0000 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED13 (low/0, medium/1, high/2, very high/3; PA13 speed bits): %x\n", ($GPIOA_OSPEEDR&0xc000000)>>26
#	printf "0x5000_0008 0x3000_0000 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED14 (low/0, medium/1, high/2, very high/3; PA14 speed bits): %x\n", ($GPIOA_OSPEEDR&0x30000000)>>28
#	printf "0x5000_0008 0xc000_0000 | rw | GPIOA_OSPEEDR (A port output speed register).OSPEED15 (low/0, medium/1, high/2, very high/3; PA15 speed bits): %x\n", ($GPIOA_OSPEEDR&0xc0000000)>>30
	printf "0x5000_0008 0xffff_ffff | rw | GPIOA_OSPEEDR (A port output speed register).value (r=0x0c00_0000): 0x%04x_%04x\n", $GPIOA_OSPEEDR>>16&0xFFFF, $GPIOA_OSPEEDR&0xFFFF

#	printf "0x5000_000c 0x0000_0003 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD0 (none/0, pullup/1, pulldown/2; PA0 pull bits): %x\n", $GPIOA_PUPDR&0x3
#	printf "0x5000_000c 0x0000_000c | rw | GPIOA_PUPDR (A port pullup/down register).PUPD1 (none/0, pullup/1, pulldown/2; PA1 pull bits): %x\n", ($GPIOA_PUPDR&0xc)>>2
#	printf "0x5000_000c 0x0000_0030 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD2 (none/0, pullup/1, pulldown/2; PA2 pull bits): %x\n", ($GPIOA_PUPDR&0x30)>>4
#	printf "0x5000_000c 0x0000_00c0 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD3 (none/0, pullup/1, pulldown/2; PA3 pull bits): %x\n", ($GPIOA_PUPDR&0xc0)>>6
#	printf "0x5000_000c 0x0000_0300 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD4 (none/0, pullup/1, pulldown/2; PA4 pull bits): %x\n", ($GPIOA_PUPDR&0x300)>>8
#	printf "0x5000_000c 0x0000_0c00 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD5 (none/0, pullup/1, pulldown/2; PA5 pull bits): %x\n", ($GPIOA_PUPDR&0xc00)>>10
#	printf "0x5000_000c 0x0000_3000 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD6 (none/0, pullup/1, pulldown/2; PA6 pull bits): %x\n", ($GPIOA_PUPDR&0x3000)>>12
#	printf "0x5000_000c 0x0000_c000 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD7 (none/0, pullup/1, pulldown/2; PA7 pull bits): %x\n", ($GPIOA_PUPDR&0xc000)>>14
#	printf "0x5000_000c 0x0003_0000 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD8 (none/0, pullup/1, pulldown/2; PA8 pull bits): %x\n", ($GPIOA_PUPDR&0x30000)>>16
#	printf "0x5000_000c 0x000c_0000 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD9 (none/0, pullup/1, pulldown/2; PA9 pull bits): %x\n", ($GPIOA_PUPDR&0xc0000)>>18
#	printf "0x5000_000c 0x0030_0000 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD10 (none/0, pullup/1, pulldown/2; PA10 pull bits): %x\n", ($GPIOA_PUPDR&0x300000)>>20
#	printf "0x5000_000c 0x00c0_0000 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD11 (none/0, pullup/1, pulldown/2; PA11 pull bits): %x\n", ($GPIOA_PUPDR&0xc00000)>>22
#	printf "0x5000_000c 0x0300_0000 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD12 (none/0, pullup/1, pulldown/2; PA12 pull bits): %x\n", ($GPIOA_PUPDR&0x3000000)>>24
#	printf "0x5000_000c 0x0c00_0000 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD13 (none/0, pullup/1, pulldown/2; PA13 pull bits): %x\n", ($GPIOA_PUPDR&0xc000000)>>26
#	printf "0x5000_000c 0x3000_0000 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD14 (none/0, pullup/1, pulldown/2; PA14 pull bits): %x\n", ($GPIOA_PUPDR&0x30000000)>>28
#	printf "0x5000_000c 0xc000_0000 | rw | GPIOA_PUPDR (A port pullup/down register).PUPD15 (none/0, pullup/1, pulldown/2; PA15 pull bits): %x\n", ($GPIOA_PUPDR&0xc0000000)>>30
	printf "0x5000_000c 0xffff_ffff | rw | GPIOA_PUPDR (A port pullup/down register).value (r=0x2400_0000): 0x%04x_%04x\n", $GPIOA_PUPDR>>16&0xFFFF, $GPIOA_PUPDR&0xFFFF

#	printf "0x5000_0010 0x0000_ffff | r  | GPIOA_IDR (A port input data register).IDy (PA0..15 asserted bits): %04x\n", $GPIOA_IDR&0xFFFF
	printf "0x5000_0010 0x0000_ffff | r  | GPIOA_IDR (A port input data register).value (r=0x0000_XXXX): 0x%04x_%04x\n", $GPIOA_IDR>>16&0xFFFF, $GPIOA_IDR&0xFFFF

#	printf "0x5000_0014 0x0000_ffff | rw | GPIOA_ODR (A port output data register).ODy (PA0..15 assert bits): %04x\n", $GPIOA_ODR&0xFFFF
	printf "0x5000_0014 0x0000_ffff | rw | GPIOA_ODR (A port output data register).value (r=0x0000_XXXX): 0x%04x_%04x\n", $GPIOA_ODR>>16&0xFFFF, $GPIOA_ODR&0xFFFF

	printf "0x5000_001c 0x0000_ffff | rw | GPIOA_LCKR (A port configuration lock register).LCKy (PA0..15 lock bits): %04x\n", $GPIOA_LCKR&0xFFFF
	printf "0x5000_001c 0x0001_0000 | rw | GPIOA_LCKR (A port configuration lock register).LCKK (sequence: 1, 0, 1; this register lock bit): %04x\n", $GPIOA_LCKR>>16&0x1
	printf "0x5000_001c 0x0001_ffff | rw | GPIOA_LCKR (A port configuration lock register).value (r=0x0000_0000): 0x%04x_%04x\n", $GPIOA_LCKR>>16&0xFFFF, $GPIOA_LCKR&0xFFFF

#	printf "0x5000_0020 0x0000_000f | rw | GPIOA_AFRL (A port alt func low register).AFSEL0 (PA0 af0..7 bits): %x\n", $GPIOA_AFRL&0xF
#	printf "0x5000_0020 0x0000_00f0 | rw | GPIOA_AFRL (A port alt func low register).AFSEL1 (PA1 af0..7 bits): %x\n", $GPIOA_AFRL>>4&0xF
#	printf "0x5000_0020 0x0000_0f00 | rw | GPIOA_AFRL (A port alt func low register).AFSEL2 (PA2 af0..7 bits): %x\n", $GPIOA_AFRL>>8&0xF
#	printf "0x5000_0020 0x0000_f000 | rw | GPIOA_AFRL (A port alt func low register).AFSEL3 (PA3 af0..7 bits): %x\n", $GPIOA_AFRL>>12&0xF
#	printf "0x5000_0020 0x000f_0000 | rw | GPIOA_AFRL (A port alt func low register).AFSEL4 (PA4 af0..7 bits): %x\n", $GPIOA_AFRL>>16&0xF
#	printf "0x5000_0020 0x00f0_0000 | rw | GPIOA_AFRL (A port alt func low register).AFSEL5 (PA5 af0..7 bits): %x\n", $GPIOA_AFRL>>20&0xF
#	printf "0x5000_0020 0x0f00_0000 | rw | GPIOA_AFRL (A port alt func low register).AFSEL6 (PA6 af0..7 bits): %x\n", $GPIOA_AFRL>>24&0xF
#	printf "0x5000_0020 0xf000_0000 | rw | GPIOA_AFRL (A port alt func low register).AFSEL7 (PA7 af0..7 bits): %x\n", $GPIOA_AFRL>>28&0xF
	printf "0x5000_0020 0xffff_ffff | rw | GPIOA_AFRL (A port alt func low register).value (r=0x0000_0000): 0x%04x_%04x\n", $GPIOA_AFRL>>16&0xFFFF, $GPIOA_AFRL&0xFFFF

#	printf "0x5000_0024 0x0000_000f | rw | GPIOA_AFRH (A port alt func high register).AFSEL8 (PA8 af0..7 bits): %x\n", $GPIOA_AFRH&0xF
#	printf "0x5000_0024 0x0000_00f0 | rw | GPIOA_AFRH (A port alt func high register).AFSEL9 (PA9 af0..7 bits): %x\n", $GPIOA_AFRH>>4&0xF
#	printf "0x5000_0024 0x0000_0f00 | rw | GPIOA_AFRH (A port alt func high register).AFSEL10 (PA10 af0..7 bits): %x\n", $GPIOA_AFRH>>8&0xF
#	printf "0x5000_0024 0x0000_f000 | rw | GPIOA_AFRH (A port alt func high register).AFSEL11 (PA11 af0..7 bits): %x\n", $GPIOA_AFRH>>12&0xF
#	printf "0x5000_0024 0x000f_0000 | rw | GPIOA_AFRH (A port alt func high register).AFSEL12 (PA12 af0..7 bits): %x\n", $GPIOA_AFRH>>16&0xF
#	printf "0x5000_0024 0x00f0_0000 | rw | GPIOA_AFRH (A port alt func high register).AFSEL13 (PA13 af0..7 bits): %x\n", $GPIOA_AFRH>>20&0xF
#	printf "0x5000_0024 0x0f00_0000 | rw | GPIOA_AFRH (A port alt func high register).AFSEL14 (PA14 af0..7 bits): %x\n", $GPIOA_AFRH>>24&0xF
#	printf "0x5000_0024 0xf000_0000 | rw | GPIOA_AFRH (A port alt func high register).AFSEL15 (PA15 af0..7 bits): %x\n", $GPIOA_AFRH>>28&0xF
	printf "0x5000_0024 0xffff_ffff | rw | GPIOA_AFRH (A port alt func high register).value (r=0x0000_0000): 0x%04x_%04x\n", $GPIOA_AFRH>>16&0xFFFF, $GPIOA_AFRH&0xFFFF

	printf "** 0xe000_0000..0xe00f_ffff * Cortex-M0+ Peripherals **\n"
	printf "0xe000_e400 0x0000_00c0 | rw | NVIC_IP0_3 (interrupt priority register).WWDG (0>1; window watchdog priority bits): %x\n", $NVIC_IP0_3>>6&0x3
	printf "0xe000_e400 0xc0c0_c0c0 | rw | NVIC_IP0_3 (interrupt priority register).value (r=0x0000_0000): 0x%04x_%04x\n", $NVIC_IP0_3>>16&0xFFFF, $NVIC_IP0_3&0xFFFF
	printf "0xe000_e404 0x0000_c000 | rw | NVIC_IP4_7 (interrupt priority register).EXTI0_1 (0>1; sw irq; sta:button stx:reedswitch): %x\n", $NVIC_IP4_7>>14&0x3
	printf "0xe000_e404 0xc0c0_c0c0 | rw | NVIC_IP4_7 (interrupt priority register).value (r=0x0000_0000): 0x%04x_%04x\n", $NVIC_IP4_7>>16&0xFFFF, $NVIC_IP4_7&0xFFFF
	printf "0xe000_e408 0xc0c0_c0c0 | rw | NVIC_IP8_11 (interrupt priority register).value (r=0x0000_0000): 0x%04x_%04x\n", $NVIC_IP8_11>>16&0xFFFF, $NVIC_IP8_11&0xFFFF
	printf "0xe000_e40c 0x0000_c000 | rw | NVIC_IP12_15 (interrupt priority register).LPTIM1 (0>1; low power timer priority bits): %x\n", $NVIC_IP12_15>>14&0x3
	printf "0xe000_e40c 0xc0c0_c0c0 | rw | NVIC_IP12_15 (interrupt priority register).value (r=0x0000_0000): 0x%04x_%04x\n", $NVIC_IP12_15>>16&0xFFFF, $NVIC_IP12_15&0xFFFF
	printf "0xe000_e410 0xc0c0_c0c0 | rw | NVIC_IP16_19 (interrupt priority register).value (r=0x0000_0000): 0x%04x_%04x\n", $NVIC_IP16_19>>16&0xFFFF, $NVIC_IP16_19&0xFFFF
	printf "0xe000_e414 0xc0c0_c0c0 | rw | NVIC_IP20_23 (interrupt priority register).value (r=0x0000_0000): 0x%04x_%04x\n", $NVIC_IP20_23>>16&0xFFFF, $NVIC_IP20_23&0xFFFF
	printf "0xe000_e418 0xc0c0_c0c0 | rw | NVIC_IP24_27 (interrupt priority register).value (r=0x0000_0000): 0x%04x_%04x\n", $NVIC_IP24_27>>16&0xFFFF, $NVIC_IP24_27&0xFFFF
	printf "0xe000_e41c 0x0000_c0c0 | rw | NVIC_IP28_29 (interrupt priority register).value (r=0x0000_0000): 0x%04x_%04x\n", $NVIC_IP28_29>>16&0xFFFF, $NVIC_IP28_29&0xFFFF
	printf "0xe000_ed08 0xffff_ff00 | rw | SCB_VTOR (system control block vector table offset register).TBLOFF (table offset bitfield): 0x%02x_%04x\n", $SCB_VTOR>>8+16&0xFF, $SCB_VTOR>>8&0xFFFF
	printf "0xe000_ed08 0xffff_ff00 | rw | SCB_VTOR (system control block vector table offset register).value (r=0x0000_0000): 0x%04x_%04x\n", $SCB_VTOR>>16&0xFFFF, $SCB_VTOR&0xFFFF

	printf "** DeviceAddr:TargetAddr * I2C ST25DV NFC radio **\n"
	printf "0xAE:0x0000             | rw | ST25DV_SYS_GPOR (gpo interrupt mask register).value:\n"
	printf "0xAE:0x0001             | rw | ST25DV_SYS_IT_TIME (interrupt pulse duration register)\n"
	printf "0xAE:0x0002             | rw | ST25DV_SYS_EH_MODE (energy harvesting default strategy after power-on register)\n"
	printf "0xAE:0x0003             | rw | ST25DV_SYS_RF_MNGT (rf interfase state after power-on register)\n"
	printf "0xAE:0x0004             | rw | ST25DV_SYS_RFA1SS (area 1 rf access protection register)\n"
	printf "0xAE:0x0005             | rw | ST25DV_SYS_ENDA1 (area 1 ending point register).value (r=0x0f; 32*ENDA+31 is area 1 last byte; 32*ENDA+32 is area 2 first byte)\n"
	printf "0xAE:0x0006             | rw | ST25DV_SYS_RFA2SS (area 2 rf access protection register)\n"
	printf "0xAE:0x0007             | rw | ST25DV_SYS_ENDA2 (area 2 ending point register).value (r=0x0f)\n"
	printf "0xAE:0x0008             | rw | ST25DV_SYS_RFA3SS (area 3 rf access protection register)\n"
	printf "0xAE:0x0009             | rw | ST25DV_SYS_ENDA3 (area 3 ending point register).value (r=0x0f)\n"
	printf "0xAE:0x000a             | rw | ST25DV_SYS_RFA4SS (area 4 rf access protection register)\n"
	printf "0xAE:0x000b             | rw | ST25DV_SYS_I2CSS (area 1..4 I2C access protection register)\n"
	printf "0xAE:0x000c             | rw | ST25DV_SYS_LOCK_CCFILE (blocks 0 and 1 rf write protection register)\n"
	printf "0xAE:0x000c             | rw | ST25DV_SYS_LOCK_CCFILE (RF write-protect blocks 0,1 of area 0 register)\n"
	printf "0xAE:0x000d        0x01 | rw | ST25DV_SYS_MB_MODE (mailbox mode register).value (f=0x00): 0x%02x\n", $ST25DV_SYS_MB_MODE
	printf "0xAE:0x000d        0x01 | rw | ST25DV_SYS_MB_MODE (mailbox mode register).MB_MODE (fast transfer mode state after power-on; ftm enable bit): %x\n", $ST25DV_SYS_MB_MODE&0x1
	printf "0xAE:0x000e        0x07 | rw | ST25DV_SYS_MB_WDG (mailbox watchdog register).value (f=0x07): 0x%02x\n", $ST25DV_SYS_MB_WDG
	printf "0xAE:0x000e        0x07 | rw | ST25DV_SYS_MB_WDG (mailbox watchdog register).MB_WDG (msg released never/0 or 2^(MB_WDG-1)*30 ms duration bits): %x\n", $ST25DV_SYS_MB_WDG&0x7
	printf "0xAE:0x000f             | rw | ST25DV_SYS_LOCK_CFG (RF write-protect sys-regs registers)\n"
	printf "0xAE:0x0010             | r  | ST25DV_SYS_LOCK_DSFID (DSFID lock status registers)\n"
	printf "0xAE:0x0011             | r  | ST25DV_SYS_LOCK_AFI (AFI lock status registers)\n"
	printf "0xAE:0x0012             | r  | ST25DV_SYS_DSFID (data storage family identifier register)\n"
	printf "0xAE:0x0013             | r  | ST25DV_SYS_AFI (application family identifier)\n"
	printf "0xAE:0x0014+2           | r  | ST25DV_SYS_MEM_SIZEA (u16 memory size value in blocks)\n"
	printf "0xAE:0x0016             | r  | ST25DV_SYS_BLK_SIZE (block size in bytes)\n"
	printf "0xAE:0x0017             | r  | ST25DV_SYS_IC_REF (IC reference value)\n"
	printf "0xAE:0x0018+8           | r  | ST25DV_SYS_UID (u64 iso15693 unique identifier register)\n"
	printf "0xAE:0x0020             | r  | ST25DV_SYS_IC_REV (integrated circuit revision)\n"
	printf "0xAE:0x0900+8           | rw | ST25DV_SYS_I2CPW (I2C security session password register)\n"
	printf "0xAE:N/A+8              |  w | ST25DV_SYS_RFCONFPW (u64 RF configuration register)\n"
	printf "0xAE:N/A+8              |  w | ST25DV_SYS_RFUSER2PW (u64 RF user area 2 access password register)\n"
	printf "0xAE:N/A+8              |  w | ST25DV_SYS_RFUSER3PW (u64 RF user area 3 access password register)\n"
	printf "0xAE:N/A+8              |  w | ST25DV_SYS_RFUSER4PW (u64 RF user area 4 access password register)\n"

	printf "0xA6:0x2000             | rw | ST25DV_DYN_GPOCTRLR (general purpose output control register)\n"
	printf "0xA6:0x2002             | r  | ST25DV_DYN_EHCTRLR (energy harvesting control register)\n"
	printf "0xA6:0x2003             | rw | ST25DV_DYN_RFMNGTR (rf interface management register)\n"
	printf "0xA6:0x2004             | r  | ST25DV_DYN_I2CSSOR (i2c secure session open status register)\n"
	printf "0xA6:0x2005             | r  | ST25DV_DYN_ITSTSR (interrupt status register)\n"
	printf "0xA6:0x2006        0xff | rw | ST25DV_DYN_MBCTRLR (mailbox control and status register).value (f=0x00): 0x%02x\n", $ST25DV_DYN_MB_CTRL
	printf "0xA6:0x2006        0x01 | rw | ST25DV_DYN_MBCTRLR (mailbox control and status register).MB_EN (w!MB_MODE==1; ftm enable bit): 0x%02x\n", $ST25DV_DYN_MB_CTRL&0x1
	printf "0xA6:0x2006        0x02 | rw | ST25DV_DYN_MBCTRLR (mailbox control and status register).HOST_PUT_MSG (i2c put msg in mb flag): 0x%02x\n", $ST25DV_DYN_MB_CTRL>>1&0x1
	printf "0xA6:0x2006        0x04 | rw | ST25DV_DYN_MBCTRLR (mailbox control and status register).RF_PUT_MSG (rf put msg in mb flag): 0x%02x\n", $ST25DV_DYN_MB_CTRL>>2&0x1
	printf "0xA6:0x2007             | r  | ST25DV_DYN_MBLENR (mailbox message length register)\n"
	printf "** DeviceAddr:TargetAddr * I2C HDC2080 humidity & temperature sensor **\n"
	printf "0x80:0x00        0xfffc | r  | HDC2080_TEMP (temperature register).TEMP (C=./65536*165-40; temperature value bits): %f C\n", (float)$HDC2080_TEMP / 65536 * 165 - 40
	printf "0x80:0x00        0xfffc | r  | HDC2080_TEMP (temperature register).value (r=0x0000): 0x%04x\n", $HDC2080_TEMP
	printf "0x80:0x02        0xfffc | r  | HDC2080_HUMID (humidity register).HUMID (%rH=./65536*100; relative humidity value bits): %f %rH\n", (float)$HDC2080_HUMID / 65536 * 100
	printf "0x80:0x02        0xfffc | r  | HDC2080_HUMID (humidity register).value (r=0x0000): 0x%04x\n", $HDC2080_HUMID

	printf "0x80:0x04          0x08 | rcr| HDC2080_STATUS (interrupt DRDY/INT status register).HL (humidity below lower threshold flag): %x\n", $HDC2080_STATUS>>3&0x1
	printf "0x80:0x04          0x10 | rcr| HDC2080_STATUS (interrupt DRDY/INT status register).HH (humidity above upper threshold flag): %x\n", $HDC2080_STATUS>>4&0x1
	printf "0x80:0x04          0x20 | rcr| HDC2080_STATUS (interrupt DRDY/INT status register).TL (temperature below lower threshold flag): %x\n", $HDC2080_STATUS>>5&0x1
	printf "0x80:0x04          0x40 | rcr| HDC2080_STATUS (interrupt DRDY/INT status register).TH (temperature above upper threshold flag): %x\n", $HDC2080_STATUS>>6&0x1
	printf "0x80:0x04          0x80 | rcr| HDC2080_STATUS (interrupt DRDY/INT status register).DRDY (data ready flag): %x\n", $HDC2080_STATUS>>7&0x1
	printf "0x80:0x04          0xf8 | rcr| HDC2080_STATUS (interrupt DRDY/INT status register).value (r=0x00): 0x%02x\n", $HDC2080_STATUS

	printf "0x80:0x05          0xff | r  | HDC2080_MAX_TEMP (peak temperature register).TMAX (C=./256*165-40; deduced only from manual measurements; peak value bits): %f C\n", (float)$HDC2080_MAX_TEMP / 256 * 165 - 40
	printf "0x80:0x05          0xff | r  | HDC2080_MAX_TEMP (peak temperature register).value (r=0x00): 0x%02x\n", $HDC2080_MAX_TEMP
	printf "0x80:0x06          0xff | r  | HDC2080_MAX_HUMID (peak humidity register).HMAX (%rH=./256*100; deduced only from manual measurements; peak value bits): %f %rH\n", (float)$HDC2080_MAX_HUMID / 256 * 100
	printf "0x80:0x06          0xff | r  | HDC2080_MAX_HUMID (peak humidity register).value (r=0x00): 0x%02x\n", $HDC2080_MAX_HUMID

	printf "0x80:0x07          0x08 | rw | HDC2080_CONFIG_INT_EN (interupt enable register).HL_EN (humidity lower threshold enable bit): %x\n", $HDC2080_INTERRUPT_ENABLE>>3&0x1
	printf "0x80:0x07          0x10 | rw | HDC2080_CONFIG_INT_EN (interupt enable register).HH_EN (humidity upper threshold enable bit): %x\n", $HDC2080_INTERRUPT_ENABLE>>4&0x1
	printf "0x80:0x07          0x20 | rw | HDC2080_CONFIG_INT_EN (interupt enable register).TL_EN (temperature lower threshold enable bit): %x\n", $HDC2080_INTERRUPT_ENABLE>>5&0x1
	printf "0x80:0x07          0x40 | rw | HDC2080_CONFIG_INT_EN (interupt enable register).TH_EN (temperature upper threshold enable bit): %x\n", $HDC2080_INTERRUPT_ENABLE>>6&0x1
	printf "0x80:0x07          0x80 | rw | HDC2080_CONFIG_INT_EN (interupt enable register).DRDY_EN (data ready interrupt enable bit): %x\n", $HDC2080_INTERRUPT_ENABLE>>7&0x1
	printf "0x80:0x07          0xf8 | rw | HDC2080_CONFIG_INT_EN (interupt enable register).value (r=0x00): 0x%02x\n", $HDC2080_INTERRUPT_ENABLE

	printf "0x80:0x08          0xff | rw | HDC2080_OFFSET_TEMP (TODO).value (r=0x00): 0x%02x\n", $HDC2080_OFFSET_TEMP
	printf "0x80:0x09          0xff | rw | HDC2080_OFFSET_HUMID (TODO).value (r=0x00): 0x%02x\n", $HDC2080_OFFSET_HUMID

	printf "0x80:0x0a          0xff | rw | HDC2080_THRES_TEMP_LOW (temperature lower threshold register).TL_THR (C=./256*165-40; threshold value bits): %f C\n", (float)$HDC2080_THRES_TEMP_LOW / 256 * 165 - 40
	printf "0x80:0x0a          0xff | rw | HDC2080_THRES_TEMP_LOW (temperature lower threshold register).value (r=0x00): 0x%02x\n", $HDC2080_THRES_TEMP_LOW
	printf "0x80:0x0b          0xff | rw | HDC2080_THRES_TEMP_HIGH (temperature upper threshold register).TH_THR (C=./256*165-40; threshold value bits): %f C\n", (float)$HDC2080_THRES_TEMP_HIGH / 256 * 165 - 40
	printf "0x80:0x0b          0xff | rw | HDC2080_THRES_TEMP_HIGH (temperature upper threshold register).value (r=0x00): 0x%02x\n", $HDC2080_THRES_TEMP_HIGH
	printf "0x80:0x0c          0xff | rw | HDC2080_THRES_HUMID_LOW (humidity lower threshold register).HL_THR (%rH=./256*100; threshold value bits): %f %rH\n", (float)$HDC2080_THRES_HUMID_LOW / 256 * 100
	printf "0x80:0x0c          0xff | rw | HDC2080_THRES_HUMID_LOW (humidity lower threshold register).value (r=0x00): 0x%02x\n", $HDC2080_THRES_HUMID_LOW
	printf "0x80:0x0d          0xff | rw | HDC2080_THRES_HUMID_HIGH (humidity uppoer threshold register).HH_THR (%rH=./256*100; theshold value bits): %f %rH\n", (float)$HDC2080_THRES_HUMID_HIGH / 256 * 100
	printf "0x80:0x0d          0xff | rw | HDC2080_THRES_HUMID_HIGH (humidity uppoer threshold register).value (r=0x00): 0x%02x\n", $HDC2080_THRES_HUMID_HIGH

	printf "0x80:0x0e          0x01 | rw | HDC2080_CONFIG (reset and DRDY/INT configuration register).INT_MODE (0:latched 1:comparator interrupt mode bit): %x\n", $HDC2080_CONFIG&0x1
	printf "0x80:0x0e          0x02 | rw | HDC2080_CONFIG (reset and DRDY/INT configuration register).INT_POL (0:low 1:high active output level on INT pin bit): %x\n", $HDC2080_CONFIG>>1&0x1
	printf "0x80:0x0e          0x04 | rw | HDC2080_CONFIG (reset and DRDY/INT configuration register).INT_EN (0:HiZ interrupt enable bit): %x\n", $HDC2080_CONFIG>>2&0x1
	printf "0x80:0x0e          0x08 | rw | HDC2080_CONFIG (reset and DRDY/INT configuration register).HEAT_EN (turn on heater element bit): %x\n", $HDC2080_CONFIG>>3&0x1
	printf "0x80:0x0e          0x70 | rw | HDC2080_CONFIG (reset and DRDY/INT configuration register).AMM (0:never 1:2m 2:1m 3:10s 4:5s 5:1s 6:500ms 7:200ms; auto measurement mode bits): %x\n", $HDC2080_CONFIG>>4&0x7
	printf "0x80:0x0e          0x80 |  w | HDC2080_CONFIG (reset and DRDY/INT configuration register).SOFT_RES (reset IC via software bit): %x\n", $HDC2080_CONFIG>>7&0x1
	printf "0x80:0x0e          0xff | rw | HDC2080_CONFIG (reset and DRDY/INT configuration register).value (r=0x00): 0x%02x\n", $HDC2080_CONFIG

	printf "0x80:0x0f          0x01 | rw | HDC2080_MEASURE (measurement configuration register).MEAS_TRIG (trigger manual measurement bit): %x\n", $HDC2080_MEASURE&0x1
	printf "0x80:0x0f          0x06 | rw | HDC2080_MEASURE (measurement configuration register).MEAS_CONF (0:humid+temp 1:temp-only; measurement mode bits): %x\n", $HDC2080_MEASURE>>1&0x3
	printf "0x80:0x0f          0x30 | rw | HDC2080_MEASURE (measurement configuration register).HRES (0:14bit 1:11bit 2:9bit; humidity resolution bits): %x\n", $HDC2080_MEASURE>>4&0x3
	printf "0x80:0x0f          0xc0 | rw | HDC2080_MEASURE (measurement configuration register).TRES (0:14bit 1:11bit 2:9bit; temperature resolution bits): %x\n", $HDC2080_MEASURE>>6&0x3
	printf "0x80:0x0f          0xf7 | rw | HDC2080_MEASURE (measurement configuration register).value (r=0x00): 0x%02x\n", $HDC2080_MEASURE

	printf "0x80:0xfc        0xffff | r  | HDC2080_ID_MANUFACTURER (manufacturer ID value bits).value (r=0x5449; identifies device is by Texas Instruments): 0x%04x\n", $HDC2080_ID_MANUFACTURER
	printf "0x80:0xfe        0xffff | r  | HDC2080_ID_DEVICE (device ID value bits).value (r=0x07d0; identifies device is an HDC2080): 0x%04x\n", $HDC2080_ID_DEVICE

	printf "** DeviceAddr:TargetAddr * I2C SFH7776 ambient light & proximity sensor **\n"
	printf "0x72:0x40          0x07 | r  | SFH7776_SYSTEM_CONTROL (system control register).PART_ID (1:always; part id bits): %x\n", $SFH7776_SYSTEM_CONTROL&0x7
	printf "0x72:0x40          0x38 | r  | SFH7776_SYSTEM_CONTROL (system control register).MANUF_ID (1:always; manufacturer id bits): %x\n", $SFH7776_SYSTEM_CONTROL>>3&0x7
	printf "0x72:0x40          0x40 |  w | SFH7776_SYSTEM_CONTROL (system control register).INT_RESET (???): %x\n", $SFH7776_SYSTEM_CONTROL>>6&0x1
	printf "0x72:0x40          0x80 |  w | SFH7776_SYSTEM_CONTROL (system control register).SW_RESET (reset IC via software bit): %x\n", $SFH7776_SYSTEM_CONTROL>>7&0x1
	printf "0x72:0x40          0xff | rw | SFH7776_SYSTEM_CONTROL (system control register).value (r=0x09): 0x%02x\n", $SFH7776_SYSTEM_CONTROL

	printf "0x72:0x41          0x0f | rw | SFH7776_MODE_CONTROL (ALS and PS timing control register).RATE_MODE (0:none 1:_10 2:_40 3:_100 4:_400 5:100_ 6:100_100 7:100_400 8:100/400_ 9:100/400_100 a:400_ b:400_400 c:50_50 as ALSint/ALSrep_PSrep in ms; measurement repetition rate mode bits): %x\n", $SFH7776_SYSTEM_CONTROL&0xf
	printf "0x72:0x41          0x10 | rw | SFH7776_MODE_CONTROL (ALS and PS timing control register).PS_MODE (0:normal 1:two_pulse; PS mode bits): %x\n", $SFH7776_SYSTEM_CONTROL>>4&1
	printf "0x72:0x41          0x1f | rw | SFH7776_MODE_CONTROL (ALS and PS timing control register).value (r=0x00): 0x%02x\n", $SFH7776_SYSTEM_CONTROL

	printf "0x72:0x42          0x03 | rw | SFH7776_ALS_PS_CONTROL (ALS and PS gain control register).LED_I (mA=25*2^. 0:25 1:50 2:100 3:200 mA; LED current bits): %x\n", $SFH7776_ALS_PS_CONTROL&0x3
	printf "0x72:0x42          0x3c | rw | SFH7776_ALS_PS_CONTROL (ALS and PS gain control register).ALS_GAIN (0:1 4:2_1 5:2 a:64 e:128_64 f:128 VIS_IR as x1 gain; ALS gain bits): %x\n", $SFH7776_ALS_PS_CONTROL>>2&0xf
	printf "0x72:0x42          0x40 | rw | SFH7776_ALS_PS_CONTROL (ALS and PS gain control register).PS_OUT (0:proximity 1:infrared output mode bit): %x\n", $SFH7776_ALS_PS_CONTROL>>6&0x1
	printf "0x72:0x42          0x7f | rw | SFH7776_ALS_PS_CONTROL (ALS and PS gain control register).value (r=0x03): 0x%02x\n", $SFH7776_ALS_PS_CONTROL

	printf "0x72:0x43          0x0f | rw | SFH7776_PERSISTENCE (PS interrupt persistence control register).PERSISTANCE (N=. 0:active?; interrupt if threshold lasts N measurements bits): %x\n", $SFH7776_PERSISTENCE&0xf
	printf "0x72:0x43          0x0f | rw | SFH7776_PERSISTENCE (PS interrupt persistence control register).value (r=0x01): 0x%02x\n", $SFH7776_PERSISTENCE

	printf "0x72:0x44+2      0xffff | r  | SFH7776_PS_DATA (PS data register).value (r=0x0000): 0x%04x\n", $SFH7776_PS_DATA
	printf "0x72:0x44+2      0xffff | r  | SFH7776_PS_DATA (PS data register).value (r=0x0000): 0x%04x\n", $SFH7776_PS_DATA
	printf "0x72:0x46+2      0xffff | r  | SFH7776_ALS_VIS_DATA (ALS visible data register).value (r=0x0000): 0x%04x\n", $SFH7776_ALS_VIS_DATA
	printf "0x72:0x48+2      0xffff | r  | SFH7776_ALS_IR_DATA (ALS infrared data register).value (r=0x0000): 0x%04x\n", $SFH7776_ALS_IR_DATA

	printf "0x72:0x4a          0x03 | rw | SFH7776_INTERRUPT_CONTROL (Interrupt control register).INT_EN (0:disable 1:PS 2:ALS 3:PS+ALS; interrupt enable bits): %x\n", $SFH7776_INTERRUPT_CONTROL&0x3
	printf "0x72:0x4a          0x04 | rw | SFH7776_INTERRUPT_CONTROL (Interrupt control register).INT_LATCH (0:'lateched until read' 1:'update each measure'; interrupt latch mode bits): %x\n", $SFH7776_INTERRUPT_CONTROL>>2&0x1
	printf "0x72:0x4a          0x08 | rw | SFH7776_INTERRUPT_CONTROL (Interrupt control register).INT_ASSERT (0:'keep stable' 1:'de-assert re-assert' if next measurement results in int active; interrupt assert mode bits): %x\n", $SFH7776_INTERRUPT_CONTROL>>3&0x1
	printf "0x72:0x4a          0x30 | rw | SFH7776_INTERRUPT_CONTROL (Interrupt control register).INT_MODE (0:high_only 1:hysteresis 2:outside; PS high/low interrupt threshold trigger mode bits): %x\n", $SFH7776_INTERRUPT_CONTROL>>4&0x3
	printf "0x72:0x4a          0x40 | rcr| SFH7776_INTERRUPT_CONTROL (Interrupt control register).ALS_STAT (ALS VIS interrupt flag): %x\n", $SFH7776_INTERRUPT_CONTROL>>6&0x1
	printf "0x72:0x4a          0x80 | rcr| SFH7776_INTERRUPT_CONTROL (Interrupt control register).PS_STAT (PS interrupt flag): %x\n", $SFH7776_INTERRUPT_CONTROL>>7&0x1
	printf "0x72:0x4a          0xff | rw | SFH7776_INTERRUPT_CONTROL (Interrupt control register).value (r=0x00): 0x%02x\n", $SFH7776_INTERRUPT_CONTROL

	printf "0x72:0x4b+2      0xffff | rw | SFH7776_PS_TH (PS upper threshold register).value (r=0xffff): 0x%04x\n", $SFH7776_PS_TH
	printf "0x72:0x4d+2      0xffff | rw | SFH7776_PS_TL (PS lower threshold register).value (r=0x0000): 0x%04x\n", $SFH7776_PS_TL
	printf "0x72:0x4f+2      0xffff | rw | SFH7776_ALS_VIS_TH (ALS upper threshold register).value (r=0xffff): 0x%04x\n", $SFH7776_ALS_VIS_TH
	printf "0x72:0x51+2      0xffff | rw | SFH7776_ALS_VIS_TL (ALS lower threshold register).value (r=0x0000): 0x%04x\n", $SFH7776_ALS_VIS_TL

	printf "** DeviceAddr:TargetAddr * I2C BMA400 accelerometer & temperature sensor **\n"
	printf "0x28:0x00          0xff | r  | BMA400_CHIPID (chip identification register).value (r=0x90): 0x%02x\n", $BMA400_CHIPID

	printf "0x28:0x02          0x02 | rcr| BMA400_ERR_REG (error register).cmd_err (b!cmd; command execution failed flag): %x\n", $BMA400_ERR_REG>>1&0x1
	printf "0x28:0x02          0x02 | rcr| BMA400_ERR_REG (error register).value (r=0x00): 0x%02x\n", $BMA400_ERR_REG
	printf "0x28:0x03          0x01 | r  | BMA400_STATUS (status register).int_active (one of the interrupts triggered flag): %x\n", $BMA400_STATUS&0x1
	printf "0x28:0x03          0x06 | r  | BMA400_STATUS (status register).power_mode_stat (0:sleep 1:low-power 2:normal power mode flag): %x\n", $BMA400_STATUS>>1&0x3
	printf "0x28:0x03          0x10 | r  | BMA400_STATUS (status register).cmd_rdy (b!cmd; command interpreter 0:busy 1:ready flag): %x\n", $BMA400_STATUS>>4&0x1
	printf "0x28:0x03          0x80 | rcr| BMA400_STATUS (status register).drdy_stat (accelerometer data refreshed flag): %x\n", $BMA400_STATUS>>7&0x1
	printf "0x28:0x03          0x97 | rcr| BMA400_STATUS (status register).value (r=0x00): 0x%02x\n", $BMA400_STATUS
	printf "0x28:0x04+2      0x0fff |ir  | BMA400_ACC_X (acceleration X-axis registers).acc_x (signed two's complement value): %d\n", $BMA400_ACC_X - ($BMA400_ACC_X >> 11 ? 4096 : 0)
	printf "0x28:0x04+2      0x0fff | r  | BMA400_ACC_X (acceleration X-axis registers).value (r=0x0000): 0x%04x\n", $BMA400_ACC_X
	printf "0x28:0x06+2      0x0fff |ir  | BMA400_ACC_Y (acceleration Y-axis registers).acc_y (signed two's complement value): %d\n", $BMA400_ACC_Y - ($BMA400_ACC_Y >> 11 ? 4096 : 0)
	printf "0x28:0x06+2      0x0fff | r  | BMA400_ACC_Y (acceleration Y-axis registers).value (r=0x0000): 0x%04x\n", $BMA400_ACC_Y
	printf "0x28:0x08+2      0x0fff |ir  | BMA400_ACC_Z (acceleration Z-axis registers).acc_x (signed two's complement value): %d\n", $BMA400_ACC_Z - ($BMA400_ACC_Z >> 11 ? 4096 : 0)
	printf "0x28:0x08+2      0x0fff | r  | BMA400_ACC_Z (acceleration Z-axis registers).value (r=0x0000): 0x%04x\n", $BMA400_ACC_Z
	printf "0x28:0x0a+3   0xff_ffff |ir  | BMA400_SENSOR_TIME (internal sensor time registers).sensor_time (time=.*312us; seconds value): %f\n", $BMA400_SENSORTIME * 0.0003125
	printf "0x28:0x0a+3   0xff_ffff | r  | BMA400_SENSOR_TIME (internal sensor time registers).value (r=0x00_0000): 0x%02x_%04x\n", $BMA400_SENSORTIME>>16, BMA400_SENSORTIME&0xffff
	printf "0x28:0x0d          0x01 | rcr| BMA400_EVENT (event status register).por_detected (power-on or software reset happened flag): %x\n", $BMA400_EVENT&0x1
	printf "0x28:0x0d          0x01 | rcr| BMA400_EVENT (event status register).value (r=0x00_0000): 0x%02x\n", $BMA400_EVENT
	printf "0x28:0x0e+3   0x00_0001 | r  | BMA400_INT_STAT (interrupt status registers).wkup (wakeup flag): %x\n", $BMA400_INT_STAT&0x1
	printf "0x28:0x0e+3   0x00_0002 | r  | BMA400_INT_STAT (interrupt status registers).orientch (orientation changed flag): %x\n", $BMA400_INT_STAT>>1&0x1
	printf "0x28:0x0e+3   0x00_0004 | r  | BMA400_INT_STAT (interrupt status registers).gen1 (generic interrupt 1 flag): %x\n", $BMA400_INT_STAT>>2&0x1
	printf "0x28:0x0e+3   0x00_0008 | r  | BMA400_INT_STAT (interrupt status registers).gen2 (generic interrupt 2 flag): %x\n", $BMA400_INT_STAT>>3&0x1
	printf "0x28:0x0e+3   0x00_0010 | rcr| BMA400_INT_STAT (interrupt status registers).ieng_overrun (always latched; interrupt engine couldn't finish all enabled calculations before next sample flag): %x\n", $BMA400_INT_STAT>>4&0x1
	printf "0x28:0x0e+3   0x00_0020 | r  | BMA400_INT_STAT (interrupt status registers).ffull (FIFO full flag): %x\n", $BMA400_INT_STAT>>5&0x1
	printf "0x28:0x0e+3   0x00_0040 | r  | BMA400_INT_STAT (interrupt status registers).fwm (FIFO watermark flag): %x\n", $BMA400_INT_STAT>>6&0x1
	printf "0x28:0x0e+3   0x00_0080 | r  | BMA400_INT_STAT (interrupt status registers).drdy (data ready flag): %x\n", $BMA400_INT_STAT>>7&0x1
	printf "0x28:0x0e+3   0x00_0300 | r  | BMA400_INT_STAT (interrupt status registers).step (0:no 1:one 2:more step detected flag): %x\n", $BMA400_INT_STAT>>8&0x3
	printf "0x28:0x0e+3   0x00_0400 | r  | BMA400_INT_STAT (interrupt status registers).s_tap (single tap detected flag): %x\n", $BMA400_INT_STAT>>10&0x1
	printf "0x28:0x0e+3   0x00_0800 | r  | BMA400_INT_STAT (interrupt status registers).d_tap (double tap detected flag): %x\n", $BMA400_INT_STAT>>11&0x1
	printf "0x28:0x0e+3   0x00_1000 | rcr| BMA400_INT_STAT (interrupt status registers).ieng_overrun (always latched; interrupt engine couldn't finish all enabled calculations before next sample flag): %x\n", $BMA400_INT_STAT>>12&0x1
	printf "0x28:0x0e+3   0x01_0000 | r  | BMA400_INT_STAT (interrupt status registers).actc_x (x-axis activity change detected flag): %x\n", $BMA400_INT_STAT>>13&0x1
	printf "0x28:0x0e+3   0x02_0000 | r  | BMA400_INT_STAT (interrupt status registers).actc_y (y-axis activity change detected flag): %x\n", $BMA400_INT_STAT>>14&0x1
	printf "0x28:0x0e+3   0x04_0000 | r  | BMA400_INT_STAT (interrupt status registers).actc_z (z-axis activity change detected flag): %x\n", $BMA400_INT_STAT>>15&0x1
	printf "0x28:0x0e+3   0x10_0000 | rcr| BMA400_INT_STAT (interrupt status registers).ieng_overrun (always latched; interrupt engine couldn't finish all enabled calculations before next sample flag): %x\n", $BMA400_INT_STAT>>20&0x1
	printf "0x28:0x0e+3   0x17_1fff | r  | BMA400_INT_STAT (interrupt status registers).value (r=0x00_0000): 0x%02x_%04x\n", $BMA400_INT_STAT>>16, BMA400_INT_STAT&0xffff
	printf "0x28:0x11          0xff | r  | BMA400_TEMP_DATA (temperature register).temp_data (temp=./2+23; probably celsius value): %f\n", $BMA400_TEMP_DATA*0.5+23
	printf "0x28:0x11          0xff | r  | BMA400_TEMP_DATA (temperature register).value (r=0x00): 0x%02x\n", $BMA400_TEMP_DATA
	printf "0x28:0x12+2      0x07ff | r  | BMA400_FIFO_LENGTH (fifo length registers).fifo_bytes_cnt (number of bytes stored in FIFO): 0x%04x\n", $BMA400_FIFO_LENGTH&0x7ff
	printf "0x28:0x12+2      0x07ff | r  | BMA400_FIFO_LENGTH (fifo length registers).value (r=0x0000): 0x%04x\n", $BMA400_FIFO_LENGTH
	printf "0x28:0x14          0xff | rwr| BMA400_FIFO_DATA (fifo data register).fifo_data (i2c auto-increment hangs here; 1KB FIFO data bitfield): 0x%02x\n", $BMA400_FIFO_DATA
	printf "0x28:0x14          0xff | rwr| BMA400_FIFO_DATA (fifo data register).value (r=0x00): 0x%02x\n", $BMA400_FIFO_DATA
	printf "0x28:0x15+3   0xff_ffff | r  | BMA400_STEP_CNT (step counter registers).step_cnt (number of steps detected bitfield): 0x%02x_%04x\n", $BMA400_STEP_CNT>>16, $BMA400_STEP_CNT&0xffff
	printf "0x28:0x15+3   0xff_ffff | r  | BMA400_STEP_CNT (step counter registers).value (r=0x00_0000): 0x%02_%04x\n", $BMA400_STEP_CNT>>16, $BMA400_STEP_CNT&0xffff
	printf "0x28:0x18          0x03 | r  | BMA400_STEP_STAT (step state register).step_stat (detected 0:still 1:walk 2:run activity): %x\n", $BMA400_STEP_STAT&0x3
	printf "0x28:0x18          0x03 | r  | BMA400_STEP_STAT (step state register).value (r=0x00): 0x%02x\n", $BMA400_STEP_STAT
	printf "0x28:0x19+3   0x00_0003 | rw | BMA400_ACC_CONFIG (accelerometer config registers).power_mode_conf (0:sleep 1:lowpower 2:normal power mode bits): %x\n", $BMA400_ACC_CONFIG&0x3
	printf "0x28:0x19+3   0x00_0060 | rw | BMA400_ACC_CONFIG (accelerometer config registers).osr_lp (oversampling rate in low power mode bits): %x\n", $BMA400_ACC_CONFIG>>5&0x3
	printf "0x28:0x19+3   0x00_0080 | rw | BMA400_ACC_CONFIG (accelerometer config registers).filt1_bw (0:0.48*ODR 1:0.24*ODR; filt1 output bandwidth mode bits): %x\n", $BMA400_ACC_CONFIG>>7&0x1
	printf "0x28:0x19+3   0x00_0f00 | rw | BMA400_ACC_CONFIG (accelerometer config registers).acc_odr (5:12.5 6:25 7:50 8:100 9:200 a:400 b:800 Hz; accelerometer output data rate bits): %x\n", $BMA400_ACC_CONFIG>>8&0xf
	printf "0x28:0x19+3   0x00_3000 | rw | BMA400_ACC_CONFIG (accelerometer config registers).osr (0:low-power vs 3:accuracy; oversampling rate in normal mode bits): %x\n", $BMA400_ACC_CONFIG>>12&0x3
	printf "0x28:0x19+3   0x00_c000 | rw | BMA400_ACC_CONFIG (accelerometer config registers).acc_range (0..3:'2 4 8 16 +/-g'; accelerometer measurement range bits): %x\n", $BMA400_ACC_CONFIG>>14&0x3
	printf "0x28:0x19+3   0x0c_0000 | rw | BMA400_ACC_CONFIG (accelerometer config registers).data_src_reg (0:'acc_filt1' 1:'acc_filt2' 2:'acc_filt_lp'; source for data registers bitfield): %x\n", $BMA400_ACC_CONFIG>>18&0x3
	printf "0x28:0x19+3   0x0c_ffe3 | rw | BMA400_ACC_CONFIG (accelerometer config registers).value (r=0x00_4900): 0x%02x_%04x\n", $BMA400_ACC_CONFIG>>16, $BMA400_ACC_CONFIG&0xffff

	printf "0x28:0x1f+2      0x0002 | rw | BMA400_INT_CONFIG (interrupt config registers).orientch_int_en (orientation changed interrupt enable bit): %x\n", $BMA400_INT_CONFIG>>1&0x1
	printf "0x28:0x1f+2      0x0004 | rw | BMA400_INT_CONFIG (interrupt config registers).gen1_int_en (generic interrupt 1 enable bit): %x\n", $BMA400_INT_CONFIG>>2&0x1
	printf "0x28:0x1f+2      0x0008 | rw | BMA400_INT_CONFIG (interrupt config registers).gen2_int_en (generic interrupt 2 enable bit): %x\n", $BMA400_INT_CONFIG>>3&0x1
	printf "0x28:0x1f+2      0x0020 | rw | BMA400_INT_CONFIG (interrupt config registers).ffull_int_en (FIFO full interrupt enable bit): %x\n", $BMA400_INT_CONFIG>>5&0x1
	printf "0x28:0x1f+2      0x0040 | rw | BMA400_INT_CONFIG (interrupt config registers).fwm_int_en (FIFO watermark interrupt enable bit): %x\n", $BMA400_INT_CONFIG>>6&0x1
	printf "0x28:0x1f+2      0x0080 | rw | BMA400_INT_CONFIG (interrupt config registers).drdy_int_en (data ready interrupt enable bit): %x\n", $BMA400_INT_CONFIG>>7&0x1
	printf "0x28:0x1f+2      0x0100 | rw | BMA400_INT_CONFIG (interrupt config registers).step_int_en (step detected interrupt enable bit): %x\n", $BMA400_INT_CONFIG>>8&0x1
	printf "0x28:0x1f+2      0x0400 | rw | BMA400_INT_CONFIG (interrupt config registers).s_tap_int_en (single tap interrupt enable bit): %x\n", $BMA400_INT_CONFIG>>10&0x1
	printf "0x28:0x1f+2      0x0800 | rw | BMA400_INT_CONFIG (interrupt config registers).d_tap_int_en (double tap interrupt enable bit): %x\n", $BMA400_INT_CONFIG>>11&0x1
	printf "0x28:0x1f+2      0x1000 | rw | BMA400_INT_CONFIG (interrupt config registers).actch_int_en (activity changed interrupt enable bit): %x\n", $BMA400_INT_CONFIG>>12&0x1
	printf "0x28:0x1f+2      0x8000 | rw | BMA400_INT_CONFIG (interrupt config registers).latch_int (latched interrupt mode bit): %x\n", $BMA400_INT_CONFIG>>15&0x1
	printf "0x28:0x1f+2      0x9dee | rw | BMA400_INT_CONFIG (interrupt config registers).value (r=0x0000): 0x%04x\n", $BMA400_INT_CONFIG
	printf "0x28:0x21          0x01 | rw | BMA400_INT1_MAP (pin INT1 interrupt map register).wkup_int1 (wakeup interrupt mapped to INT1 pin bit): %x\n", $BMA400_INT1_MAP&0x1
	printf "0x28:0x21          0x02 | rw | BMA400_INT1_MAP (pin INT1 interrupt map register).orientch_int1 (orientation changed interrupt mapped to INT1 pin bit): %x\n", $BMA400_INT1_MAP>>1&0x1
	printf "0x28:0x21          0x04 | rw | BMA400_INT1_MAP (pin INT1 interrupt map register).gen1_int1 (generic interrupt 1 mapped to INT1 pin bit): %x\n", $BMA400_INT1_MAP>>2&0x1
	printf "0x28:0x21          0x08 | rw | BMA400_INT1_MAP (pin INT1 interrupt map register).gen2_int1 (generic interrupt 2 mapped to INT1 pin bit): %x\n", $BMA400_INT1_MAP>>3&0x1
	printf "0x28:0x21          0x10 | rw | BMA400_INT1_MAP (pin INT1 interrupt map register).ieng_overrun_int1 (interrupt overrun mapped to INT1 pin bit): %x\n", $BMA400_INT1_MAP>>4&0x1
	printf "0x28:0x21          0x20 | rw | BMA400_INT1_MAP (pin INT1 interrupt map register).ffull_int1 (FIFO full interrupt mapped to INT1 pin bit): %x\n", $BMA400_INT1_MAP>>5&0x1
	printf "0x28:0x21          0x40 | rw | BMA400_INT1_MAP (pin INT1 interrupt map register).fwm_int1 (FIFO watermark interrupt mapped to INT1 pin bit): %x\n", $BMA400_INT1_MAP>>6&0x1
	printf "0x28:0x21          0x80 | rw | BMA400_INT1_MAP (pin INT1 interrupt map register).drdy_int1 (data ready interrupt mapped to INT1 pin bit): %x\n", $BMA400_INT1_MAP>>7&0x1
	printf "0x28:0x21          0xff | rw | BMA400_INT1_MAP (pin INT1 interrupt map register).value (r=0x00): 0x%02x\n", $BMA400_INT1_MAP
	printf "0x28:0x22          0x01 | rw | BMA400_INT2_MAP (pin INT2 interrupt map register).wkup_int2 (wakeup interrupt mapped to INT2 pin bit): %x\n", $BMA400_INT2_MAP&0x1
	printf "0x28:0x22          0x02 | rw | BMA400_INT2_MAP (pin INT2 interrupt map register).orientch_int2 (orientation changed interrupt mapped to INT2 pin bit): %x\n", $BMA400_INT2_MAP>>1&0x1
	printf "0x28:0x22          0x04 | rw | BMA400_INT2_MAP (pin INT2 interrupt map register).gen1_int2 (generic interrupt 1 mapped to INT2 pin bit): %x\n", $BMA400_INT2_MAP>>2&0x1
	printf "0x28:0x22          0x08 | rw | BMA400_INT2_MAP (pin INT2 interrupt map register).gen2_int2 (generic interrupt 2 mapped to INT2 pin bit): %x\n", $BMA400_INT2_MAP>>3&0x1
	printf "0x28:0x22          0x10 | rw | BMA400_INT2_MAP (pin INT2 interrupt map register).ieng_overrun_int2 (interrupt overrun mapped to INT2 pin bit): %x\n", $BMA400_INT2_MAP>>4&0x1
	printf "0x28:0x22          0x20 | rw | BMA400_INT2_MAP (pin INT2 interrupt map register).ffull_int2 (FIFO full interrupt mapped to INT2 pin bit): %x\n", $BMA400_INT2_MAP>>5&0x1
	printf "0x28:0x22          0x40 | rw | BMA400_INT2_MAP (pin INT2 interrupt map register).fwm_int2 (FIFO watermark interrupt mapped to INT2 pin bit): %x\n", $BMA400_INT2_MAP>>6&0x1
	printf "0x28:0x22          0x80 | rw | BMA400_INT2_MAP (pin INT2 interrupt map register).drdy_int2 (data ready interrupt mapped to INT2 pin bit): %x\n", $BMA400_INT2_MAP>>7&0x1
	printf "0x28:0x22          0xff | rw | BMA400_INT2_MAP (pin INT2 interrupt map register).value (r=0x00): 0x%02x\n", $BMA400_INT2_MAP
	printf "0x28:0x23          0x01 | rw | BMA400_INT12_MAP (pins INT1 INT2 interrupt map register).step_int1 (step detect interrupt mapped to INT1 pin bit): %x\n", $BMA400_INT12_MAP&0x1
	printf "0x28:0x23          0x04 | rw | BMA400_INT12_MAP (pins INT1 INT2 interrupt map register).tap_int1 (tap sensing interrupt mapped to INT1 pin bit): %x\n", $BMA400_INT12_MAP>>2&0x1
	printf "0x28:0x23          0x08 | rw | BMA400_INT12_MAP (pins INT1 INT2 interrupt map register).actch_int1 (activity changed interrupt mapped to INT1 pin bit): %x\n", $BMA400_INT12_MAP>>3&0x1
	printf "0x28:0x23          0x10 | rw | BMA400_INT12_MAP (pins INT1 INT2 interrupt map register).step_int2 (step detect interrupt mapped to INT2 pin bit): %x\n", $BMA400_INT12_MAP>>4&0x1
	printf "0x28:0x23          0x40 | rw | BMA400_INT12_MAP (pins INT1 INT2 interrupt map register).tap_int2 (tap sensing interrupt mapped to INT2 pin bit): %x\n", $BMA400_INT12_MAP>>6&0x1
	printf "0x28:0x23          0x80 | rw | BMA400_INT12_MAP (pins INT1 INT2 interrupt map register).actch_int2 (activity changed interrupt mapped to INT2 pin bit): %x\n", $BMA400_INT12_MAP>>7&0x1
	printf "0x28:0x23          0xdd | rw | BMA400_INT12_MAP (pins INT1 INT2 interrupt map register).value (r=0x00): 0x%02x\n", $BMA400_INT12_MAP
	printf "0x28:0x24          0x02 | rw | BMA400_INT12_IO_CTRL (pins INT1 INT2 control register).int1_lvl (0:low 1:high active output level on INT1 pin bit): %x\n", $BMA400_INT12_IO_CTRL>>1&0x1
	printf "0x28:0x24          0x04 | rw | BMA400_INT12_IO_CTRL (pins INT1 INT2 control register).int1_od (0:push-pull 1:open-drain output drive on INT1 pin bit): %x\n", $BMA400_INT12_IO_CTRL>>2&0x1
	printf "0x28:0x24          0x20 | rw | BMA400_INT12_IO_CTRL (pins INT1 INT2 control register).int2_lvl (0:low 1:high active output level on INT2 pin bit): %x\n", $BMA400_INT12_IO_CTRL>>5&0x1
	printf "0x28:0x24          0x40 | rw | BMA400_INT12_IO_CTRL (pins INT1 INT2 control register).int2_od (0:push-pull 1:open-drain output drive on INT2 pin bit): %x\n", $BMA400_INT12_IO_CTRL>>6&0x1
	printf "0x28:0x24          0x66 | rw | BMA400_INT12_IO_CTRL (pins INT1 INT2 control register).value (r=0x22): 0x%02x\n", $BMA400_INT12_IO_CTRL

	printf "0x28:0x26+3   0x00_0001 | rw | BMA400_FIFO_CONFIG (FIFO configure registers).auto_flush (clear FIFO on power mode change bit): %x\n", $BMA400_FIFO_CONFIG&0x1
	printf "0x28:0x26+3   0x00_0002 | rw | BMA400_FIFO_CONFIG (FIFO configure registers).fifo_stop_on_full (0:pop-oldest 1:stop when FIFO full bit): %x\n", $BMA400_FIFO_CONFIG>>1&0x1
	printf "0x28:0x26+3   0x00_0004 | rw | BMA400_FIFO_CONFIG (FIFO configure registers).fifo_time_en (append sensor time frame once FIFO runs empty bit): %x\n", $BMA400_FIFO_CONFIG>>2&0x1
	printf "0x28:0x26+3   0x00_0008 | rw | BMA400_FIFO_CONFIG (FIFO configure registers).fifo_data_src (store data to FIFO from 0:acc_filt1 1:acc_filt2 bit): %x\n", $BMA400_FIFO_CONFIG>>3&0x1
	printf "0x28:0x26+3   0x00_0010 | rw | BMA400_FIFO_CONFIG (FIFO configure registers).fifo_8bit_en (FIFO data is 0:'2 bytes, 12 bits' 1:'1 byte, 8-bits' bit): %x\n", $BMA400_FIFO_CONFIG>>4&0x1
	printf "0x28:0x26+3   0x00_0020 | rw | BMA400_FIFO_CONFIG (FIFO configure registers).fifo_x_en (store X-axis acceleration data to FIFO bit): %x\n", $BMA400_FIFO_CONFIG>>5&0x1
	printf "0x28:0x26+3   0x00_0040 | rw | BMA400_FIFO_CONFIG (FIFO configure registers).fifo_y_en (store Y-axis acceleration data to FIFO bit): %x\n", $BMA400_FIFO_CONFIG>>6&0x1
	printf "0x28:0x26+3   0x00_0080 | rw | BMA400_FIFO_CONFIG (FIFO configure registers).fifo_z_en (store Z-axis acceleration data to FIFO bit): %x\n", $BMA400_FIFO_CONFIG>>7&0x1
	printf "0x28:0x26+3   0x07_ff00 | rw | BMA400_FIFO_CONFIG (FIFO configure registers).fifo_watermark (FIFO watermark threshold value bits): 0x%03x\n", $BMA400_FIFO_CONFIG>>8&0x7ff
	printf "0x28:0x26+3   0x07_ffff | rw | BMA400_FIFO_CONFIG (FIFO configure registers).value (r=0x00_0000): 0x%02x_%04x\n", $BMA400_FIFO_CONFIG>>16, $BMA400_FIFO_CONFIG&0xffff
	printf "0x28:0x29          0x01 | rw | BMA400_FIFO_PWR_CONFIG (FIFO power configure register).fifo_read_disable (disable FIFO read circuit, saves 100nA power bit): %x\n", $BMA400_FIFO_CONFIG&0x1
	printf "0x28:0x29          0x01 | rw | BMA400_FIFO_PWR_CONFIG (FIFO power configure register).value (r=0x00): 0x%02x\n", $BMA400_FIFO_CONFIG
	printf "0x28:0x2a+2      0xf0ff |irw | BMA400_AUTOLOWPOW (auto-low-power registers).auto_lp_timeout_thres (timeout=.*2500us; low-power on timeout threshold): 0x%03x\n", $BMA400_AUTOLOWPOW<<4&0xff0 + $BMA400_AUTOLOWPOW>>12&0xf
	printf "0x28:0x2a+2      0x0100 | rw | BMA400_AUTOLOWPOW (auto-low-power registers).drdy_lowpow_trig (trigger low-power on accelerometer data refresh bit): %x\n", $BMA400_AUTOLOWPOW>>8&0x1
	printf "0x28:0x2a+2      0x0200 | rw | BMA400_AUTOLOWPOW (auto-low-power registers).gen1_int (trigger low-power on generic interrupt 1 bit): %x\n", $BMA400_AUTOLOWPOW>>9&0x1
	printf "0x28:0x2a+2      0x0c00 | rw | BMA400_AUTOLOWPOW (auto-low-power registers).auto_lp_timeout (0:no 1:yes 2:'yes, generic interrupt 2 resets timeout counter' ; trigger low-power on timeout bitfield): %x\n", $BMA400_AUTOLOWPOW>>10&0x3
	printf "0x28:0x2a+2      0xffff | rw | BMA400_AUTOLOWPOW (auto-low-power registers).value (r=0x0000): 0x%04x\n", $BMA400_AUTOLOWPOW
	printf "0x28:0x2c+2      0xf0ff |irw | BMA400_AUTOWAKEUP (auto-wake-up registers).wakeup_timeout_thres (timeout=.*2500us aka 2.5ms/lsb; wake-up on timeout threshold): 0x%03x\n", $BMA400_AUTOWAKEUP<<4&0xff0 + $BMA400_AUTOWAKEUP>>12&0xf
	printf "0x28:0x2c+2      0x0200 | rw | BMA400_AUTOWAKEUP (auto-wake-up registers).wkup_int (trigger wakeup on wakeup interrupt bit): %x\n", $BMA400_AUTOWAKEUP>>9&0x1
	printf "0x28:0x2c+2      0x0400 | rw | BMA400_AUTOWAKEUP (auto-wake-up registers).wkup_timeout (trigger wakeup on timeout threshold bit): %x\n", $BMA400_AUTOWAKEUP>>10&0x1
	printf "0x28:0x2c+2      0xf6ff | rw | BMA400_AUTOWAKEUP (auto-wake-up registers).value (r=0x0000): 0x%04x\n", $BMA400_AUTOWAKEUP

	printf "0x28:0x2f          0x03 | rw | BMA400_WKUP_INT_CONFIG0 (wake-up interrupt registers).wkup_refu (0:manual 1:on-low-power 2:on-acc-refresh update mode of xyz reference axes): %x\n", $BMA400_WKUP_INT_CONFIG0&0x3
	printf "0x28:0x2f          0x1c | rw | BMA400_WKUP_INT_CONFIG0 (wake-up interrupt registers).num_of_samples (NoS=.+1; trigger wakeup if threshold been crossed for N continuous samples): %x\n", $BMA400_WKUP_INT_CONFIG0>>2&0x7
	printf "0x28:0x2f          0x20 | rw | BMA400_WKUP_INT_CONFIG0 (wake-up interrupt registers).wkup_x_en (wakeup interrupt evaluate x-axis enable bit): %x\n", $BMA400_WKUP_INT_CONFIG0>>5&0x1
	printf "0x28:0x2f          0x40 | rw | BMA400_WKUP_INT_CONFIG0 (wake-up interrupt registers).wkup_y_en (wakeup interrupt evaluate y-axis enable bit): %x\n", $BMA400_WKUP_INT_CONFIG0>>6&0x1
	printf "0x28:0x2f          0x80 | rw | BMA400_WKUP_INT_CONFIG0 (wake-up interrupt registers).wkup_z_en (wakeup interrupt evaluate z-axis enable bit): %x\n", $BMA400_WKUP_INT_CONFIG0>>7&0x1
	printf "0x28:0x2f          0xff | rw | BMA400_WKUP_INT_CONFIG0 (wake-up interrupt registers).value (r=0x00): 0x%02x\n", $BMA400_WKUP_INT_CONFIG0
	printf "0x28:0x30          0xff | rw | BMA400_WKUP_INT_CONFIG1 (wake-up interrupt registers).int_wkup_thres (mg=.*2^(2+acc_range)/256 aka 15mg/lsb when 2g range; interrupt threshold): 0x%02x\n", $BMA400_WKUP_INT_CONFIG1
	printf "0x28:0x30          0xff | rw | BMA400_WKUP_INT_CONFIG1 (wake-up interrupt registers).value (r=0x00): 0x%02x\n", $BMA400_WKUP_INT_CONFIG1
	printf "0x28:0x31          0xff | rw | BMA400_WKUP_INT_CONFIG2 (wake-up interrupt registers).int_wkup_refx (signed x-axis reference acceleration): 0x%02x\n", $BMA400_WKUP_INT_CONFIG2
	printf "0x28:0x31          0xff | rw | BMA400_WKUP_INT_CONFIG2 (wake-up interrupt registers).value (r=0x00): 0x%02x\n", $BMA400_WKUP_INT_CONFIG2
	printf "0x28:0x32          0xff | rw | BMA400_WKUP_INT_CONFIG3 (wake-up interrupt registers).int_wkup_refy (signed y-axis reference acceleration): 0x%02x\n", $BMA400_WKUP_INT_CONFIG3
	printf "0x28:0x32          0xff | rw | BMA400_WKUP_INT_CONFIG3 (wake-up interrupt registers).value (r=0x00): 0x%02x\n", $BMA400_WKUP_INT_CONFIG3
	printf "0x28:0x33          0xff | rw | BMA400_WKUP_INT_CONFIG4 (wake-up interrupt registers).int_wkup_refz (signed z-axis reference acceleration): 0x%02x\n", $BMA400_WKUP_INT_CONFIG4
	printf "0x28:0x33          0xff | rw | BMA400_WKUP_INT_CONFIG4 (wake-up interrupt registers).value (r=0x00): 0x%02x\n", $BMA400_WKUP_INT_CONFIG4

	printf "0x28:0x35          0x0c | rw | BMA400_ORIENTCH_CONFIG0 (orientation changed interrupt registers).orient_refu (0:manual 1:'onetime acc_filt2' 2:'onetime acc_filt_lp' update mode of xyz reference axes): %x\n", $BMA400_ORIENTCH_CONFIG0>>2&0x3
	printf "0x28:0x35          0x10 | rw | BMA400_ORIENTCH_CONFIG0 (orientation changed interrupt registers).orient_data_src (interrupt evaluate data from 0:acc_filt2 1:acc_filt_lp mode bit): %x\n", $BMA400_ORIENTCH_CONFIG0>>4&0x1
	printf "0x28:0x35          0x20 | rw | BMA400_ORIENTCH_CONFIG0 (orientation changed interrupt registers).orient_x_en (orientation changed interrupt evaluate x-axis enable bit): %x\n", $BMA400_ORIENTCH_CONFIG0>>5&0x1
	printf "0x28:0x35          0x40 | rw | BMA400_ORIENTCH_CONFIG0 (orientation changed interrupt registers).orient_y_en (orientation changed interrupt evaluate y-axis enable bit): %x\n", $BMA400_ORIENTCH_CONFIG0>>6&0x1
	printf "0x28:0x35          0x80 | rw | BMA400_ORIENTCH_CONFIG0 (orientation changed interrupt registers).orient_z_en (orientation changed interrupt evaluate z-axis enable bit): %x\n", $BMA400_ORIENTCH_CONFIG0>>7&0x1
	printf "0x28:0x35          0xfc | rw | BMA400_ORIENTCH_CONFIG0 (orientation changed interrupt registers).value (r=0x00): 0x%02x\n", $BMA400_ORIENTCH_CONFIG0
	printf "0x28:0x36          0xff | rw | BMA400_ORIENTCH_CONFIG1 (orientation changed interrupt registers).orient_thres (mg=.*8 aka 8mg/lsb resolution; interrupt threshold): 0x%02x\n", $BMA400_ORIENTCH_CONFIG1
	printf "0x28:0x36          0xff | rw | BMA400_ORIENTCH_CONFIG1 (orientation changed interrupt registers).value (r=0x00): 0x%02x\n", $BMA400_ORIENTCH_CONFIG1
	printf "0x28:0x38          0xff | rw | BMA400_ORIENTCH_CONFIG3 (orientation changed interrupt registers).orient_dur (ms=.*10 aka 10ms/lsb; duration of new stable orientation before triggering interrupt XXX): 0x%02x\n", $BMA400_ORIENTCH_CONFIG3
	printf "0x28:0x38          0xff | rw | BMA400_ORIENTCH_CONFIG3 (orientation changed interrupt registers).value (r=0x00): 0x%02x\n", $BMA400_ORIENTCH_CONFIG3
	printf "0x28:0x39+2      0x0fff | rw | BMA400_ORIENTCH_CONFIG4_5 (orientation changed interrupt registers).int_orient_refx (x-axis reference orientation XXX): 0x%03x\n", $BMA400_ORIENTCH_CONFIG4_5&0xfff
	printf "0x28:0x39+2      0x0fff | rw | BMA400_ORIENTCH_CONFIG4_5 (orientation changed interrupt registers).value (r=0x000): 0x%04x\n", $BMA400_ORIENTCH_CONFIG4_5
	printf "0x28:0x3b+2      0x0fff | rw | BMA400_ORIENTCH_CONFIG6_7 (orientation changed interrupt registers).int_orient_refy (y-axis reference orientation XXX): 0x%03x\n", $BMA400_ORIENTCH_CONFIG6_7&0xfff
	printf "0x28:0x3b+2      0x0fff | rw | BMA400_ORIENTCH_CONFIG6_7 (orientation changed interrupt registers).value (r=0x000): 0x%04x\n", $BMA400_ORIENTCH_CONFIG6_7
	printf "0x28:0x3d+2      0x0fff | rw | BMA400_ORIENTCH_CONFIG8_9 (orientation changed interrupt registers).int_orient_refz (z-axis reference orientation XXX): 0x%03x\n", $BMA400_ORIENTCH_CONFIG8_9&0xfff
	printf "0x28:0x3d+2      0x0fff | rw | BMA400_ORIENTCH_CONFIG8_9 (orientation changed interrupt registers).value (r=0x000): 0x%04x\n", $BMA400_ORIENTCH_CONFIG8_9
	printf "0x28:0x3f          0x03 | rw | BMA400_GEN1INT_CONFIG0 (generic interrupt 1 registers).gen1_act_hyst (0:high noise vs 3:low noise; 0:no 1:24mg 2:48mg 3:96mg hysteresis on interrupt evaluation): %x\n", $BMA400_GEN1INT_CONFIG0&0x3
	printf "0x28:0x3f          0x0c | rw | BMA400_GEN1INT_CONFIG0 (generic interrupt 1 registers).gen1_act_refu (0:manual 1:onetime 2:everytime 3:'everytime acc_filt_lp' update mode of reference xyz axes): %x\n", $BMA400_GEN1INT_CONFIG0>>2&0x3
	printf "0x28:0x3f          0x10 | rw | BMA400_GEN1INT_CONFIG0 (generic interrupt 1 registers).gen1_data_src (interrupt evaluate data from 0:acc_filt1 1:acc_filt2 mode bit): %x\n", $BMA400_GEN1INT_CONFIG0>>4&0x1
	printf "0x28:0x3f          0x20 | rw | BMA400_GEN1INT_CONFIG0 (generic interrupt 1 registers).gen1_act_x_en (generic interrupt 1 evaluate x-axis enable bit): %x\n", $BMA400_GEN1INT_CONFIG0>>5&0x1
	printf "0x28:0x3f          0x40 | rw | BMA400_GEN1INT_CONFIG0 (generic interrupt 1 registers).gen1_act_y_en (generic interrupt 1 evaluate y-axis enable bit): %x\n", $BMA400_GEN1INT_CONFIG0>>6&0x1
	printf "0x28:0x3f          0x80 | rw | BMA400_GEN1INT_CONFIG0 (generic interrupt 1 registers).gen1_act_z_en (generic interrupt 1 evaluate z-axis enable bit): %x\n", $BMA400_GEN1INT_CONFIG0>>7&0x1
	printf "0x28:0x3f          0xff | rw | BMA400_GEN1INT_CONFIG0 (generic interrupt 1 registers).value (r=0x00): 0x%02x\n", $BMA400_GEN1INT_CONFIG0
	printf "0x28:0x40          0x01 | rw | BMA400_GEN1INT_CONFIG1 (generic interrupt 1 registers).gen1_comb_sel (trigger interrupt when 0:any 1:all xyz-axes threshold mode bit): %x\n", $BMA400_GEN1INT_CONFIG1&0x1
	printf "0x28:0x40          0x02 | rw | BMA400_GEN1INT_CONFIG1 (generic interrupt 1 registers).gen1_criterion_sel (trigger interrupt when 0:below 1:above threshold mode bit): %x\n", $BMA400_GEN1INT_CONFIG1>>1&0x1
	printf "0x28:0x40          0x03 | rw | BMA400_GEN1INT_CONFIG1 (generic interrupt 1 registers).value (r=0x00): 0x%02x\n", $BMA400_GEN1INT_CONFIG1
	printf "0x28:0x41          0xff | rw | BMA400_GEN1INT_CONFIG2 (generic interrupt 1 registers).gen1_int_thres (8mg/lsb; trigger interrupt on threshold value bits): 0x%02x\n", $BMA400_GEN1INT_CONFIG2
	printf "0x28:0x41          0xff | rw | BMA400_GEN1INT_CONFIG2 (generic interrupt 1 registers).value (r=0x00): 0x%02x\n", $BMA400_GEN1INT_CONFIG2
	printf "0x28:0x42+2      0xffff |irw | BMA400_GEN1INT_CONFIG3 (generic interrupt 1 registers).gen1_int_dur (duration, in data ready ticks, of new stable acceleration before triggering interrupt): 0x%04x\n", $BMA400_GEN1INT_CONFIG3<<8&0xff00 + $BMA400_GEN1INT_CONFIG3>>8&0xff
	printf "0x28:0x42+2      0xffff | rw | BMA400_GEN1INT_CONFIG3 (generic interrupt 1 registers).value (r=0x0000): 0x%04x\n", $BMA400_GEN1INT_CONFIG3
	printf "0x28:0x44+2      0x0fff | rw | BMA400_GEN1INT_CONFIG4_5 (generic interrupt 1 registers).gen1_int_th_refx (x-axis reference XXX): 0x%03x\n", $BMA400_GEN1INT_CONFIG4_5&0xfff
	printf "0x28:0x44+2      0x0fff | rw | BMA400_GEN1INT_CONFIG4_5 (generic interrupt 1 registers).value (r=0x0000): 0x%04x\n", $BMA400_GEN1INT_CONFIG4_5
	printf "0x28:0x46+2      0x0fff | rw | BMA400_GEN1INT_CONFIG6_7 (generic interrupt 1 registers).gen1_int_th_refy (y-axis reference XXX): 0x%03x\n", $BMA400_GEN1INT_CONFIG6_7&0xfff
	printf "0x28:0x46+2      0x0fff | rw | BMA400_GEN1INT_CONFIG6_7 (generic interrupt 1 registers).value (r=0x0000): 0x%04x\n", $BMA400_GEN1INT_CONFIG6_7
	printf "0x28:0x48+2      0x0fff | rw | BMA400_GEN1INT_CONFIG8_9 (generic interrupt 1 registers).gen1_int_th_refz (z-axis reference XXX): 0x%03x\n", $BMA400_GEN1INT_CONFIG8_9&0xfff
	printf "0x28:0x48+2      0x0fff | rw | BMA400_GEN1INT_CONFIG8_9 (generic interrupt 1 registers).value (r=0x0000): 0x%04x\n", $BMA400_GEN1INT_CONFIG8_9

	printf "0x28:0x4a          0x03 | rw | BMA400_GEN2INT_CONFIG0 (generic interrupt 2 registers).gen2_act_hyst (0:high noise vs 3:low noise; 0:no 1:24mg 2:48mg 3:96mg hysteresis on interrupt evaluation): %x\n", $BMA400_GEN2INT_CONFIG0&0x3
	printf "0x28:0x4a          0x0c | rw | BMA400_GEN2INT_CONFIG0 (generic interrupt 2 registers).gen2_act_refu (0:manual 1:onetime 2:everytime 3:'everytime acc_filt_lp' update mode of reference xyz axes): %x\n", $BMA400_GEN2INT_CONFIG0>>2&0x3
	printf "0x28:0x4a          0x10 | rw | BMA400_GEN2INT_CONFIG0 (generic interrupt 2 registers).gen2_data_src (interrupt evaluate data from 0:acc_filt1 1:acc_filt2 mode bit): %x\n", $BMA400_GEN2INT_CONFIG0>>4&0x1
	printf "0x28:0x4a          0x20 | rw | BMA400_GEN2INT_CONFIG0 (generic interrupt 2 registers).gen2_act_x_en (generic interrupt 1 evaluate x-axis enable bit): %x\n", $BMA400_GEN2INT_CONFIG0>>5&0x1
	printf "0x28:0x4a          0x40 | rw | BMA400_GEN2INT_CONFIG0 (generic interrupt 2 registers).gen2_act_y_en (generic interrupt 1 evaluate y-axis enable bit): %x\n", $BMA400_GEN2INT_CONFIG0>>6&0x1
	printf "0x28:0x4a          0x80 | rw | BMA400_GEN2INT_CONFIG0 (generic interrupt 2 registers).gen2_act_z_en (generic interrupt 1 evaluate z-axis enable bit): %x\n", $BMA400_GEN2INT_CONFIG0>>7&0x1
	printf "0x28:0x4a          0xff | rw | BMA400_GEN2INT_CONFIG0 (generic interrupt 2 registers).value (r=0x00): 0x%02x\n", $BMA400_GEN2INT_CONFIG0
	printf "0x28:0x4b          0x01 | rw | BMA400_GEN2INT_CONFIG1 (generic interrupt 2 registers).gen2_comb_sel (trigger interrupt when 0:any 1:all xyz-axes threshold mode bit): %x\n", $BMA400_GEN2INT_CONFIG1&0x1
	printf "0x28:0x4b          0x02 | rw | BMA400_GEN2INT_CONFIG1 (generic interrupt 2 registers).gen2_criterion_sel (trigger interrupt when 0:below 1:above threshold mode bit): %x\n", $BMA400_GEN2INT_CONFIG1>>1&0x1
	printf "0x28:0x4b          0x03 | rw | BMA400_GEN2INT_CONFIG1 (generic interrupt 2 registers).value (r=0x00): 0x%02x\n", $BMA400_GEN2INT_CONFIG1
	printf "0x28:0x4c          0xff | rw | BMA400_GEN2INT_CONFIG2 (generic interrupt 2 registers).gen2_int_thres (8mg/lsb; trigger interrupt on threshold value bits): 0x%02x\n", $BMA400_GEN2INT_CONFIG2
	printf "0x28:0x4c          0xff | rw | BMA400_GEN2INT_CONFIG2 (generic interrupt 2 registers).value (r=0x00): 0x%02x\n", $BMA400_GEN2INT_CONFIG2
	printf "0x28:0x4d+2      0xffff |irw | BMA400_GEN2INT_CONFIG3 (generic interrupt 2 registers).gen2_int_dur (duration, in data ready ticks, of new stable acceleration before triggering interrupt): 0x%04x\n", $BMA400_GEN2INT_CONFIG3<<8&0xff00 + $BMA400_GEN2INT_CONFIG3>>8&0xff
	printf "0x28:0x4d+2      0xffff | rw | BMA400_GEN2INT_CONFIG3 (generic interrupt 2 registers).value (r=0x0000): 0x%04x\n", $BMA400_GEN2INT_CONFIG3
	printf "0x28:0x4f+2      0x0fff | rw | BMA400_GEN2INT_CONFIG4_5 (generic interrupt 2 registers).gen2_int_th_refx (x-axis reference XXX): 0x%03x\n", $BMA400_GEN2INT_CONFIG4_5&0xfff
	printf "0x28:0x4f+2      0x0fff | rw | BMA400_GEN2INT_CONFIG4_5 (generic interrupt 2 registers).value (r=0x0000): 0x%04x\n", $BMA400_GEN2INT_CONFIG4_5
	printf "0x28:0x51+2      0x0fff | rw | BMA400_GEN2INT_CONFIG6_7 (generic interrupt 2 registers).gen2_int_th_refy (y-axis reference XXX): 0x%03x\n", $BMA400_GEN2INT_CONFIG6_7&0xfff
	printf "0x28:0x51+2      0x0fff | rw | BMA400_GEN2INT_CONFIG6_7 (generic interrupt 2 registers).value (r=0x0000): 0x%04x\n", $BMA400_GEN2INT_CONFIG6_7
	printf "0x28:0x53+2      0x0fff | rw | BMA400_GEN2INT_CONFIG8_9 (generic interrupt 2 registers).gen2_int_th_refz (z-axis reference XXX): 0x%03x\n", $BMA400_GEN2INT_CONFIG8_9&0xfff
	printf "0x28:0x53+2      0x0fff | rw | BMA400_GEN2INT_CONFIG8_9 (generic interrupt 2 registers).value (r=0x0000): 0x%04x\n", $BMA400_GEN2INT_CONFIG8_9

	printf "0x28:0x55+2      0x00ff | rw | BMA400_ACTCH_CONFIG (activity changed interrupt registers).actch_thres (8mg/g resoluion; trigger interrupt on threshold value bits): 0x%02x\n", $BMA400_ACTCH_CONFIG&0xff
	printf "0x28:0x55+2      0x0f00 | rw | BMA400_ACTCH_CONFIG (activity changed interrupt registers).actch_npts (0:32 1:64 2:128 3:256 4:512 number of points for evaluation of activity bits): 0x%02x\n", $BMA400_ACTCH_CONFIG>>8&0xf
	printf "0x28:0x55+2      0x1000 | rw | BMA400_ACTCH_CONFIG (activity changed interrupt registers).actch_data_src (interrupt evaluate data from 0:acc_filt1 1:acc_filt2 mode bit): %x\n", $BMA400_ACTCH_CONFIG>>12&0x1
	printf "0x28:0x55+2      0x2000 | rw | BMA400_ACTCH_CONFIG (activity changed interrupt registers).actch_x_en (activity changed interrupt evaluate x-axis enable bit): %x\n", $BMA400_ACTCH_CONFIG>13&0x1
	printf "0x28:0x55+2      0x4000 | rw | BMA400_ACTCH_CONFIG (activity changed interrupt registers).actch_y_en (activity changed interrupt evaluate y-axis enable bit): %x\n", $BMA400_ACTCH_CONFIG>14&0x1
	printf "0x28:0x55+2      0x8000 | rw | BMA400_ACTCH_CONFIG (activity changed interrupt registers).actch_z_en (activity changed interrupt evaluate z-axis enable bit): %x\n", $BMA400_ACTCH_CONFIG>15&0x1
	printf "0x28:0x55+2      0xffff | rw | BMA400_ACTCH_CONFIG (activity changed interrupt registers).value (r=0x0000): 0x%04x\n", $BMA400_ACTCH_CONFIG
	printf "0x28:0x57          0x07 | rw | BMA400_TAP_CONFIG (tap interrupt registers).tap_sensitivity (0:highest .. 7:lowest sensitivity bitfield): %x\n", $BMA400_TAP_CONFIG&0x7
	printf "0x28:0x57          0x18 | rw | BMA400_TAP_CONFIG (tap interrupt registers).sel_axis (use data from 0:Z 1:Y 2:X axis bitfield): %x\n", $BMA400_TAP_CONFIG>>3&0x3
	printf "0x28:0x57          0x1f | rw | BMA400_TAP_CONFIG (tap interrupt registers).value (r=0x00): 0x%02x\n", $BMA400_TAP_CONFIG
	printf "0x28:0x58          0x03 | rw | BMA400_TAP_CONFIG1 (tap interrupt registers).tics_th (0..3:'6 9 12 18' data samples between upper and lower peak of a tap bitfield): %x\n", $BMA400_TAP_CONFIG1&0x3
	printf "0x28:0x58          0x0c | rw | BMA400_TAP_CONFIG1 (tap interrupt registers).quiet (0..3:'60 80 100 120' data samples between single or double taps bitfield): %x\n", $BMA400_TAP_CONFIG1>>2&0x3
	printf "0x28:0x58          0x30 | rw | BMA400_TAP_CONFIG1 (tap interrupt registers).quiet_dt (0..3:'4 8 12 16' data samples between two taps of double taps bitfield): %x\n", $BMA400_TAP_CONFIG1>>4&0x3
	printf "0x28:0x58          0x3f | rw | BMA400_TAP_CONFIG1 (tap interrupt registers).value (r=0x06): 0x%02x\n", $BMA400_TAP_CONFIG1

	printf "0x28:0x7c          0x01 | rw | BMA400_IF_CONF (serial interface configure registers).spi3 (0:spi-4-wire 1:spi-3-wire interface mode bit): 0x%02x\n", $BMA400_IF_CONF&0x1
	printf "0x28:0x7c          0x01 | rw | BMA400_IF_CONF (serial interface configure registers).value (r=0x00): 0x%02x\n", $BMA400_IF_CONF
	printf "0x28:0x7d          0x01 | rw | BMA400_SELF_TEST (sensor self-test register).acc_self_test_en_x (trigger self-test for X-axis bit): %x\n", $BMA400_SELF_TEST&0x1
	printf "0x28:0x7d          0x02 | rw | BMA400_SELF_TEST (sensor self-test register).acc_self_test_en_y (trigger self-test for Y-axis bit): %x\n", $BMA400_SELF_TEST>>1&0x1
	printf "0x28:0x7d          0x04 | rw | BMA400_SELF_TEST (sensor self-test register).acc_self_test_en_z (trigger self-test for Z-axis bit): %x\n", $BMA400_SELF_TEST>>2&0x1
	printf "0x28:0x7d          0x08 | rw | BMA400_SELF_TEST (sensor self-test register).acc_self_test_sign (self test in 0:positive 1:negative range bit): %x\n", $BMA400_SELF_TEST>>3&0x1
	printf "0x28:0x7d          0x0f | rw | BMA400_SELF_TEST (sensor self-test register).value (r=0x00): 0x%02x\n", $BMA400_SELF_TEST
	printf "0x28:0x7e          0xff |  w | BMA400_CMD (command register).cmd (w!cmd_rdy==1; 0xb0:'clear fifo' 0xb1:'clear step counter' 0xb6:'reset' opcode bits): N/A\n"
	printf "0x28:0x7e          0xff |  w | BMA400_CMD (command register).value (r=0x00): N/A\n"


	printf "** DeviceAddr:TargetAddr * I2C BME680 temperature, humidity, pressure and air quality index sensor **\n"
	printf "0xec:0xe0          0xff | rw | BME680_SOFT_RESET (soft reset register).cmd (0xb6:'reset' opcode bits): N/A\n"
	printf "0xec:0xe0          0xff | rw | BME680_SOFT_RESET (soft reset register).value (r=0x00): N/A\n"
	printf "0xec:0xd0          0xff | r  | BME680_CHIPID (chip identification register).value (r=0x61): 0x%02x\n", $BMA400_CHIPID

	printf "0xec:0x89+25            | r  | BME680_COEFF1 (coefficient)\n"
	printf "0xec:0xe1+16            | r  | BME680_COEFF2 (coefficient)\n"
	printf "0xec:0x00               | r  | BME680_ADDR_RES_HEAT_VAL (coefficient)\n"
	printf "0xec:0x02               | r  | BME680_ADDR_RES_HEAT_RANGE (coefficient)\n"
	printf "0xec:0x04               | r  | BME680_ADDR_RANGE_SW_ERR (coefficient)\n"

	printf "0xec:0x5a          0xff | rw | >6d BME680_RES_HEAT0 (heater settings)\n"
	printf "0xec:0x5b          0xff | rw | >64 BME680_RES_HEAT1 (heater settings)\n"
	printf "0xec:0x5c          0xff | rw | >71 BME680_RES_HEAT2 (heater settings)\n"
	printf "0xec:0x5d          0xff | rw |     BME680_RES_HEAT3 (heater settings)\n"
	printf "0xec:0x5e          0xff | rw |     BME680_RES_HEAT4 (heater settings)\n"
	printf "0xec:0x5f          0xff | rw |     BME680_RES_HEAT5 (heater settings)\n"
	printf "0xec:0x60          0xff | rw |     BME680_RES_HEAT6 (heater settings)\n"
	printf "0xec:0x61          0xff | rw |     BME680_RES_HEAT7 (heater settings)\n"
	printf "0xec:0x62          0xff | rw |     BME680_RES_HEAT8 (heater settings)\n"
	printf "0xec:0x63          0xff | rw |     BME680_RES_HEAT9 (heater settings)\n"

	printf "0xec:0x72          0x07 | rw | BME680_CTRL_HUM (humidity control register).osrs_h (0:skip 1:1x 2:2x 3:4x 4:8x 5,6,7:16x oversampling humidity bits): %x\n", $BME680_CTRL_HUM & 0x07
	printf "0xec:0x72          0x40 | rw | BME680_CTRL_HUM (humidity control register).spi_3w_int_en (enable SPI 3 wire mode): %x\n" $BME680_CTRL_HUM >> 6 & 0x1
	printf "0xec:0x72          0x47 | rw | BME680_CTRL_HUM (humidity control register).value: 0x%02x\n", $BME680_CTRL_HUM

	printf "0xec:0x74          0x03 | rw | BME680_CTRL_MEAS (tempe).mode (0:sleep 1:forced; power mode bit)\n", $BME680_CTRL_MEAS & 0x03
	printf "0xec:0x74          0x1c | rw | BME680_CTRL_MEAS (tempe).osrs_p\n"
	printf "0xec:0x74          0xe0 | rw | BME680_CTRL_MEAS (tempe).osrs_t\n"
	printf "0xec:0x74          0xff | rw | BME680_CTRL_MEAS (tempe).value: 0x%02x\n"
	printf "0xec:0x75          0x01 | rw | BME680_CONFIG.spi_3w_en\n"
	printf "0xec:0x75          0x1c | rw | BME680_CONFIG.filter\n"
	printf "0xec:0x75          0x1d | rw | BME680_CONFIG.value\n"

	printf "0xEC:0x1D          0xff | r  | BME680 (command register).value (r=0x00): N/A\n"
	printf "0xEC:0x1F+3        0xff | r  | BME680_PRES (pressure).value (r=0x00): N/A\n"
	printf "0xEC:0x22+3        0xff | r  | BME680_TEMP (temperature)\n"
	printf "0xEC:0x25+2        0xff | r  | BME680_HUMID (humidity)\n"
	printf "0xEC:0x2A+2        0xff | r  | BME680_GAS_RES (gas resistance)\n"

	printf "0xEC:0xB6               |    | BME680_SOFT_RESET"

end
document reglist
Ignored registers:
- Write-only registers like GPIOA_BSRR at 0x5000_0018, are not listed. As nothing can be read.
end
reglist

# What are these?
# ---------------
# CP15
#
# Helpers
# -------
# - desc: Generate GDB memory read commands from GDB printf commands
#   cmd: |
#     mawk '/^[\t ]*$/{print; next} {gsub(/[|]/, ""); r=$5; gsub(/["_]/, ""); a=$2} !A[r a]++{printf("\tset $%s = (unsigned int) *%s\n", r, a)}' | uniq
#   stdin: |
#     printf "0x4000_5400 0x00ff_dfff | rw | I2C_CR1 (control register 1).value (r=0x0000_0000): 0x%04x_%04x\n", $I2C_CR1>>16&0xFFFF, $I2C_CR1&0xFFFF
#   stdout: |
#     set $I2C_CR1 = (unsigned int) *0x40005400
