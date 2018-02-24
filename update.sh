#!/bin/sh
#
# Copy this to a shared LaTeX project; run it to update bib files
#
for f in pubs refs
do
    cp ~/texmf/png-texmf/png-$f.bib .
done
