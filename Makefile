#!/usr/bin/make -f

all:
	@./install.sh $(DESTDIR)

install: all
	$(info Installation complete.)

