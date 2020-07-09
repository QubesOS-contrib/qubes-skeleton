# PACKAGE_SET variable is provided by qubes-builder at build time
# Any name can be given to spec files. Here names does not contain
# the suffix '.in' like the corresponding files 'skeleton.spec.in'
# and 'skeleton-vm.spec.in'
RPM_SPEC_FILES.dom0 := rpm_spec/skeleton-dom0.spec
RPM_SPEC_FILES.vm := rpm_spec/skeleton-vm.spec

RPM_SPEC_FILES := $(RPM_SPEC_FILES.$(PACKAGE_SET))