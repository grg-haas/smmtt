
# Arguments: bits
define build-opensbi

$$(eval $$(call project-vars,opensbi,$(1)))

OPENSBI$(1)_MK_FLAGS	:= PLATFORM=generic O=$$(OPENSBI$(1)_BUILDDIR) FW_TEXT_START=0x80000000 \
                            V=$$(VERBOSE) DEBUG=$$(DEBUG) CROSS_COMPILE=$$(CROSS_COMPILE$(1)) \
                            EXTRA_CFLAGS="-I$(SMMTT)/shared/include -DSMMTT_OPENSBI"

.PHONY: opensbi$(1)
opensbi$(1):
	mkdir -p $$(OPENSBI$(1)_BUILDDIR)
	$$(MAKE) -C opensbi $$(OPENSBI$(1)_MK_FLAGS)

.PHONY: clean-opensbi$(1)
clean-opensbi$(1):
	rm -rf $$(OPENSBI$(1)_BUILDDIR)

endef
