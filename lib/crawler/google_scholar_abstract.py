#! /usr/bin/python
# -*- coding: utf-8 -*-

import sys
import logging
import json

from google_scholar_article_crawler import GoogleScholarArticleCrawler

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)

    if len(sys.argv) == 2 and sys.argv[1] != '':
        g = GoogleScholarArticleCrawler()
        abstract = g.get_abstract(sys.argv[1])
        print abstract.encode('utf-8')

    

