PROJECT = base64-cdc

# Directory containing our Rust library
RUST_BASE_PATH = ./base64-rs-ffi

OBJECTS = \
		./main.o \
		./lib/USBDevice/USBDevice/USBHAL_LPC17.o \
		./lib/USBDevice/USBDevice/USBDevice.o \
		./lib/USBDevice/USBSerial/USBSerial.o \
		./lib/USBDevice/USBSerial/USBCDC.o
SYS_OBJECTS = \
		./lib/mbed/TARGET_LPC1768/TOOLCHAIN_GCC_ARM/board.o \
		./lib/mbed/TARGET_LPC1768/TOOLCHAIN_GCC_ARM/startup_LPC17xx.o \
		./lib/mbed/TARGET_LPC1768/TOOLCHAIN_GCC_ARM/cmsis_nvic.o \
		./lib/mbed/TARGET_LPC1768/TOOLCHAIN_GCC_ARM/retarget.o \
		./lib/mbed/TARGET_LPC1768/TOOLCHAIN_GCC_ARM/system_LPC17xx.o
INCLUDE_PATHS = \
		-I. \
		-I./lib/USBDevice \
		-I./lib/USBDevice/USBDevice \
		-I./lib/USBDevice/USBSerial \
		-I./lib/mbed \
		-I./lib/mbed/TARGET_LPC1768 \
		-I./lib/mbed/TARGET_LPC1768/TOOLCHAIN_GCC_ARM \
		-I./lib/mbed/TARGET_LPC1768/TARGET_NXP \
		-I./lib/mbed/TARGET_LPC1768/TARGET_NXP/TARGET_LPC176X \
		-I./lib/mbed/TARGET_LPC1768/TARGET_NXP/TARGET_LPC176X/TARGET_MBED_LPC1768 \
		-I./$(RUST_BASE_PATH)/include
LIBRARY_PATHS = \
		-L./lib/mbed/TARGET_LPC1768/TOOLCHAIN_GCC_ARM
LIBRARIES = -lmbed -lbase64_cfl_wrapper
LINKER_SCRIPT = ./lib/mbed/TARGET_LPC1768/TOOLCHAIN_GCC_ARM/LPC1768.ld

###############################################################################
AS      = arm-none-eabi-as
CC      = arm-none-eabi-gcc
CPP     = arm-none-eabi-g++
LD      = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
SIZE    = arm-none-eabi-size


CPU = -mcpu=cortex-m3 -mthumb
TARGET = thumbv7m-none-eabi
CC_FLAGS = \
		$(CPU) \
		-c \
		-g \
		-fno-common \
		-fmessage-length=0 \
		-Wall \
		-Wextra \
		-Wno-unused-parameter \
		-fno-exceptions \
		-ffunction-sections \
		-fdata-sections \
		-fomit-frame-pointer \
		-MMD \
		-MP
CC_SYMBOLS = \
		-DTOOLCHAIN_GCC_ARM \
		-DTOOLCHAIN_GCC \
		-DARM_MATH_CM3 \
		-DTARGET_CORTEX_M \
		-DTARGET_LPC176X \
		-DTARGET_NXP \
		-DTARGET_MBED_LPC1768 \
		-D__MBED__=1 \
		-DTARGET_LPC1768 \
		-D__CORTEX_M3 \
		-DTARGET_M3
LD_FLAGS = \
		$(CPU) \
		-Wl,--gc-sections \
		--specs=nano.specs \
		-u _printf_float \
		-u _scanf_float \
		-Wl,--wrap,main \
		-Wl,-Map=$(PROJECT).map,--cref
LD_SYS_LIBS = \
		-lstdc++ \
		-lsupc++ \
		-lm \
		-lc \
		-lgcc \
		-lnosys

export CARGO_FLAGS = --target=$(TARGET)

ifeq ($(DEBUG), 1)
  CC_FLAGS += -DDEBUG -O0
  LIBRARY_PATHS += -L$(RUST_BASE_PATH)/target/$(TARGET)/debug
else
  CC_FLAGS += -DNDEBUG -Os
  CARGO_FLAGS += --release
  LIBRARY_PATHS += -L$(RUST_BASE_PATH)/target/$(TARGET)/release
endif

.PHONY: all clean lst size cargo

all: $(PROJECT).bin $(PROJECT).hex size

clean:
	@echo Cleaning up...
	@rm -f $(PROJECT).bin $(PROJECT).elf $(PROJECT).hex $(PROJECT).map $(PROJECT).lst $(OBJECTS) $(DEPS)
	@$(MAKE) -C $(RUST_BASE_PATH) clean

.asm.o:
	@echo "Assembling $<"
	@$(CC) $(CPU) -c -x assembler-with-cpp -o $@ $<
.s.o:
	@echo "Assembling $<"
	@$(CC) $(CPU) -c -x assembler-with-cpp -o $@ $<
.S.o:
	@echo "Assembling $<"
	@$(CC) $(CPU) -c -x assembler-with-cpp -o $@ $<

.c.o:
	@echo "Building $<"
	@$(CC) $(CC_FLAGS) $(CC_SYMBOLS) -std=gnu99 $(INCLUDE_PATHS) -o $@ $<

.cpp.o:
	@echo "Building $<"
	@$(CPP) $(CC_FLAGS) $(CC_SYMBOLS) -std=gnu++98 -fno-rtti $(INCLUDE_PATHS) -o $@ $<

$(PROJECT).elf: $(OBJECTS) $(SYS_OBJECTS) | cargo
	@echo "Linking $@"
	@$(LD) $(LD_FLAGS) -T$(LINKER_SCRIPT) $(LIBRARY_PATHS) -o $@ $^ $(LIBRARIES) $(LD_SYS_LIBS) $(LIBRARIES) $(LD_SYS_LIBS)

$(PROJECT).bin: $(PROJECT).elf
	$(OBJCOPY) -O binary $< $@

$(PROJECT).hex: $(PROJECT).elf
	@$(OBJCOPY) -O ihex $< $@

$(PROJECT).lst: $(PROJECT).elf
	@$(OBJDUMP) -Sdh $< > $@

lst: $(PROJECT).lst

size: $(PROJECT).elf
	$(SIZE) $(PROJECT).elf

cargo:
	$(MAKE) -C $(RUST_BASE_PATH) all

DEPS = $(OBJECTS:.o=.d) $(SYS_OBJECTS:.o=.d)
-include $(DEPS)
