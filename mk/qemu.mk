
# QEMU
$(eval $(call project-vars,qemu,))

QEMU_MK_FLAGS	:=
ifneq ($(VERBOSE),0)
	QEMU_MK_FLAGS += V=$(VERBOSE)
endif

.PHONY: qemu
qemu: $(QEMU_BUILDDIR)/Makefile
	$(MAKE) -C $(QEMU_BUILDDIR) $(QEMU_MK_FLAGS)

QEMU_CFG_FLAGS	:= --without-default-features --enable-system --target-list="riscv64-softmmu,riscv32-softmmu" \
			--ninja=$(SMMTT)/scripts/ninja_filtered.sh

ifneq ($(DEBUG),0)
	QEMU_CFG_FLAGS += --enable-debug --disable-strip
endif

$(QEMU_BUILDDIR)/Makefile:
	mkdir -p $(QEMU_BUILDDIR)
	( cd $(QEMU_BUILDDIR) ; $(SMMTT)/qemu/configure $(QEMU_CFG_FLAGS) )