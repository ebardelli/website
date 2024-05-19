#HUGO := docker run --rm -v $(current_dir):/src klakegg/hugo:ext-alpine 
HUGO := hugo
#ACADEMIC := docker run --rm -v $(current_dir):/hugo ebardelli/hugo-academic:latest 
ACADEMIC := pipenv run academic

current_dir:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY=build
build:
	$(HUGO) --gc --minify --cleanDestinationDir

.PHONY=deploy
deploy:
	rsync -azP --delete public/* bardelli@sftp.itd.umich.edu:~/Public/html

.PHONY=theme
theme:
	$(HUGO) mod clean
	$(HUGO) mod get -u ./...
	$(HUGO) mod tidy

.PHONY=server
serve:
	$(HUGO) serve --bind "0.0.0.0"

.PHONY=publications
publications:
	rm -rf content/publication/*/*.md; \
	$(ACADEMIC) import --bibtex bibtex/publications.bib --overwrite --normalize content/publication; \
	tmpfile=$(mktemp /tmp/publications.XXXXXX); \
	sed 's/  keywords = {My Work\/Papers}.*$$//' bibtex/working-papers.bib | sed 's/  file =.*$$//' | sed 's/techreport/unpublished/' > "$tmpfile";\
	$(ACADEMIC) import --bibtex "$tmpfile" --overwrite --normalize content/publication; \
	rm "$tmpfile"
	#$(ACADEMIC) import --bibtex bibtex/talks.bib --overwrite --publication-dir=content/event --normalize
