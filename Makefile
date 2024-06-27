
###################
## Configuration ##
###################

# Compilers and tools
export SHELL			:= /bin/bash
export CROSS_COMPILE32		:= riscv32-unknown-linux-gnu-
export CROSS_COMPILE64		:= riscv64-unknown-linux-gnu-

export VERBOSE			?= 0
export DEBUG			?= 0

# Directories
export SMMTT			?= $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
export CCACHE_DIR		:= $(SMMTT)/.ccache

###################
## Build recipes ##
###################

all: opensbi32 opensbi64 tests32 tests64 linux32 linux64 qemu

include mk/utils.mk
include mk/opensbi.mk
include mk/qemu.mk
include mk/tests.mk
include mk/linux.mk

$(eval $(call build-opensbi,32))
$(eval $(call build-opensbi,64))
$(eval $(call build-tests,32))
$(eval $(call build-tests,64))
$(eval $(call build-linux,32))
$(eval $(call build-linux,64))

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
