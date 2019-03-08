#!/bin/sh

XSL="/usr/share/xml/docbook/stylesheet/docbook-xsl/html/docbook.xsl"

for i in saidar/*.xml statgrab/*.xml; do
	BASE=`echo $i | sed 's/\.xml$//'`
	xsltproc $XSL $i | sed 's/charset=ISO-8859-1/charset=UTF-8/' | iconv --from-code=iso-8859-1 --to-code=utf-8 > $BASE.1.html
done

for i in libstatgrab/*.xml; do
	BASE=`echo $i | sed 's/\.xml$//'`
	xsltproc $XSL $i | sed 's/charset=ISO-8859-1/charset=UTF-8/' | iconv --from-code=iso-8859-1 --to-code=utf-8 > $BASE.3.html
done
