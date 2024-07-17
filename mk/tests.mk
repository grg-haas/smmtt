
# Arguments: bits
define build-tests

$$(eval $$(call project-vars,tests,$(1)))

.PHONY: tests$(1)
tests$(1): $$(TESTS$(1)_BUILDDIR)/Makefile
	$$(MAKE) -C $$(TESTS$(1)_BUILDDIR)

TESTS$(1)_CFLAGS = -I$$(TESTS$(1)_BUILDDIR)/lib
TESTS$(1)_CFG_FLAGS := --arch=riscv$(1) --processor=smmtt \
 						--cross-prefix=$$(CROSS_COMPILE$(1)) --cflags="$$(TESTS$(1)_CFLAGS)"

ifneq ($(DEBUG),0)
	TESTS$(1)_CFG_FLAGS += --disable-werror
endif

ifeq ($(1),32)
	TESTS$(1)_CFG_FLAGS += --memory=1536M
else ifeq ($(1),64)
	TESTS$(1)_CFG_FLAGS += --memory=4G
endif

$$(TESTS$(1)_BUILDDIR)/Makefile:
	mkdir -p $$(TESTS$(1)_BUILDDIR)
	( cd $$(TESTS$(1)_BUILDDIR) ; $(SMMTT)/kvm-unit-tests/configure $$(TESTS$(1)_CFG_FLAGS))
	mkdir -p $$(TESTS$(1)_BUILDDIR)/lib/{riscv,generated,libfdt}

.PHONY: clean-tests$(1)
clean-tests$(1):
	rm -rf $$(TESTS$(1)_BUILDDIR)

endef