BACKENDSDIR=$(LIBDIR)/backends
BACKENDS=tvrage.sh
SOURCES=$(BACKENDS) Makefile

.PHONY: all, install, clean, uninstall, archive

all: ;

install:
	$(INSTALL) $(INSTALLDIRFLAGS) "$(DESTDIR)$(BACKENDSDIR)"
	$(INSTALL) $(INSTALLFLAGS) -t "$(DESTDIR)$(BACKENDSDIR)" $(BACKENDS)

clean: ;

uninstall:
	-for i in $(BACKENDS); do $(RM) "$(DESTDIR)$(BACKENDSDIR)"/$$i; done
	-$(RMDIR) "$(DESTDIR)$(BACKENDSDIR)"

archive:
	$(INSTALL) $(INSTALLDIRFLAGS) "$(TARDIR)"
	$(INSTALL) $(INSTALLFLAGS) -t "$(TARDIR)" $(SOURCES)