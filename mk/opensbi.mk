
# Arguments: bits
define build-opensbi

$$(eval $$(call project-vars,opensbi,$(1)))

OPENSBI$(1)_MK_FLAGS	:= PLATFORM=generic O=$$(OPENSBI$(1)_BUILDDIR) \
							V=$$(VERBOSE) DEBUG=$$(DEBUG) CROSS_COMPILE=$$(CROSS_COMPILE$(1))
.PHONY: opensbi$(1)

opensbi$(1):
	mkdir -p $$(OPENSBI$(1)_BUILDDIR)
	$$(MAKE) -C opensbi $$(OPENSBI$(1)_MK_FLAGS)

endef
