# Each of these macros have the arguments
#	1. Bits (32/64)
#	2. smmtt/max
#	3. test target

## Targets/helpers for running QEMU ##
define __run-target

.PHONY: run-$(3)-$(2)$(1)
run-$(3)-$(2)$(1):
	$$(QEMU$(1)$(2)$(3)_CMD)

ideacfgs: $$(IDEACFG)/run-$(3)-$(2)$(1).xml
$$(IDEACFG)/run-$(3)-$(2)$(1).xml: $$(SMMTT)/mk/run.mk
	mkdir -p $$(IDEACFG)
	m4 -DSMMTT_NAME=\"run-$(3)-$(2)$(1)\" \
                -DSMMTT_PARAMS="\"$$(QEMU$(1)$(2)$(3)_RUN_FLAGS_STRIPPED)\"" \
                -DSMMTT_QEMU_PATH=\"$$(QEMU_BUILDDIR)/qemu-system-riscv$(1)\" \
                $$(SMMTT)/scripts/templates/run.xml > $$@
endef

## Targets/helpers for debugging programs inside of QEMU ##
define __dbg-target

.PHONY: dbg-$(3)-$(2)$(1)
dbg-$(3)-$(2)$(1):
	$$(QEMU$(1)$(2)$(3)_CMD) -gdb tcp::9822 -S

ideacfgs: $$(IDEACFG)/dbg-$(3)-$(2)$(1).xml
$$(IDEACFG)/dbg-$(3)-$(2)$(1).xml: $$(SMMTT)/mk/run.mk
	mkdir -p $$(IDEACFG)
	m4 -DSMMTT_NAME=\"dbg-$(3)-$(2)$(1)\" \
                -DSMMTT_PARAMS="\"$$(QEMU$(1)$(2)$(3)_RUN_FLAGS_STRIPPED) -gdb tcp::9822 -S\"" \
                -DSMMTT_QEMU_PATH=\"$$(QEMU_BUILDDIR)/qemu-system-riscv$(1)\" \
                $$(SMMTT)/scripts/templates/run.xml > $$@

endef

## Targets/helpers for connecting GDB to QEMU programs ##
define __connect-target

.PHONY: connect-$(3)-$(2)$(1)
connect-$(3)-$(2)$(1):
	SMMTT_BITS=$(1) SMMTT_ISOL=$(2) SMMTT_TEST=$(3) \
	PYTHONPATH=$$(LINUX$(1)_BUILDDIR)/scripts/gdb \
	$$(CROSS_COMPILE$(1))gdb -x $$(SMMTT)/scripts/gdb/gdb.cfg

ideacfgs: $$(IDEACFG)/connect-$(3)-$(2)$(1).xml
$$(IDEACFG)/connect-$(3)-$(2)$(1).xml: $$(SMMTT)/mk/run.mk
	mkdir -p $$(IDEACFG)
	m4 -DSMMTT_NAME=\"connect-$(3)-$(2)$(1)\" \
		-DSMMTT_OPENSBI=\"$$(OPENSBI$(1)_BUILDDIR)//platform/generic/firmware/fw_jump.elf\" \
		-DSMMTT_DEBUGGER="/bin/$$(CROSS_COMPILE$(1))gdb" \
		-DSMMTT_BITS_VAL=\"$(1)\" -DSMMTT_ISOL_VAL=\"$(2)\" -DSMMTT_TEST_VAL=\"$(3)\" \
		$$(SMMTT)/scripts/templates/remote.xml > $$@

ideacfgs: $$(IDEACFG)/$(3)-$(2)$(1).xml
$$(IDEACFG)/$(3)-$(2)$(1).xml: $$(SMMTT)/mk/run.mk
	mkdir -p $$(IDEACFG)
	m4 -DSMMTT_NAME=\"$(3)-$(2)$(1)\" \
		-DSMMTT_QEMU=\"dbg-$(3)-$(2)$(1)\" \
		-DSMMTT_REMOTE=\"connect-$(3)-$(2)$(1)\" \
		$$(SMMTT)/scripts/templates/compound.xml > $$@

endef

## Main generation function ##
define run-targets

# Derive the flags to use
QEMU$(1)$(2)$(3)_RUN_FLAGS = \
	-nodefaults -nographic -serial mon:stdio -machine virt,rpmi=true -accel tcg \
	-bios $$(OPENSBI$(1)_BUILDDIR)/platform/generic/firmware/fw_jump.bin \
	-kernel $$(LINUX$(1)_BUILDDIR)/arch/riscv/boot/Image \
	-no-reboot -append "earlycon console=ttyS0 panic=-1" -cpu $(2)

ifeq ($(1),32)
	QEMU$(1)$(2)$(3)_RUN_FLAGS += -m 1536M
else ifeq ($(1),64)
	QEMU$(1)$(2)$(3)_RUN_FLAGS += -m 4G
endif

ifeq ($(3),linux)
	QEMU$(1)$(2)$(3)_RUN_FLAGS += -kernel $$(LINUX$(1)_BUILDDIR)/arch/riscv/boot/Image
else ifeq ($(3),tests)
	QEMU$(1)$(2)$(3)_RUN_FLAGS += -kernel $$(TESTS$(1)_BUILDDIR)/riscv/sbi.flat
endif

# Strip the flags for use in IDEA cfg files
QEMU$(1)$(2)$(3)_RUN_FLAGS_STRIPPED = $$(shell echo '$$(QEMU$(1)$(2)$(3)_RUN_FLAGS)' | sed 's/"/\&quot;/g')

# Specify the full QEMU command for make helpers
QEMU$(1)$(2)$(3)_CMD = $$(QEMU_BUILDDIR)/qemu-system-riscv$(1) $$(QEMU$(1)$(2)$(3)_RUN_FLAGS)

$$(eval $$(call __run-target,$(1),$(2),$(3)))
$$(eval $$(call __dbg-target,$(1),$(2),$(3)))
$$(eval $$(call __connect-target,$(1),$(2),$(3)))

# Target for debugging QEMU itself
.PHONY: qemudbg-$(3)-$(2)$(1)
qemudbg-$(3)-$(2)$(1):
	gdb --args $$(QEMU$(1)$(2)$(3)_CMD)

# Target for debugging both QEMU and its applications simultaneously
.PHONY: alldbg-$(3)-$(2)$(1)
alldbg-$(3)-$(2)$(1):
	gdb --args $$(QEMU$(1)$(2)$(3)_CMD) -gdb tcp::9822 -S

# Utility for dumping DTBs from QEMU
.PHONY: dumpdtb-$(3)-$(2)$(1)
dumpdtb-$(3)-$(2)$(1):
	$$(QEMU$(1)$(2)$(3)_CMD) -machine dumpdtb=qemu-$(3)-$(2)$(1).dtb

endef
