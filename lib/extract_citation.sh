#!/usr/local/bin/zsh
pdftotext $1 ./tmp.cite
~/parscit/bin/citeExtract.pl ./tmp.cite
#rm ./tmp.cite
#rm ./tmp.body
