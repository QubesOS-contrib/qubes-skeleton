install-common:
	install -m 775 -D skeleton.sh $(DESTDIR)/usr/lib/qubes/skeleton/skeleton.sh

install-dom0: install-common
	install -m 664 -D README.dom0 $(DESTDIR)/usr/lib/qubes/skeleton/README

install-vm: install-common
	install -m 664 -D README.vm $(DESTDIR)/usr/lib/qubes/skeleton/README

clean:
	rm -rf pkgs