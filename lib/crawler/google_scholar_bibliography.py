#! /usr/bin/python
# -*- coding: utf-8 -*-

import sys
import json
import logging

from google_scholar_article_crawler import GoogleScholarArticleCrawler

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)

    if len(sys.argv) == 2 and sys.argv[1] != '':
        g = GoogleScholarArticleCrawler()
        bib = g.get_bibliography(sys.argv[1])
        print json.dumps(bib)