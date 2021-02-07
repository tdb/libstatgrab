#!/bin/sh

for i in "$@"; do
	if [ ! -f "$i" ]; then
		echo "Can't find $i"
		exit 1
	fi

	if [ ! -f $i.adoc ]; then
		echo "= \c" > $i.adoc
		xmllint --xpath '/refentry/refmeta/refentrytitle/text()' $i >> $i.adoc
		echo "(\c" >> $i.adoc
		xmllint --xpath '/refentry/refmeta/manvolnum/text()' $i >> $i.adoc
		echo ")" >> $i.adoc
		echo ":doctype: manpage" >> $i.adoc
		echo ":manmanual: libstatgrab" >> $i.adoc
		echo ":mansource: libstatgrab" >> $i.adoc
		echo >> $i.adoc
		docbook2x-man -N --no-links --string-param header-3="`git log -1 --format='%ad' --date=short $i`" --to-stdout $i | pandoc -f man -t asciidoctor >> $i.adoc
	fi

	docbook2x-man -N --no-links --string-param header-3="`git log -1 --format='%ad' --date=short $i`" --to-stdout $i | man -l - | col -b > $i.original
	/home/cur/tdb/.gem/ruby/2.5.0/bin/asciidoctor -a docdate="`git log -1 --format='%ad' --date=short $i`" -b manpage -o - $i.adoc | man -l - | col -b > $i.new

	diff -u $i.original $i.new
done
