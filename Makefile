
###################
## Configuration ##
###################

# Compilers and tools
export SHELL			:= /bin/bash
export BITS				:= 32

export CROSS_COMPILE32	:= riscv32-unknown-linux-gnu-
export CROSS_COMPILE64	:= riscv64-unknown-linux-gnu-

export VERBOSE			?= 0
export DEBUG			?= 0

# Directories
export SMMTT			?= $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
export CCACHE_DIR		:= $(SMMTT)/.ccache

###################
## Build recipes ##
###################

all: opensbi32 opensbi64 qemu

include mk/utils.mk
include mk/opensbi.mk
include mk/qemu.mk

$(eval $(call build-opensbi,32))
$(eval $(call build-opensbi,64))


# Cleaning
.PHONY: clean
clean:
	rm -rf $(SMMTT)/build

.PHONY: clean-opensbi
clean-opensbi: clean-opensbi32 clean-opensbi64
