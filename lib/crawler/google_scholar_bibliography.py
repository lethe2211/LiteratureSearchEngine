#! /usr/bin/python
# -*- coding: utf-8 -*-

import json
import logging

from google_scholar_base import *
import filecache

def put_json(querier):
    '''
    JSONを出力
    '''
    articles = {
            'title':         [None, 'Title',          0], # 論文タイトル
            'url':           [None, 'URL',            1], # 検索結果URL
            'year':          [None, 'Year',           2], # 発行年
            'num_citations': [0,    'Citations',      3], # 被引用数
            'num_versions':  [0,    'Versions',       4], # 同一判定された論文のバージョン数
            'cluster_id':    [None, 'Cluster ID',     5], # クラスタID
            'url_pdf':       [None, 'PDF link',       6], # 論文PDFへのリンク(SERPからの直接リンクでなければ取得できない)
            'url_citations': [None, 'Citations list', 7], # 被引用論文のリストへのリンク
            'url_versions':  [None, 'Versions list',  8], # 同一判定された論文の各バージョンのリストへのリンク
            'url_citation':  [None, 'Citation link',  9], # よくわからない...
            'snippet':       [None, 'Snippet',       10], # スニペット(新たに追加)
            'authors':       [[],   'Authors',       11] # 著者(新たに追加)
    }

    if len(querier.articles) > 0:
        articles = querier.articles[0].as_json() 

    return articles

def get_bibliography(cluster_id):
    '''
    Cluster_idを受け取り，書誌情報を返す
    '''
    abspath = os.path.dirname(os.path.abspath(sys.argv[0]))
    bibliography = filecache.Client(abspath + '/bibliography/')

    cache = bibliography.get(str(cluster_id)) # キャッシュ機構
    if cache != None:
        return cache
    else:
        querier = ScholarQuerierWithSnippets()
        settings = ScholarSettings()
        querier.apply_settings(settings)
        query = ClusterScholarQuery(cluster=cluster_id)
        query.set_num_page_results(1) # 返す検索結果は1件
        querier.send_query(query)
        result = put_json(querier)

        bibliography.set(str(cluster_id), result)

        return result

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)

    if len(sys.argv) == 2 and sys.argv[1] != '':
        result = json.dumps(get_bibliography(sys.argv[1].strip()))
        logging.debug(result)
        print result