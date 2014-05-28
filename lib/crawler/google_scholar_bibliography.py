#! /usr/bin/python
# -*- coding: utf-8 -*-

import json
from google_scholar_base import *

def put_json(querier):
    '''
    JSONを出力
    '''
    articles = querier.articles[0].as_json()

    return articles

def get_bibliography(cluster_id):
    '''
    Cluster_idを受け取り，書誌情報を返す
    '''
    querier = ScholarQuerierWithSnippets()
    settings = ScholarSettings()
    querier.apply_settings(settings)
    query = ClusterScholarQuery(cluster=cluster_id)
    query.set_num_page_results(1) # 返す検索結果は1件
    querier.send_query(query)
    return put_json(querier)

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] != '':
        print json.dumps(get_bibliography(sys.argv[1].strip()))