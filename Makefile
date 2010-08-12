#    serenity - An automated episode renamer.
#    Copyright (C) 2010  Florian Léger
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
SOURCES=serenity.in serenity-devel README INSTALL COPYING Makefile $(CONFS)

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
