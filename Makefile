AR  ?= ar
AS  ?= as
CC  ?= gcc
CXX ?= g++
LD  ?= $(CXX)

O ?= build

ifdef VERBOSE
  Q :=
else
  Q := @
endif

INCDIR += $O
LIBDIR += $O

INCPATHS += $(addprefix -I,$(INCDIR))
LIBPATHS += $(addprefix -L,$(LIBDIR))

# ifdef DEBUG
#   CDEFINES += DEBUG
# endif

# CWARNFLAGS += all extra no-unused-parameter

#ifdef DEBUG
#  COPTFLAGS := -O0
#else
#  COPTFLAGS := -O2
#endif

# CFLAGS += -pipe $(COPTFLAGS) -pedantic

ifdef DEBUG
  CFLAGS += -g
  ASFLAGS += -g
endif

CFLAGS += $(addprefix -W,$(CWARNFLAGS))
CFLAGS += $(addprefix -D,$(CDEFINES))
CFLAGS += $(INCPATHS)

CXXFLAGS += $(filter-out -pedantic,$(CFLAGS)) -fno-exceptions -fno-rtti
LDFLAGS += $(LIBPATHS)

all: usage

usage:
	@echo "USAGE: ./build-project.sh project_directory [clean] firmware|qemu|qemu-gdb|qemu-gdbserver|qemu-valgrind"
	@echo "Example:"
	@echo " ./build-project.sh Projects/STM32746G-Discovery/Examples/LTDC/LTDC_Display_1Layer/SW4STM32/STM32746G_DISCOVERY qemu"

firmware: $O/firmware.elf

generate-project: $O/.
	$Q python3 convert.py $(PROJECT) > $O/Makefile.gen

SRCS :=
-include $O/Makefile.gen

## Manual fixes
# SRCS += Drivers/STM32F7xx_HAL_Driver/Src/stm32f7xx_hal_adc_ex.c

OBJS :=	$(addprefix $O/,$(patsubst %.s,%.o,$(patsubst %.cpp,%.o,$(patsubst %.c,%.o,$(SRCS)))))

$O/firmware.elf: $(OBJS) $O/Makefile.gen
	$Q echo "LD  $(@:$O/%=%)"
	$(LD) $(LDFLAGS) -o $@ -Wl,--start-group $(OBJS) -Wl,--end-group $(LIBS)

$O/firmware.elf: $(LDSCRIPT)
$O/firmware.elf: private LD := $(CC)
$O/firmware.elf: private LDFLAGS += -specs=nosys.specs -T$(LDSCRIPT)

qemu: $O/firmware.elf
	$(WRAP) ~/src/.build/qemu/qemu-system-arm \
		-M stm32746g-discovery -d guest_errors,unimp \
		-monitor stdio -kernel $< -s $(APPEND)

qemu-gdb: qemu
qemu-gdb: APPEND := -S

qemu-gdbserver: qemu
qemu-gdbserver: WRAP := gdbserver localhost:1235

qemu-valgrind: qemu
qemu-valgrind: WRAP := valgrind --leak-check=full --track-origins=yes --max-stackframe=137304372264
qemu-valgrind: APPEND := -S

# clean

.PHONY: clean
clean:
	rm -rf $O

# Object directories

.PRECIOUS: $O/. $O%/.

$O/.:
	$Q mkdir -p $@

$O%/.:
	$Q mkdir -p $@

# Implicit targets

.SUFFIXES:
.PRECIOUS: $O/%.o $O/%.gen.o
.SECONDEXPANSION:

$O/%.txt:
	touch $@

$O/%.o: %.c | $$(@D)/.
	$Q echo "CC  $<"
	$Q $(CC) $(CFLAGS) -c -MMD -MT $@ -MF $@.d -o $@ $<

$O/%.o: %.cpp | $$(@D)/.
	$Q echo "CXX $<"
	$Q $(CXX) $(CXXFLAGS) -c -MMD -MT $@ -MF $@.d -o $@ $<

$O/%.o: %.s | $$(@D)/.
	$Q echo "AS  $<"
	$Q $(AS) $(ASFLAGS) -c -o $@ $<

$O/%.a: | $$(@D)/.
	$Q echo "AR  $(@:$O/%=%)"
	$Q $(AR) rcs $@ $?

# Dependencies

-include $(addsuffix /*.d,$(shell find $O -type d 2> /dev/null))
