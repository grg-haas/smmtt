
## Targets/helpers for running QEMU ##
define __run-target

.PHONY: run-$(1)
run-$(1):
	$$(QEMU$(1)_CMD)

ideacfgs: $$(IDEACFG)/run-$(1).xml
$$(IDEACFG)/run-$(1).xml: $$(SMMTT)/mk/run.mk
	mkdir -p $$(IDEACFG)
	m4 -DSMMTT_NAME=\"run-$(1)\" \
                -DSMMTT_PARAMS="\"$$(QEMU$(1)_RUN_FLAGS_STRIPPED)\"" \
                -DSMMTT_QEMU_PATH=\"$$(QEMU_BUILDDIR)/qemu-system-riscv$(2)\" \
                $$(SMMTT)/scripts/templates/run.xml > $$@
endef

## Targets/helpers for debugging programs inside of QEMU ##
define __dbg-target

.PHONY: dbg-$(1)
dbg-$(1):
	$$(QEMU$(1)_CMD) -gdb tcp::9822 -S

ideacfgs: $$(IDEACFG)/dbg-$(1).xml
$$(IDEACFG)/dbg-$(1).xml: $$(SMMTT)/mk/run.mk
	mkdir -p $$(IDEACFG)
	m4 -DSMMTT_NAME=\"dbg-$(1)\" \
                -DSMMTT_PARAMS="\"$$(QEMU$(1)_RUN_FLAGS_STRIPPED) -gdb tcp::9822 -S\"" \
                -DSMMTT_QEMU_PATH=\"$$(QEMU_BUILDDIR)/qemu-system-riscv$(2)\" \
                $$(SMMTT)/scripts/templates/run.xml > $$@

endef

## Targets/helpers for connecting GDB to QEMU programs ##
define __connect-target

.PHONY: connect-$(1)
connect-$(1):
	PYTHONPATH=$$(LINUX$(1)_BUILDDIR)/scripts/gdb \
		$$(CROSS_COMPILE$(1))gdb -x $$(SMMTT)/scripts/gdb/gdb.cfg \
		$$(OPENSBI$(2)_BUILDDIR)/platform/generic/firmware/fw_jump.elf

ideacfgs: $$(IDEACFG)/connect-$(1).xml
$$(IDEACFG)/connect-$(1).xml: $$(SMMTT)/mk/run.mk
	mkdir -p $$(IDEACFG)
	m4 -DSMMTT_NAME=\"connect-$(1)\" \
		-DSMMTT_OPENSBI=\"$$(OPENSBI$(2)_BUILDDIR)/platform/generic/firmware/fw_jump.elf\" \
		-DSMMTT_DEBUGGER="/bin/$$(CROSS_COMPILE$(2))gdb" \
		$$(SMMTT)/scripts/templates/remote.xml > $$@

ideacfgs: $$(IDEACFG)/$(1).xml
$$(IDEACFG)/$(1).xml: $$(SMMTT)/mk/run.mk
	mkdir -p $$(IDEACFG)
	m4 -DSMMTT_NAME=\"$(1)\" \
		-DSMMTT_QEMU=\"dbg-$(1)\" \
		-DSMMTT_REMOTE=\"connect-$(1)\" \
		$$(SMMTT)/scripts/templates/compound.xml > $$@

endef

## Miscellaneous targets/helpers
define __misc-targets

# Target for debugging QEMU itself
.PHONY: qemudbg-$(1)
qemudbg-$(1):
	gdb --args $$(QEMU$(1)_CMD)

# Target for debugging both QEMU and its applications simultaneously
.PHONY: alldbg-$(1)
alldbg-$(1):
	gdb --args $$(QEMU$(1)_CMD) -gdb tcp::9822 -S

# Utility for dumping DTBs from QEMU
.PHONY: dumpdtb-$(1)
dumpdtb-$(1):
	$$(QEMU$(1)_CMD) -machine dumpdtb=qemu-$(1).dtb

endef

## Generate QEMU flags
##	1. Bits (32/64)
##	2. smmtt/max
##	3. test target
##	4. optional suffix

define qemu-flags

QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS = \
	-nodefaults -nographic -serial mon:stdio -machine virt,rpmi=true -accel tcg \
	-bios $$(OPENSBI$(1)_BUILDDIR)/platform/generic/firmware/fw_jump.bin \
	-no-reboot -smp 2

ifeq ($(1),32)
	# 2 pages less than 2 gigabytes. This is the highest amount of RAM that can
	# be specified such that kvm-unit-tests can still initialize
	QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS += -m 2097144k
else ifeq ($(1),64)
	QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS += -m 4G
endif

ifeq ($(2),max)
	QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS += -cpu max
else ifeq ($(2),smmtt)
	QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS += -cpu smmtt

	# Add reserved memory for SMMTT tables
	QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS += \
		-device opensbi-memregion,id=smmtt-tables,base=0x84000000,size=0x4000000,reserve=true
endif

ifeq ($(3),linux)
	QEMU$(3)-$(2)$(1)$(4)_RUN_FILE = $$(LINUX$(1)_BUILDDIR)/arch/riscv/boot/Image
	QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS += -append "earlycon console=ttyS0 panic=-1"
else ifeq ($(3),tests)
	QEMU$(3)-$(2)$(1)$(4)_RUN_FILE = $$(TESTS$(1)_BUILDDIR)/riscv/sbi.flat
else ifeq ($(3),unittests)
	QEMU$(3)-$(2)$(1)$(4)_RUN_FILE = $$(TESTS$(1)_BUILDDIR)/riscv/smmtt.flat
	QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS += -append "primary"
endif

QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS += -kernel $$(QEMU$(3)-$(2)$(1)$(4)_RUN_FILE)

endef

define qemu-strip-cmd

# Strip the flags for use in IDEA cfg files
QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS_STRIPPED = $$(shell echo '$$(QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS)' | sed 's/"/\&quot;/g')

# Specify the full QEMU command for make helpers
QEMU$(3)-$(2)$(1)$(4)_CMD = $$(QEMU_BUILDDIR)/qemu-system-riscv$(1) $$(QEMU$(3)-$(2)$(1)$(4)_RUN_FLAGS)

endef

## Main generation function
##	1. Bits (32/64)
##	2. smmtt/max
##	3. test target

define run-targets

$$(eval $$(call qemu-flags,$(1),$(2),$(3),))
$$(eval $$(call qemu-strip-cmd,$(1),$(2),$(3),))

$$(eval $$(call __run-target,$(3)-$(2)$(1),$(1)))
$$(eval $$(call __dbg-target,$(3)-$(2)$(1),$(1)))
$$(eval $$(call __connect-target,$(3)-$(2)$(1),$(1)))
$$(eval $$(call __misc-targets,$(3)-$(2)$(1)))

endef

# Subgenerator
#	1. Bits
#	2. Name
#	3. QEMU name
#	4. Mode index
#	5. Perm value
define __unit-test-generate

$$(eval $$(call qemu-flags,$(1),smmtt,unittests,-$(2)))

# Add secondary base memory region
$(3)_RUN_FLAGS += \
	-device loader,file=$$($(3)_RUN_FILE),addr=0x90000000,force-raw=on \
	-device opensbi-memregion,id=mem,base=0x90000000,size=0x4000000,mmio=false,reserve=true \
	-device opensbi-memregion,id=uart,base=0x10000000,size=0x1000,mmio=true,device0="/soc/serial@10000000"

# Add test memory regions
$(3)_RUN_FLAGS += \
	-device opensbi-memregion,id=oneg,base=0xC0000000,size=0x40000000,mmio=false,reserve=true \
	-device opensbi-memregion,id=twom,base=0xB0000000,size=0x200000,mmio=false,reserve=true \
	-device opensbi-memregion,id=l1,base=0xB8000000,size=0x1000,mmio=false,reserve=true

$(3)_BOOT = possible-harts=0-1,boot-hart=0x0,next-addr=0x90000000,next-arg1=0x90200000,next-mode=1,smmtt-mode=$(4),system-reset-allowed=true
$(3)_REGIONS = region0=mem,perms0=0x3f,region1=uart,perms1=0x3f,region2=oneg,perms2=$(5),region3=twom,perms3=$(5),region4=l1,perms4=$(5)

# Add secondary domain
$(3)_RUN_FLAGS += \
	-device opensbi-domain,id=domain,$$($(3)_BOOT),$$($(3)_REGIONS)

$$(eval $$(call qemu-strip-cmd,$(1),smmtt,unittests,-$(2)))

$$(eval $$(call __run-target,unittests-smmtt$(1)-$(2),$(1)))
$$(eval $$(call __dbg-target,unittests-smmtt$(1)-$(2),$(1)))
$$(eval $$(call __connect-target,unittests-smmtt$(1)-$(2),$(1)))
$$(eval $$(call __misc-targets,unittests-smmtt$(1)-$(2)))

endef

SMMTT1_PERM_INDICES	:= 1 2 3
SMMTT0_PERM_INDICES	:= 1 2

SMMTT1_PERM_VALUES	:= 0x0 0xf 0x1f
SMMTT0_PERM_VALUES	:= 0x0 0x3f

SMMTT1_PERM_NAMES	:= disallow allow-r allow-rw
SMMTT0_PERM_NAMES	:= disallow allow

## Subgenerator
#	1. Bits
#	2. Mode index
#	3. Mode name
#	4. Is mode rw
define __unit-test-perms

$(foreach perm,$(SMMTT$(4)_PERM_INDICES),
SMMTT$(1)_$(perm)_PERMNAME = $(word $(perm),$(SMMTT$(4)_PERM_NAMES))
SMMTT$(1)_$(perm)_PERMVAL = $(word $(perm),$(SMMTT$(4)_PERM_VALUES))
SMMTT$(1)_$(2)_$(perm)_NAME = $(3)-$$(SMMTT$(1)_$(perm)_PERMNAME)
SMMTT$(1)_$(2)_$(perm)_QEMUNAME = QEMUunittests-smmtt$(1)-$$(SMMTT$(1)_$(2)_$(perm)_NAME)

$$(eval $$(call __unit-test-generate,$(1),$$(SMMTT$(1)_$(2)_$(perm)_NAME),$$(SMMTT$(1)_$(2)_$(perm)_QEMUNAME),$(2),$$(SMMTT$(1)_$(perm)_PERMVAL)))
)
endef


## Unit test generator
##	1. Bits (32/64)

SMMTT32_MODE_INDICES	:= 1 2
SMMTT64_MODE_INDICES	:= 1 2 3 4

SMMTT32_MODE_NAMES 	:= smmtt34-rw smmtt34
SMMTT64_MODE_NAMES 	:= smmtt46-rw smmtt46 smmtt56-rw smmtt56

define unit-test-targets

$(foreach mode,$(SMMTT$(1)_MODE_INDICES),

SMMTT$(1)_$(mode)_MODENAME = $(word $(mode),$(SMMTT$(1)_MODE_NAMES))
SMMTT$(1)_$(mode)_ISRW = $(shell echo $$(( $(mode) % 2 )))
$$(eval $$(call __unit-test-perms,$(1),$(mode),$$(SMMTT$(1)_$(mode)_MODENAME),$$(SMMTT$(1)_$(mode)_ISRW)))

)

endef

