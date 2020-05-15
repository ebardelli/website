#!/bin/sh

rm -rf content/publication/*

tmpfile=$(mktemp /tmp/publications.XXXXXX)

sed 's/  keywords = {My Work\/Papers}.*$//' publications.bib |
sed 's/  file =.*$//' |
sed 's/techreport/unpublished/' > "$tmpfile"

academic import --bibtex "$tmpfile" --overwrite --publication-dir=publication --normalize

rm "$tmpfile"
