#
# Copyright (c) 2017 - InvnSense Inc
#

SDK_VERSION := 1.0.0

# Windows
ifeq ($(OS),Windows_NT)
	RM = del /Q
	MKDIR = mkdir
	FixPath = $(subst /,\,$1)
endif

# 
# Basic configuration
#
INVN_TOOLCHAIN_PATH ?= %ProgramFiles(x86)%\Atmel\Studio\7.0\toolchain\arm\arm-gnu-toolchain\bin
$(info INVN_TOOLCHAIN_PATH is $(INVN_TOOLCHAIN_PATH))

PREFIX  ?= $(INVN_TOOLCHAIN_PATH)\arm-none-eabi-
GCC     := "$(PREFIX)gcc"
OBJCOPY := "$(PREFIX)objcopy"
SIZE    := "$(PREFIX)size"
AR      := "$(PREFIX)ar"

OUTPUT_DIR  ?= output
OUTPUT      ?= libEMDCore.a
EXTRA_FLAGS ?=
FLAGS   ?= -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16 $(EXTRA_FLAGS)
CFLAGS  ?= $(FLAGS) -pipe -std=c99 -fdata-sections -ffunction-sections -Wall -Wextra -Wno-unused-parameter -fsigned-char \
	-mlong-calls -fno-strict-aliasing -Wmissing-prototypes -Werror-implicit-function-declaration -Wpointer-arith -Wchar-subscripts \
	-Wcomment -Wformat=2 -Wimplicit-int -Wmain -Wparentheses -Wsequence-point -Wreturn-type -Wswitch -Wtrigraphs -Wunused -Wuninitialized -Wunknown-pragmas \
	-Wundef -Wbad-function-cast -Wwrite-strings -Wsign-compare -Waggregate-return -Wmissing-declarations -Wformat -Wmissing-format-attribute \
	-Wno-deprecated-declarations -Wpacked -Wunreachable-code --param max-inline-insns-single=500	
VERSION ?= $(SDK_VERSION)

ifeq ($(DEBUG),yes)
	CFLAGS += -O0 -g3
else
	CFLAGS += -O0
endif

EXTRA_IDIRS ?=
EXTRA_DEPS  ?=
EXTRA_CSRCS ?=
EXTRA_DEFS  ?=
EXTRA_LIBS  ?=
EXTRA_LDIRS ?=

# List of files and dependencies (automatically-generated)
IDIRS   +=  \
	sources/board-hal \
	sources/Invn/Devices/Drivers/Iam20680 \
	sources/Invn/EmbUtils
LDIRS   +=

DEPS    +=  \
	sources/Invn/Devices/Drivers/Iam20680/Iam20680Transport.h \
	sources/Invn/Devices/Drivers/Iam20680/Iam20680SelfTest.h \
	sources/Invn/Devices/Drivers/Iam20680/Iam20680ExtFunc.h \
	sources/Invn/Devices/Drivers/Iam20680/Iam20680Driver_HL.h \
	sources/Invn/Devices/Drivers/Iam20680/Iam20680Defs.h \
	sources/Invn/EmbUtils/RingByteBuffer.h \
	sources/Invn/EmbUtils/RingBuffer.h \
	sources/Invn/EmbUtils/Message.h \
	sources/Invn/EmbUtils/InvError.h \
	sources/Invn/EmbUtils/InvBool.h \
	sources/Invn/EmbUtils/InvAssert.h \
	sources/Invn/EmbUtils/ErrorHelper.h \
	sources/Invn/EmbUtils/InvScheduler.h \
	sources/Invn/EmbUtils/Message.h \
	sources/Invn/EmbUtils/RingBuffer.h
CSRCS   +=  \
	sources/Invn/Devices/Drivers/Iam20680/Iam20680Transport.c \
	sources/Invn/Devices/Drivers/Iam20680/Iam20680SelfTest.c \
	sources/Invn/Devices/Drivers/Iam20680/Iam20680Driver_HL.c \
	sources/Invn/Devices/Drivers/Iam20680/Iam20680Driver.c \
	sources/Invn/EmbUtils/RingByteBuffer.c \
	sources/Invn/EmbUtils/Message.c \
	sources/Invn/EmbUtils/ErrorHelper.c \
	sources/Invn/EmbUtils/InvScheduler.c
DEFS    +=  \
	-DINV_MSG_ENABLE=INV_MSG_LEVEL_VERBOSE \
	-DASSERT \
	-DNDEBUG \
	-DARM_MATH_CM4
LIBS    +=
LDSCRIPT ?= 

ifdef INVN_EMD_SDK_PATH
# fixup path according to SDK root
	CSRCS := $(addprefix $(INVN_EMD_SDK_PATH)/,$(CSRCS))
	DEPS := $(addprefix $(INVN_EMD_SDK_PATH)/,$(DEPS))
	IDIRS := $(addprefix $(INVN_EMD_SDK_PATH)/,$(IDIRS))
	LDIRS := $(addprefix $(INVN_EMD_SDK_PATH)/,$(LDIRS))
ifneq ($(LDSCRIPT),)
	LDSCRIPT := $(addprefix $(INVN_EMD_SDK_PATH)/,$(LDSCRIPT))
endif
endif

ifneq ($(LDSCRIPT),)
	LDSCRIPT := -T $(LDSCRIPT)
endif
DEFS += -DVERSION=$(VERSION)
IDIRS := $(addprefix -I,$(IDIRS))
LDIRS := $(addprefix -L,$(LDIRS))
CSRCS += $(EXTRA_CSRCS)
DEPS  += $(EXTRA_DEPS)
DEFS  += $(EXTRA_DEFS)
IDIRS += $(EXTRA_IDIRS)
LDIRS += $(EXTRA_LDIRS)
LIBS  += $(EXTRA_LIBS)

# Get objects lists according to sources list
OBJS := $(notdir $(CSRCS))
OBJS := $(addsuffix .o,$(OBJS))
OBJS := $(addprefix $(OUTPUT_DIR)/objs/,$(OBJS))

#
# Rules
#
all: $(OUTPUT)
	@echo "SUCCESS: output available under '$(OUTPUT_DIR)/$(OUTPUT)'"

# Generic rule for compiling 
define CRule
$(OUTPUT_DIR)/objs/$(notdir $(1).o): $(1) $(DEPS)
	$(GCC) -c $(CFLAGS) $(IDIRS) $(DEFS) $(1) -o $(OUTPUT_DIR)/objs/$(notdir $(1)).o
endef
$(foreach _,$(CSRCS), $(eval $(call CRule,$_)))

$(OUTPUT): $(OUTPUT_DIR)/$(OUTPUT)

$(OUTPUT_DIR)/objs:
	@$(MKDIR) $(call FixPath, $(OUTPUT_DIR)/objs)

$(OUTPUT_DIR)/$(OUTPUT): $(OUTPUT_DIR)/objs $(OBJS)
	$(AR) rcs $(OUTPUT_DIR)/$(OUTPUT) $(OBJS)

clean:
	$(RM) $(call FixPath,$(OBJS))
	$(RM) $(call FixPath, $(OUTPUT_DIR)/$(OUTPUT))

# for Makefile debug
print-%  : ; @echo $* = $($*)

.phony: all clean size 
