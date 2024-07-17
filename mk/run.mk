
define run-targets

TESTS$(1)_RUN_ENV = \
	FIRMWARE_OVERRIDE=$$(OPENSBI$(1)_BUILDDIR)/platform/generic/firmware/fw_jump.bin \
	QEMU=$$(QEMU_BUILDDIR)/qemu-system-riscv$(1)

.PHONY: run-tests$(1)
run-tests$(1): tests$(1) opensbi$(1) qemu
	( cd $$(TESTS$(1)_BUILDDIR) ; $$(TESTS$(1)_RUN_ENV) ./riscv-run ./riscv/sbi.flat )

QEMU$(1)_RUN_FLAGS = \
	-nodefaults -nographic -serial mon:stdio -machine virt -accel tcg \
	-bios $$(OPENSBI$(1)_BUILDDIR)/platform/generic/firmware/fw_jump.bin \
	-kernel $$(LINUX$(1)_BUILDDIR)/arch/riscv/boot/Image \
	-no-reboot -append "earlycon console=ttyS0 panic=-1"

ifeq ($(1),32)
	QEMU$(1)_RUN_FLAGS += -m 1536M
else ifeq ($(1),64)
	QEMU$(1)_RUN_FLAGS += -m 4G
endif

.PHONY: run-linux-smmtt$(1)
run-linux-smmtt$(1): #qemu opensbi$(1) linux$(1)
	$$(QEMU_BUILDDIR)/qemu-system-riscv$(1) $$(QEMU$(1)_RUN_FLAGS) -cpu smmtt

.PHONY: run-linux-pmp$(1)
run-linux-pmp$(1): #qemu opensbi$(1) linux$(1)
	$$(QEMU_BUILDDIR)/qemu-system-riscv$(1) $$(QEMU$(1)_RUN_FLAGS) -cpu max

endef
