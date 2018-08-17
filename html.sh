#!/bin/zsh

html=$HOME/doc/github.io/_pubs

# Use a relative css path so it work independent of baseurl
opts=(
    -css assets/stylish.css
    -r
    -d
)

bibtex2html $opts -t "Philip N. Garner: Publications" \
            png-pubs.bib
bibtex2html $opts -t "Philip N. Garner: Patents and published applications" \
            png-pats.bib
bibtex2html $opts -t "Philip N. Garner: Technical reports" \
            png-tech.bib
bibtex2html $opts -t "Philip N. Garner: In preparation" \
            png-prep.bib

echo Copying to $html
cp *.html $html
