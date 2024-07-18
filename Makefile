
###################
## Configuration ##
###################

# Compilers and tools
export SHELL			:= /bin/bash
export CROSS_COMPILE32		?= riscv32-unknown-linux-gnu-
export CROSS_COMPILE64		?= riscv64-unknown-linux-gnu-

export VERBOSE			?= 0
export DEBUG			?= 0

# Directories
export SMMTT			?= $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
ifeq ($(CCACHE_DIR),)
export CCACHE_DIR		:= $(SMMTT)/.ccache
else
export CCACHE_DIR		:= $(CCACHE_DIR)
endif

###################
## Build recipes ##
###################

BITS            := 32 64
PROJECTS	:= opensbi linux #tests
ISOLATION	:= max smmtt

# Generate toplevel targets
TARGETS := $(foreach proj,$(PROJECTS),	\
		$(foreach bits,$(BITS),	\
			$(proj)$(bits)))
TARGETS += qemu
all: $(TARGETS)

# Include helper files
include mk/utils.mk
include mk/run.mk

include mk/qemu.mk
$(foreach proj,$(PROJECTS),		\
	$(eval include mk/$(proj).mk))

# Generate subtargets
$(foreach proj,$(PROJECTS),	\
	$(foreach bits,$(BITS),	\
		$(eval $(call build-$(proj),$(bits)))))

# Generate tests
$(foreach mode,$(ISOLATION),	\
	$(foreach bits,$(BITS),	\
		$(eval $(call run-targets,$(bits),$(mode)))))

# Cleaning
.PHONY: clean
clean:
	rm -rf $(SMMTT)/build

.PHONY: clean-opensbi
clean-opensbi: clean-opensbi32 clean-opensbi64

.PHONY: clean-tests
clean-tests: clean-tests32 clean-tests64

.PHONY: clean-linux
clean-linux: clean-linux32 clean-linux64
