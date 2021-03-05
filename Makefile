current_dir:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY=all
all: theme build

.PHONY=build
build:
	docker run --rm -v $(current_dir):/src peaceiris/hugo:v0.81.0-mod --gc --minify --cleanDestinationDir

.PHONY=theme
theme:
	docker run --rm -v $(current_dir):/src peaceiris/hugo:v0.81.0-mod mod get -u
	docker run --rm -v $(current_dir):/src peaceiris/hugo:v0.81.0-mod mod clean

.PHONY=publications
publications:
	rm -rf content/publication/*; \
	docker run --rm -v $(current_dir):/hugo ebardelli/hugo-academic:latest import --bibtex publications.bib --overwrite --publication-dir=publication --normalize; \
	rm -rf content/working-paper/*; \
	tmpfile=$(mktemp /tmp/publications.XXXXXX); \
	sed 's/  keywords = {My Work\/Papers}.*$$//' working-papers.bib | sed 's/  file =.*$$//' | sed 's/techreport/unpublished/' > "$tmpfile";\
	docker run --rm -v $(current_dir):/hugo ebardelli/hugo-academic:latest import --bibtex "$tmpfile" --overwrite --publication-dir=working-paper --normalize; \
	rm "$tmpfile"

