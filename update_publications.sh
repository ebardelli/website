#!/bin/sh

# Published papers
rm -rf content/publication/*

academic import --bibtex publications.bib --overwrite --publication-dir=publication --normalize

# Working papers
rm -rf content/working-paper/*

tmpfile=$(mktemp /tmp/publications.XXXXXX)

sed 's/  keywords = {My Work\/Papers}.*$//' working-papers.bib |
sed 's/  file =.*$//' |
sed 's/techreport/unpublished/' > "$tmpfile"

academic import --bibtex "$tmpfile" --overwrite --publication-dir=working-paper --normalize

rm "$tmpfile"

