#! /usr/bin/python
# -*- coding: utf-8 -*-

import json
import requests
import commands

from google_scholar_bibliography import *
from bs4 import BeautifulSoup

def get_citedby(cluster_id):
    '''
    Cluster_idを受け取り，その論文に引用されている論文のcluster_idを返す

    FIXME:
    書誌情報そのものが取ってこれなかったり，被引用論文のタイトル検索がうまく行かなかったりするみたい
    ネットワーク関係の何か？(API制限とか)
    printを挟んで処理を遅延させるとうまくいく(？)
    '''
    art = get_bibliography(cluster_id) # 書誌情報を返す

    citedbyes = [] # 被引用論文のcluster_id
    if art["url_citations"][0] is not None:
        html = requests.get(art["url_citations"][0]).text
        #print html
        soup = BeautifulSoup(html)
        soup_titles = soup.find_all("h3", "gs_rt")
        for soup_title in soup_titles:
            # 各被引用論文について，タイトルで検索した時の上位1件のcluster_idを取得
            citedby_title = soup_title.a.get_text() if soup_title.a else ''
            #print citedby_title
            # citedby_cmd = os.path.dirname(sys.argv[0]) + "/scholarpy/scholar.py -c 1 -t --csv --phrase " # CSV形式で検索
            # citedby_cmd += '"' + citedby_title + '"' 
            # csv = commands.getoutput(citedby_cmd)
            # #print csv
            # citedby_cid = csv.split('|')[5] if len(csv.split('|')) >= 6 else None  # 6番目がcluster_id

            querier = ScholarQuerierWithSnippets()
            settings = ScholarSettings()
            querier.apply_settings(settings)
            query = SearchScholarQuery()
            query.set_words(citedby_title.encode('utf-8'))
            query.set_scope(True)
            query.set_num_page_results(1) # 返す検索結果は1件
            querier.send_query(query)
            result = put_json(querier)
            citedby_cid = result["cluster_id"][0]

            if citedby_cid is not None:
                citedbyes.append(citedby_cid)

    return citedbyes

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] != '':
        print json.dumps(get_citedby(sys.argv[1].strip()))