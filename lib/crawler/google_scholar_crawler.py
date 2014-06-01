#! /usr/bin/python
# -*- coding: utf-8 -*-

import json

from google_scholar_base import *
from bs4 import BeautifulSoup


def put_json(querier):
    '''
    JSONを出力
    '''
    articles_json = []
    articles = querier.articles
    for art in articles:
        art_json = art.as_json()


        articles_json.append(art_json)
        
    return articles_json

def crawl(input_query):
    querier = ScholarQuerierWithSnippets()
    settings = ScholarSettings()
    querier.apply_settings(settings)
    query = SearchScholarQuery()
    query.set_words(input_query)
    querier.send_query(query)
    return put_json(querier)

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] != '':
        print json.dumps(crawl(sys.argv[1].strip()))
