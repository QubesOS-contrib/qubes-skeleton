qubes-skeleton
===

A minimal reference package for Qubes OS components built with
[qubes-builderv2](https://github.com/QubesOS/qubes-builderv2). Use it as a
starting point when creating a new component, or as a reference for how the
build system expects files to be laid out.


## Repository layout

```
qubes-skeleton/
├── .qubesbuilder               # Tells qubes-builderv2 what to build and for which targets
├── Makefile                    # install-dom0 / install-vm targets consumed by the spec/rules files
├── README.dom0                 # Installed as /usr/lib/qubes/skeleton/README on dom0
├── README.vm                   # Installed as /usr/lib/qubes/skeleton/README in VMs
├── debian/                     # Debian packaging (VM distributions only)
│   ├── changelog
│   ├── compat
│   ├── control
│   ├── copyright
│   ├── qubes-skeleton.install
│   ├── rules
│   └── source/
│       └── format
├── rel                         # Plain-text release/revision number (e.g. "1")
├── rpm_spec/
│   ├── skeleton-dom0.spec.in   # RPM spec template for the dom0 package
│   └── skeleton-vm.spec.in     # RPM spec template for VM packages
├── skeleton.sh                 # The actual payload installed by both packages
└── version                     # Plain-text upstream version (e.g. "1.0.0")
```


## File-by-file guide

### `.qubesbuilder`

Declares what qubes-builderv2 should build and for which host/VM targets.
Each top-level key (`host`, `vm`) maps to a set of distribution types
(`rpm`, `deb`, etc.). Under `build:` list the spec/recipe files to use.

```yaml
host:
  rpm:
    build:
    - rpm_spec/skeleton-dom0.spec   # built for dom0 (host) RPM distributions
vm:
  rpm:
    build:
    - rpm_spec/skeleton-vm.spec     # built for VM RPM distributions
  deb:
    build:
    - debian                        # built for VM Debian distributions
```

The builder renders `*.spec.in` -> `*.spec` by substituting `@VERSION@`,
`@REL@`, and `@CHANGELOG@` before the spec is used. For Debian, the
`debian/changelog` is updated automatically.

### `version` and `rel`

Plain-text files containing the upstream version and the package release
number respectively. The builder reads them and substitutes them into
`@VERSION@` and `@REL@` inside RPM spec templates and into the Debian
`changelog`.

### `Makefile`

Contains `install-dom0` and `install-vm` targets. Each RPM spec's `%install`
section and the Debian `rules` file call one of these with the appropriate
`DESTDIR`. Add every file you want packaged to the appropriate target here,
then list it in the corresponding spec `%files` section or `.install` file.

```makefile
install-common:
	install -m 775 -D skeleton.sh $(DESTDIR)/usr/lib/qubes/skeleton/skeleton.sh

install-dom0: install-common
	install -m 664 -D README.dom0 $(DESTDIR)/usr/lib/qubes/skeleton/README

install-vm: install-common
	install -m 664 -D README.vm $(DESTDIR)/usr/lib/qubes/skeleton/README
```

### `rpm_spec/` - RPM packaging

Used when building for RPM-based distributions. Two spec templates are
provided: one for dom0 (host) and one for VMs.

**`rpm_spec/skeleton-dom0.spec.in`** - dom0 package:

```spec
%global debug_package %{nil}
Name: qubes-skeleton-dom0
Version: @VERSION@
Release: @REL@%{?dist}

Summary: Qubes Skeleton package for dom0
License: GPLv2+
URL: https://www.qubes-os.org/

Source0: %{name}-%{version}.tar.gz

BuildRequires: make

%description
Qubes Skeleton package for dom0.

%prep
%setup -q

#%build
#something to build?

%install
make install-dom0 DESTDIR=$RPM_BUILD_ROOT

%files
/usr/lib/qubes/skeleton/README
/usr/lib/qubes/skeleton/skeleton.sh

%changelog
@CHANGELOG@
```

**`rpm_spec/skeleton-vm.spec.in`** - VM package (identical structure, calls
`install-vm` and uses a different package name):

```spec
Name: qubes-skeleton-vm
...
%install
make install-vm DESTDIR=$RPM_BUILD_ROOT
...
```

The `%global debug_package %{nil}` line at the top disables the automatic
generation of `-debuginfo` and `-debugsource` sub-packages. RPM generates
those by default for packages that contain compiled binaries. For
script-only packages there are no binaries, so the generated file list is
empty and the build fails with:

```
error: Empty %files file .../debugsourcefiles.list
```

Keep this line for any package that installs only scripts or data files.
Remove it if the package ever builds and installs compiled binaries (RPM
will then produce useful debug packages automatically).

The placeholders replaced by the builder before the spec is used are:

| Placeholder    | Replaced with                           |
|----------------|-----------------------------------------|
| `@VERSION@`    | contents of `version`                   |
| `@REL@`        | contents of `rel`                       |
| `@CHANGELOG@`  | auto-generated changelog from git log   |

`Source0` must be `%{name}-%{version}.tar.gz` - the builder creates this
tarball automatically from the source tree.

Every file installed by the `%install` step must also be listed under
`%files`, otherwise the build fails with an unpackaged files error. If a
file should only be present on some architectures or conditionally included,
use RPM conditionals (`%ifarch`, `%if`) inside `%files`.

### `debian/` - Debian packaging

Used when building for Debian-based VM distributions (e.g. `vm-bookworm`,
`vm-trixie`). The key files are:

**`debian/control`** - source and binary package metadata:

```
Source: qubes-skeleton
Section: admin
Priority: optional
Maintainer: Your Name <you@example.com>
Build-Depends: debhelper (>= 10), make
Standards-Version: 4.4.0.1
Homepage: https://www.qubes-os.org

Package: qubes-skeleton
Architecture: all
Depends: ${misc:Depends}
Description: Qubes skeleton VM package
 Example component for Qubes OS.
```

**`debian/rules`** - the build and install script, typically a thin wrapper
around the Makefile:

```makefile
#!/usr/bin/make -f

export DESTDIR=$(shell pwd)/debian/tmp

%:
	dh $@

override_dh_auto_install:
	make install-vm
```

**`debian/changelog`** - version history in the standard Debian format. The
builder updates the version automatically so only an initial entry is needed:

```
qubes-skeleton (1.0.0-1) unstable; urgency=medium

  * Initial release.

 -- Your Name <you@example.com>  Thu, 01 Jan 2026 00:00:00 +0000
```

**`debian/compat`** - debhelper compatibility level (use `10` or higher):

```
10
```

**`debian/source/format`** - Debian source format:

```
3.0 (quilt)
```

**`debian/qubes-skeleton.install`** - lists files to include in the binary
package (paths relative to `DESTDIR`):

```
usr/lib/qubes/skeleton/skeleton.sh
usr/lib/qubes/skeleton/README
```

**`debian/copyright`** - license declaration in the machine-readable DEP-5
format:

```
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: qubes-skeleton
Source: https://www.qubes-os.org/

Files: *
Copyright: 2026 Your Name <you@example.com>
License: GPL-2+
 [license text...]
```

### `README.dom0` / `README.vm`

Plain-text files installed as `/usr/lib/qubes/skeleton/README` on the
relevant target. Replace these with whatever per-target documentation or
runtime instructions your component needs.

### `skeleton.sh`

The example payload. Replace or extend this with the scripts, binaries, or
configuration files your component provides.


## Example: adding a new file

Suppose you want to install a new script `toto.sh` into both dom0 and VMs
(RPM and Debian).

**1. Create the file in the repository.**

```bash
cat > toto.sh << 'EOF'
#!/bin/bash
echo "toto"
EOF
chmod +x toto.sh
```

**2. Add the install rule to `Makefile`.**

```makefile
install-common:
	install -m 775 -D skeleton.sh $(DESTDIR)/usr/lib/qubes/skeleton/skeleton.sh
	install -m 775 -D toto.sh   $(DESTDIR)/usr/lib/qubes/skeleton/toto.sh
```

**3. Add the path to the RPM spec files under `%files`.**

In `rpm_spec/skeleton-dom0.spec.in` and `rpm_spec/skeleton-vm.spec.in`:

```spec
%files
/usr/lib/qubes/skeleton/README
/usr/lib/qubes/skeleton/skeleton.sh
/usr/lib/qubes/skeleton/toto.sh
```

**4. Add the path to the Debian install file.**

In `debian/qubes-skeleton.install`:

```
usr/lib/qubes/skeleton/skeleton.sh
usr/lib/qubes/skeleton/README
usr/lib/qubes/skeleton/toto.sh
```

**5. Commit the changes.**

```bash
git add toto.sh Makefile rpm_spec/skeleton-dom0.spec.in rpm_spec/skeleton-vm.spec.in debian/qubes-skeleton.install
git commit -m "Add toto.sh"
```

That is all that is needed at the source level. The rest is handled by
qubes-builderv2.


## Local test build with qubes-builderv2

> **Prerequisites:** Follow the setup instructions in the
> [qubes-builderv2 README](https://github.com/QubesOS/qubes-builderv2/blob/main/README.md)
> first - install dependencies, fetch submodules, and configure your executor
> (Qubes disposable VM, Docker, or Podman).

### 1. Clone qubes-builderv2

```bash
git clone https://github.com/QubesOS/qubes-builderv2
cd qubes-builderv2
git submodule update --init
```

### 2. Create `builder.yml`

Start from the example config that matches your target release
(`example-configs/qubes-os-r4.3.yml`) and narrow it down to just skeleton.
Replace `/path/to/your/skeleton` with the absolute path to your local clone
of this repository.

```yaml
# builder.yml
git:
  baseurl: https://github.com
  prefix: fepitre/qubes-
  branch: master
  maintainers:
  # fepitre's @qubes-os.org
  - 9FA64B92F95E706BF28E2CA6484010B5CDC576E2
  # fepitre's @invisiblethingslab.com
  - 77EEEF6D0386962AEA8CF84A9B8273F80AC219E6

executor:
  type: qubes
  options:
    dispvm: qubes-builder-dvm   # your builder disposable template

distributions:
  - host-fc41      # adjust to the Fedora version your dom0 runs
  - vm-fc42        # add RPM distributions as needed
  - vm-bookworm    # add Debian distributions as needed

components:
  - skeleton:
      branch: master
      # Override the URL with a local path to test uncommitted changes:
      url: /path/to/your/git/skeleton
      # GPG fingerprint(s) used to verify signed tags for this component.
      # When omitted, the keys from the top-level git.maintainers list are used.
      # Setting this overrides those defaults for this component only.
      maintainers:
        - AABBCCDDEEFF00112233445566778899AABBCCDD

less-secure-signed-commits-sufficient:
  - skeleton

repository-publish:
  components: current-testing

stages:
  - fetch
  - prep
  - build
  - sign:
      executor:
        type: local
  - publish:
      executor:
        type: local
```

### 3. Run the build pipeline

Stages have declared dependencies that are resolved automatically:
`fetch` is always run by the CLI before anything else, and `build` has an
explicit job dependency on the `prep` artifact, so `get_jobs` pulls `prep`
in automatically. In practice, calling `build` is sufficient for a full
run from scratch:

```bash
./qb -c skeleton package build
```

You can also list stages explicitly if you only want to run up to a certain
point:

```bash
./qb -c skeleton package fetch
./qb -c skeleton package prep
./qb -c skeleton package build
```

Once the build succeeds, optionally sign and publish:

```bash
# Sign - requires a GPG key configured in builder.yml
./qb -c skeleton package sign

# Publish to the local repository tree
./qb -c skeleton package publish
```

Each stage is tracked via YAML artifact files under `artifacts/`. A stage is
skipped if its artifact already exists. To force sources to be re-fetched, `fetch` 
must be explicitly listed in the stage, otherwise the
implicit fetch run skips the git pull:

```bash
./qb -c skeleton package fetch build
```

To re-run build stages, delete the relevant artifact file under
`artifacts/components/skeleton/`.

### 4. Inspect the built packages

Artifacts are laid out as described in the qubes-builderv2 README:

```bash
# Built RPMs
find artifacts/components/skeleton -name '*.rpm'

# Built .deb packages
find artifacts/components/skeleton -name '*.deb'

# Published repository tree
ls artifacts/repository-publish/
```

### 5. Install and verify

#### dom0

> **Warning:** dom0 is the most privileged and trusted component of Qubes OS.
> Installing packages in dom0 that have not been signed and verified through
> the official Qubes OS repository process is a security risk. Only do this
> with packages you built yourself from source you fully trust, on a machine
> you are comfortable treating as potentially compromised. **Proceed at your
> own risk.**

dom0 is isolated and cannot pull files directly from the builder qube. Copy
the built RPM from the builder qube (`work-qubesos`) to dom0 using
`qvm-run --pass-io`, then install it:

```bash
# Run in dom0
qvm-run --pass-io work-qubesos \
    'cat ~/qubes-builderv2/artifacts/components/skeleton/*/host-fc41/build/rpm/qubes-skeleton-dom0-*.rpm' \
    | sudo tee /tmp/qubes-skeleton-dom0.rpm > /dev/null

sudo rpm -ivh /tmp/qubes-skeleton-dom0.rpm

# Verify
/usr/lib/qubes/skeleton/skeleton.sh
/usr/lib/qubes/skeleton/toto.sh
cat /usr/lib/qubes/skeleton/README
```

#### VM distributions (RPM and Debian)

To test without modifying a template, install into either a freshly
started disposable VM based on the target template, or a dedicated testing
AppVM. Start the VM first, then copy the package to it with `qvm-copy-to-vm`
from the builder qube and install inside it.

**RPM-based (e.g. fedora-42):**

```bash
# Start a fresh dispvm based on fedora-42 or use a dedicated testing AppVM
# (replace 'test-fedora-42' with the actual running VM name)
qvm-copy-to-vm test-fedora-42 \
    ~/qubes-builderv2/artifacts/components/skeleton/*/vm-fc42/build/rpm/qubes-skeleton-vm-*.rpm

# Inside the VM
sudo rpm -ivh ~/QubesIncoming/work-qubesos/qubes-skeleton-vm-*.rpm
/usr/lib/qubes/skeleton/skeleton.sh
/usr/lib/qubes/skeleton/toto.sh
cat /usr/lib/qubes/skeleton/README
```

**Debian-based (e.g. bookworm):**

```bash
# Start a fresh dispvm based on debian-12 or use a dedicated testing AppVM
qvm-copy-to-vm test-bookworm \
    ~/qubes-builderv2/artifacts/components/skeleton/*/vm-bookworm/build/deb/qubes-skeleton_*.deb

# Inside the VM
sudo dpkg -i ~/QubesIncoming/work-qubesos/qubes-skeleton_*.deb
/usr/lib/qubes/skeleton/skeleton.sh
/usr/lib/qubes/skeleton/toto.sh
cat /usr/lib/qubes/skeleton/README
```
