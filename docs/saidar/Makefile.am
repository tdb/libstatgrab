# Makefile for libstatgrab/docs/saidar
# http://www.i-scream.org/libstatgrab/
# $Id$

if SAIDAR
man_MANS = saidar.1
endif

EXTRA_DIST = $(man_MANS)

if BUILD_MANPAGES
CLEANFILES= $(man_MANS)

.xml.1:
	DATE=`git log -1 --format="%ad" --date=short $<` \
		$(DOCBOOK2MAN) -N --symlinks \
		--string-param header-3="$$DATE" $<
endif
