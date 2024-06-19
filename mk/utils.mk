
to_upper = $(shell echo $(1) | tr '[:lower:]' '[:upper:]')
to_lower = $(shell echo $(1) | tr '[:upper:]' '[:lower:]')

# Arguments: project, bits
define project-vars
	ifneq ($$(DEBUG),0)
		export $(call to_upper,$(1))$(2)_BUILDDIR = $$(SMMTT)/build/dbg/$(call to_lower,$(1))$(2)
	else
		export $(call to_upper,$(1))$(2)_BUILDDIR = $$(SMMTT)/build/rel/$(call to_lower,$(1))$(2)
	endif
endef