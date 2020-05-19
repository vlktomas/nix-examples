# documentation name
DOCUMENTATION_NAME=project

# package name
PACKAGE_NAME=project

# other programs
RM=rm -f
TAR=tar
ZIP=zip


.PHONY: clean run

all: build

build:
	vlna -l -v KkSsVvZzOoUuAaIi *.tex
	#pdflatex $(DOCUMENTATION_NAME)
	#bibtex $(DOCUMENTATION_NAME)
	#pdflatex $(DOCUMENTATION_NAME)
	#pdflatex $(DOCUMENTATION_NAME)
	latexmk -pdf -f -g

run: build
	evince $(DOCUMENTATION_NAME).pdf

pack: build
	# for discard directory structure add --junk-paths to zip and --xform 's#^.+/##x' to tar
	$(ZIP) -r $(PACKAGE_NAME).zip $(DOCUMENTATION_NAME).pdf --exclude "*/.*"
	$(TAR) -cf $(PACKAGE_NAME).tar $(DOCUMENTATION_NAME).pdf --exclude "*/.*"

clean:
	rm -f $(DOCUMENTATION_NAME).dvi
	rm -f $(DOCUMENTATION_NAME).ps
	rm -f $(DOCUMENTATION_NAME).aux
	rm -f $(DOCUMENTATION_NAME).log
	rm -f $(DOCUMENTATION_NAME).out
	rm -f $(DOCUMENTATION_NAME).blg
	rm -f $(DOCUMENTATION_NAME).bbl
	rm -f $(DOCUMENTATION_NAME).te~
	rm -f $(DOCUMENTATION_NAME).fdb_latexmk
	rm -f .$(DOCUMENTATION_NAME).tex.swp
	rm -f $(PACKAGE_NAME)
	rm -f *.fls

