
# Arguments: bits
define build-linux

$$(eval $$(call project-vars,linux,$(1)))

LINUX$(1)_MK_FLAGS		:= ARCH=riscv CROSS_COMPILE=$$(CROSS_COMPILE$(1)) V=$$(VERBOSE)

.PHONY: linux$(1)
linux$(1): $$(LINUX$(1)_BUILDDIR)/Makefile
	$$(MAKE) $$(LINUX$(1)_MK_FLAGS) -C $$(LINUX$(1)_BUILDDIR)

LINUX$(1)_CFG_FLAGS		:= $$(LINUX$(1)_MK_FLAGS) O=$$(LINUX$(1)_BUILDDIR)
ifeq ($(1),32)
LINUX$(1)_DEFCONFIG		:= rv$(1)_defconfig
else
LINUX$(1)_DEFCONFIG		:= defconfig
endif

$$(LINUX$(1)_BUILDDIR)/Makefile:
	$$(MAKE) $$(LINUX$(1)_CFG_FLAGS) -C linux $$(LINUX$(1)_DEFCONFIG)
ifneq ($$(DEBUG),0)
	echo "CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT=y" >> $$(LINUX$(1)_BUILDDIR)/.config
	echo "CONFIG_GDB_SCRIPTS=y" >> $$(LINUX$(1)_BUILDDIR)/.config
	$$(MAKE) $$(LINUX$(1)_CFG_FLAGS) -C linux olddefconfig
endif

.PHONY: clean-linux$(1)
clean-linux$(1):
	rm -rf $$(LINUX$(1)_BUILDDIR)

endef
