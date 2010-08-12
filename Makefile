DESTDIR=
PREFIX=/usr/local
CONFDIR=/etc
BINDIR=$(PREFIX)/bin
LIBDIR=$(PREFIX)/lib/serenity


override DESTDIR:=$(abspath $(DESTDIR))


SED=/bin/sed
INSTALL=/bin/install
RM=/bin/rm
RMDIR=/bin/rmdir
TAR=/bin/tar
INSTALLBINFLAGS=-D -m755
INSTALLDIRFLAGS=-d
INSTALLFLAGS=-D -m644

NAME=serenity
VERSION=0.2.0

TARDIR=$(NAME)-$(VERSION)
override TARDIR:=$(abspath $(TARDIR))
TARFORMAT=.xz
TARNAME=$(NAME)-$(VERSION).tar$(TARFORMAT)
TARFLAGS=-acf

SUBDIRS=lib
BINS=serenity
CONFS=serenity.conf
SOURCES=serenity.in serenity-devel README INSTALL Makefile $(CONFS)

SUBMAKEFLAGS='DESTDIR=$(DESTDIR)' 'PREFIX=$(PREFIX)' 'CONFDIR=$(CONFDIR)' 'BINDIR=$(BINDIR)' 'LIBDIR=$(LIBDIR)' 'SED=$(SED)' 'INSTALL=$(INSTALL)' 'RM=$(RM)' 'RMDIR=$(RMDIR)' 'INSTALLBINFLAGS=$(INSTALLBINFLAGS)' 'INSTALLFLAGS=$(INSTALLFLAGS)' 'INSTALLDIRFLAGS=$(INSTALLDIRFLAGS)' 'NAME=$(NAME)' 'VERSION=$(VERSION)'

.PHONY: all, install, clean, uninstall, really-clean, archive

all: $(BINS)
	for i in $(SUBDIRS); do cd $$i; $(MAKE) $(SUBMAKEFLAGS) $@; done

serenity: serenity.in
	$(SED) -e "s/%LIBDIR%/$(subst /,\/,$(LIBDIR))/g" -e "s/%CONFDIR%/$(subst /,\/,$(CONFDIR))/g" $? > $@

install: all
	$(INSTALL) $(INSTALLDIRFLAGS) "$(DESTDIR)$(PREFIX)"
	$(INSTALL) $(INSTALLDIRFLAGS) "$(DESTDIR)$(BINDIR)"
	$(INSTALL) $(INSTALLDIRFLAGS) "$(DESTDIR)$(CONFDIR)"
	$(INSTALL) $(INSTALLBINFLAGS) -t "$(DESTDIR)$(BINDIR)" $(BINS)
	$(INSTALL) $(INSTALLFLAGS) -t "$(DESTDIR)$(CONFDIR)" $(CONFS)
	for i in $(SUBDIRS); do cd $$i; $(MAKE) $(SUBMAKEFLAGS) $@; done

clean:
	-$(RM) $(BINS)
	-$(RM) $(TARNAME)
	-for i in $(SUBDIRS); do cd $$i; $(MAKE) $(SUBMAKEFLAGS) $@; done

uninstall:
	-for i in $(SUBDIRS); do cd $$i; $(MAKE) $(SUBMAKEFLAGS) $@; done
	-for i in $(BINS); do $(RM) "$(DESTDIR)$(BINDIR)"/$$i; done
	-for i in $(CONFS); do $(RM) "$(DESTDIR)$(CONFDIR)"/$$i; done
	-$(RMDIR) "$(DESTDIR)$(CONFDIR)"
	-$(RMDIR) "$(DESTDIR)$(BINDIR)"

really-clean: clean uninstall

archive:
	$(INSTALL) $(INSTALLDIRFLAGS) "$(TARDIR)"
	$(INSTALL) $(INSTALLFLAGS) -t "$(TARDIR)" $(SOURCES)
	for i in $(SUBDIRS); do cd $$i; $(MAKE) $(SUBMAKEFLAGS) "TARDIR=$(TARDIR)/$$i" $@; done
	$(TAR) $(TARFLAGS) $(TARNAME) $(TARDIR)
	$(RM) -r $(TARDIR)
