
WORK=work

all: deb-package

clean:
	find . -name '*~' -delete
	if [ -d "$(WORK)" ] ; then rm -rf "$(WORK)" ; fi

_install:
	if [ -n "$(PREFIX)" ] && [ ! -d "$(PREFIX)" ] ; then mkdir -p "$(PREFIX)" ; fi
	if [ -n "$(PREFIX)" ] && [ ! -d "$(PREFIX)/DEBIAN" ] ; then mkdir -p "$(PREFIX)/DEBIAN" ; fi
	if [ -n "$(PREFIX)" ] ; then cp control "$(PREFIX)/DEBIAN" ; fi 
	if [ -n "$(PREFIX)" ] ; then install postinst "$(PREFIX)/DEBIAN" ; fi

	if [ ! -d "$(PREFIX)/lib/systemd/system/" ] ; then mkdir -p "$(PREFIX)/lib/systemd/system/" ; fi 
	cp ifupdown-wait-all-network.service "$(PREFIX)/lib/systemd/system/"
	if [ ! -d "$(PREFIX)/usr/lib/ifupdown" ] ; then mkdir -p "$(PREFIX)/usr/lib/ifupdown" ; fi 
	install ifupdown-wait-all-online.sh "$(PREFIX)/usr/lib/ifupdown"

deb-package:
	PREFIX=$(WORK) make _install
	fakeroot dpkg-deb --build $(WORK) .
