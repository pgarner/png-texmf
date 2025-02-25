#!/bin/zsh

html=$HOME/Documents/github.io/_pubs

# Use a relative css path so it works independent of baseurl
opts=(
    -css assets/stylish.css
    -r
    -d
)

cat png-strs.bib png-pubs.bib \
    | bibtex2html $opts -t "Philip N. Garner: Publications" \
                  -o png-pubs
            
cat png-strs.bib png-pats.bib \
    | bibtex2html $opts -t "Philip N. Garner: Patents and published applications" \
                  -o png-pats

cat png-strs.bib png-tech.bib \
    | bibtex2html $opts -t "Philip N. Garner: Technical reports" \
                  -o png-tech

echo Copying to $html
cp *.html $html
