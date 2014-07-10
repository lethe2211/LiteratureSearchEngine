#!/bin/sh

curl -o ./tmp.pdf $1 >/dev/null 2>&1
# if [ $? -gt 0 ]; then
#     exit 1
# fi

pdftotext ./tmp.pdf ./tmp.cite
if [ $? -gt 0 ]; then
    exit 1
fi

#~/ParsCit/bin/citeExtract.pl ./tmp.cite
#cd `dirname $0`
parscit=$(cd $(dirname $0) && pwd)/crawler/ParsCit/bin/citeExtract.pl
$parscit ./tmp.cite
#~/Dropbox/rails/search/lib/crawler/ParsCit/bin/citeExtract.pl ./tmp.cite
if [ $? -gt 0 ]; then
    # rm ./tmp.cite
    # rm ./tmp.body
    exit 1
fi
