#!/usr/bin/make -f

INSTALL = install
CONFDIR = $(DESTDIR)/etc/perun/${CONF}.d
BINDIR = $(DESTDIR)/opt/perun/bin
LIBDIR = $(DESTDIR)/opt/perun/lib

build: ;

install:
	$(INSTALL) -d -m 755 $(BINDIR)
	$(INSTALL) ./bin/* $(BINDIR)
