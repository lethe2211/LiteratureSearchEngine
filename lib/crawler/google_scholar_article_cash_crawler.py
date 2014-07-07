#! /usr/bin/python
# -*- coding: utf-8 -*-

from google_scholar_article_crawler import GoogleScholarArticleCrawler

class GoogleScholarArticleCashCrawler(object):

    def __init__(self):
        pass

    def crawl(self, cluster_id, depth=100):
        g = GoogleScholarArticleCrawler()
        g.get_bibliography(cluster_id)
        citation = g.get_citation(cluster_id)
        citedby = g.get_citedby(cluster_id)

        for c in citation:
            self.crawl(c, depth - 1)

        if citation == []:
            for c in citedby:
                self.crawl(c, depth - 1)
