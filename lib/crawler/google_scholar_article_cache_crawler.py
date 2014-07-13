#! /usr/bin/python
# -*- coding: utf-8 -*-

import sys
import time
import logging

from google_scholar_article_crawler import GoogleScholarArticleCrawler

class GoogleScholarArticleCacheCrawler(object):

    def __init__(self):
        pass

    def crawl(self, cluster_id, depth=10):
        logging.debug('cluster id : ' + str(cluster_id))
        g = GoogleScholarArticleCrawler()
        g.get_bibliography(cluster_id)
        citation = g.get_citation(cluster_id)
        citedby = g.get_citedby(cluster_id)

        if depth == 0:
            return
        else:
            for c in citation:
                self.crawl(c, depth - 1)
                time.sleep(3)

            if citation == []:
                for c in citedby:
                    self.crawl(c, depth - 1)
                    time.sleep(3)

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)

    if len(sys.argv) == 2:
        g = GoogleScholarArticleCacheCrawler()
        print g.crawl(sys.argv[1], depth=1)
