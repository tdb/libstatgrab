# Makefile for libstatgrab/docs
# https://libstatgrab.org/

SUBDIRS = libstatgrab statgrab saidar

html-manpages:
	for d in $(SUBDIRS); do $(MAKE) -C $$d html-manpages; done
