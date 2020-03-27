#!/bin/sh

tmpfile=$(mktemp /tmp/publications.XXXXXX)

sed 's/  keywords = {My Work\/Papers}.*$//' publications.bib |
sed 's/  file =.*$//' > "$tmpfile"

academic import --bibtex "$tmpfile" --overwrite --publication-dir=publication

rm "$tmpfile"
