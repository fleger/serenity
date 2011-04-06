#    serenity - An automated episode renamer.
#    Copyright (C) 2010-2011  Florian Léger
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

SUBDIRS=backends
LIBS=$(wildcard *.sh)
SOURCES=$(LIBS) Makefile

.PHONY: all, install, clean, uninstall, archive

all:
	for i in $(SUBDIRS); do cd $$i; $(MAKE) $@; cd -; done

install:
	$(INSTALL) $(INSTALLDIRFLAGS) "$(DESTDIR)$(LIBDIR)"
	$(INSTALL) $(INSTALLFLAGS) -t "$(DESTDIR)$(LIBDIR)" $(LIBS)
	for i in $(SUBDIRS); do cd $$i; $(MAKE) $@; cd -; done
	
clean: ;

uninstall:
	-for i in $(SUBDIRS); do cd $$i; $(MAKE) $@; cd -; done
	-for i in $(LIBS); do $(RM) "$(DESTDIR)$(LIBDIR)"/$$i; done
	-$(RMDIR) "$(DESTDIR)$(LIBDIR)"

archive:
	$(INSTALL) $(INSTALLDIRFLAGS) "$(TARDIR)"
	$(INSTALL) $(INSTALLFLAGS) -t "$(TARDIR)" $(SOURCES)
	for i in $(SUBDIRS); do cd $$i; $(MAKE) "TARDIR=$(TARDIR)/$$i" $@; cd -; done