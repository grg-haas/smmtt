# Arguments
#	1. Bits (32/64)
#	2. smmtt/max

define run-targets

#TESTS$(1)_RUN_ENV = \
#	FIRMWARE_OVERRIDE=$$(OPENSBI$(1)_BUILDDIR)/platform/generic/firmware/fw_jump.bin \
#	QEMU=$$(QEMU_BUILDDIR)/qemu-system-riscv$(1)

#.PHONY: run-tests$(1)
#run-tests$(1): tests$(1) opensbi$(1) qemu
#	( cd $$(TESTS$(1)_BUILDDIR) ; $$(TESTS$(1)_RUN_ENV) ./riscv-run ./riscv/sbi.flat )

QEMU$(1)$(2)_RUN_FLAGS = \
	-nodefaults -nographic -serial mon:stdio -machine virt,rpmi=true -accel tcg \
	-bios $$(OPENSBI$(1)_BUILDDIR)/platform/generic/firmware/fw_jump.bin \
	-kernel $$(LINUX$(1)_BUILDDIR)/arch/riscv/boot/Image \
	-no-reboot -append "earlycon console=ttyS0 panic=-1" -cpu $(2)

ifeq ($(1),32)
	QEMU$(1)$(2)_RUN_FLAGS += -m 1536M
else ifeq ($(1),64)
	QEMU$(1)$(2)_RUN_FLAGS += -m 4G
endif

.PHONY: run-$(2)$(1)
run-$(2)$(1):
	$$(QEMU_BUILDDIR)/qemu-system-riscv$(1) $$(QEMU$(1)$(2)_RUN_FLAGS)

.PHONY: debug-$(2)$(1)
debug-$(2)$(1):
	$$(QEMU_BUILDDIR)/qemu-system-riscv$(1) $$(QEMU$(1)$(2)_RUN_FLAGS) -gdb tcp::9822 -S

.PHONY: qemudbg-$(2)$(1)
qemudbg-$(2)$(1):
	gdb --args $$(QEMU_BUILDDIR)/qemu-system-riscv$(1) $$(QEMU$(1)$(2)_RUN_FLAGS)

.PHONY: alldbg-$(2)$(1)
alldbg-$(2)$(1):
	gdb --args $$(QEMU_BUILDDIR)/qemu-system-riscv$(1) $$(QEMU$(1)$(2)_RUN_FLAGS) -gdb tcp::9822 -S

.PHONY: dumpdtb-$(2)$(1)
dumpdtb-$(2)$(1):
	$$(QEMU_BUILDDIR)/qemu-system-riscv$(1) $$(QEMU$(1)$(2)_RUN_FLAGS) -machine dumpdtb=qemu-$(2)$(1).dtb

endef
