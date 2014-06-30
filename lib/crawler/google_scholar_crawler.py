#! /usr/bin/python
# -*- coding: utf-8 -*-

import json

from google_scholar_base import *
from google_scholar_search_pdf import *
import filecache

from bs4 import BeautifulSoup

def put_json(querier):
    '''
    JSONを出力
    '''
    articles_json = []
    articles = querier.articles
    for art in articles:
        art_json = art.as_json()

        # PDFへの直リンクは引用論文取得のために必要であるため，取得できていない場合は論文詳細ページから取得
        if art_json['url_pdf'][0] is None:
            art_json['url_pdf'][0] = search_pdf(art_json['cluster_id'][0])

        articles_json.append(art_json)
        
    return articles_json

def crawl(input_query):
    abspath = os.path.dirname(os.path.abspath(__file__))
    serp = filecache.Client(abspath + '/serp/')

    cache = serp.get(input_query) # キャッシュ機構
    if cache != None:
        return cache
    else:
        querier = ScholarQuerierWithSnippets()
        settings = ScholarSettings()
        querier.apply_settings(settings)
        query = SearchScholarQuery()
        query.set_words(input_query)
        querier.send_query(query)
        result = put_json(querier)

        serp.set(input_query, result)

        return result



if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] != '':
        print json.dumps(crawl(sys.argv[1].strip()))
