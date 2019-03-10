# Makefile for libstatgrab/docs/saidar
# https://libstatgrab.org/

if MANPAGES
if SAIDAR
man_MANS = saidar.1
endif

EXTRA_DIST = $(man_MANS)
endif

if BUILD_MANPAGES
MAINTAINERCLEANFILES= $(man_MANS)

.xml.1:
	$(DOCBOOK2MAN) -N --solinks --string-param \
		header-3="`git log -1 --format='%ad' --date=short $<`" \
		$<

html-manpages: saidar.1.html

SUFFIXES = .xml .1.html
.xml.1.html:
	xsltproc /usr/share/xml/docbook/stylesheet/docbook-xsl/html/docbook.xsl $< | sed 's/charset=ISO-8859-1/charset=UTF-8/' | iconv --from-code=iso-8859-1 --to-code=utf-8 > $@
endif
