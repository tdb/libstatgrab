#!/bin/sh

XSL="/usr/local/share/xsl/docbook/xhtml-1_1/docbook.xsl"

for i in saidar/*.xml statgrab/*.xml; do
	BASE=`echo $i | sed 's/\.xml$//'`
	xsltproc $XSL $i | sed -e 's/<meta name/<meta http-equiv=\"Content-Type\" content=\"text\/html; charset=utf-8\"\/><meta name/g' > $BASE.1.html
done

for i in libstatgrab/*.xml; do
	BASE=`echo $i | sed 's/\.xml$//'`
	xsltproc $XSL $i | sed -e 's/<meta name/<meta http-equiv=\"Content-Type\" content=\"text\/html; charset=utf-8\"\/><meta name/g' > $BASE.3.html
done
