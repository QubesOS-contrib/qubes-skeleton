# PACKAGE_SET variable is provided by qubes-builder at build time
# Any name can be given to spec files. Here names does not contain
# the suffix '.in' like the corresponding files 'skeleton.spec.in'
# and 'skeleton-vm.spec.in'
ifeq ($(PACKAGE_SET),dom0)
RPM_SPEC_FILES := rpm_spec/skeleton.spec
else
RPM_SPEC_FILES := rpm_spec/skeleton-vm.spec
endif