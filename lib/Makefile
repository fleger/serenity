SUBDIRS=backends
LIBS=serenity.sh tools.sh
SOURCES=$(LIBS) Makefile

.PHONY: all, install, clean, uninstall, archive

all:
	for i in $(SUBDIRS); do cd $$i; $(MAKE) $@; done

install:
	$(INSTALL) $(INSTALLDIRFLAGS) "$(DESTDIR)$(LIBDIR)"
	$(INSTALL) $(INSTALLFLAGS) -t "$(DESTDIR)$(LIBDIR)" $(LIBS)
	for i in $(SUBDIRS); do cd $$i; $(MAKE) $@; done
	
clean: ;

uninstall:
	-for i in $(SUBDIRS); do cd $$i; $(MAKE) $@; done
	-for i in $(LIBS); do $(RM) "$(DESTDIR)$(LIBDIR)"/$$i; done
	-$(RMDIR) "$(DESTDIR)$(LIBDIR)"

archive:
	$(INSTALL) $(INSTALLDIRFLAGS) "$(TARDIR)"
	$(INSTALL) $(INSTALLFLAGS) -t "$(TARDIR)" $(SOURCES)
	for i in $(SUBDIRS); do cd $$i; $(MAKE) "TARDIR=$(TARDIR)/$$i" $@; done