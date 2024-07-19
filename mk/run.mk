# Arguments
#	1. Bits (32/64)
#	2. smmtt/max
#	3. test target

define run-targets

#TESTS$(1)_RUN_ENV = \
#	FIRMWARE_OVERRIDE=$$(OPENSBI$(1)_BUILDDIR)/platform/generic/firmware/fw_jump.bin \
#	QEMU=$$(QEMU_BUILDDIR)/qemu-system-riscv$(1)

#.PHONY: run-tests$(1)
#run-tests$(1): tests$(1) opensbi$(1) qemu
#	( cd $$(TESTS$(1)_BUILDDIR) ; $$(TESTS$(1)_RUN_ENV) ./riscv-run ./riscv/sbi.flat )

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

QEMU$(1)$(2)$(3)_CMD = $$(QEMU_BUILDDIR)/qemu-system-riscv$(1) $$(QEMU$(1)$(2)$(3)_RUN_FLAGS)

.PHONY: run-$(3)-$(2)$(1)
run-$(3)-$(2)$(1):
	$$(QEMU$(1)$(2)$(3)_CMD)

.PHONY: debug-$(3)-$(2)$(1)
debug-$(3)-$(2)$(1):
	$$(QEMU$(1)$(2)$(3)_CMD) -gdb tcp::9822 -S

.PHONY: qemudbg-$(3)-$(2)$(1)
qemudbg-$(3)-$(2)$(1):
	gdb --args $$(QEMU$(1)$(2)$(3)_CMD)

.PHONY: alldbg-$(3)-$(2)$(1)
alldbg-$(3)-$(2)$(1):
	gdb --args $$(QEMU$(1)$(2)$(3)_CMD) -gdb tcp::9822 -S

.PHONY: dumpdtb-$(3)-$(2)$(1)
dumpdtb-$(3)-$(2)$(1):
	$$(QEMU$(1)$(2)$(3)_CMD) -machine dumpdtb=qemu-$(3)-$(2)$(1).dtb

endef
