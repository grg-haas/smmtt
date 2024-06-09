
###################
## Configuration ##
###################

# Compilers and tools
export SHELL 		:= /bin/bash
export CROSS_COMPILE 	?= riscv64-linux-gnu-

export VERBOSE		?= 0
export DEBUG		?= 0

# Directories
export SMMTT		?= $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

ifneq ($(DEBUG),0)
export SMMTT_BUILDDIR	:= $(SMMTT)/build/dbg
else
export SMMTT_BUILDDIR	:= $(SMMTT)/build/rel
endif

export OPENSBI_BUILDDIR	:= $(SMMTT_BUILDDIR)/opensbi
export QEMU_BUILDDIR	:= $(SMMTT_BUILDDIR)/qemu

###################
## Build recipes ##
###################

all: opensbi qemu

# OpenSBI
OPENSBI_MK_FLAGS 	:= PLATFORM=generic O=$(OPENSBI_BUILDDIR) V=$(VERBOSE) DEBUG=$(DEBUG)

.PHONY: opensbi
opensbi:
	mkdir -p $(OPENSBI_BUILDDIR)
	$(MAKE) -C opensbi $(OPENSBI_MK_FLAGS)


# QEMU
QEMU_MK_FLAGS	:=

ifneq ($(VERBOSE),0)
	QEMU_MK_FLAGS += V=$(VERBOSE)
endif

.PHONY: qemu
qemu: $(QEMU_BUILDDIR)/Makefile
	$(MAKE) -C $(QEMU_BUILDDIR) $(QEMU_MK_FLAGS)

QEMU_CFG_FLAGS	:= --without-default-features --enable-system --target-list="riscv64-softmmu" \
			--ninja=$(SMMTT)/scripts/ninja_filtered.sh

ifneq ($(DEBUG),0)
	QEMU_CFG_FLAGS += --enable-debug --disable-strip
endif

$(QEMU_BUILDDIR)/Makefile:
	mkdir -p $(QEMU_BUILDDIR)
	( cd $(QEMU_BUILDDIR) ; $(SMMTT)/qemu/configure $(QEMU_CFG_FLAGS) )

# Cleaning
.PHONY: clean
clean:
	rm -rf $(SMMTT_BUILDDIR)

#################
## Run recipes ##
#################

QEMU_RUN_FLAGS	:= -nographic -bios $(OPENSBI_BUILDDIR)/platform/generic/firmware/fw_jump.bin

run: $(QEMU_BUILDDIR)/qemu-system-riscv64
	$(QEMU_BUILDDIR)/qemu-system-riscv64 $(QEMU_RUN_FLAGS)

