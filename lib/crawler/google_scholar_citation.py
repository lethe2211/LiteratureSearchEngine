#! /usr/bin/python
# -*- coding: utf-8 -*-

import commands

from google_scholar_bibliography import *
from bs4 import BeautifulSoup

def get_citation(cluster_id):
    '''
    Cluster_idを受け取り，その論文が引用している論文のcluster_idを返す

    FIXME:
    BeautifulSoupがうまく読み込めていないみたい
    '''
    art = get_bibliography(cluster_id) # 書誌情報を返す

    citations = [] # 引用論文のcluster_id
    if art["url_pdf"][0] != None:
        # ParsCitによる引用情報の取得
        cmd = os.path.dirname(os.path.abspath(__file__)) + "/../extract_citations.sh " + art["url_pdf"][0]
        xml = commands.getoutput(cmd)
        soup = BeautifulSoup(xml, "html.parser")

        if len(soup.find_all("citation")) > 0:
            for citation_soup in soup.find_all("citation"):
                # 各引用論文について，タイトルで検索した時の上位1件のcluster_idを取得
                citation_title = citation_soup.title.string if citation_soup.title else ''
                #print citation_title
                # ここでbs4が読み込めてない
                # citation_cmd = os.path.dirname(__file__) + "/scholarpy/scholar.py -c 1 -t --csv --phrase " # CSV形式で検索
                # citation_cmd += '"' + citation_title.encode('utf-8') + '"' 
                # csv = commands.getoutput(citation_cmd)
                # #print csv

                # citation_cid = csv.split('|')[5] if len(csv.split('|')) >= 6 else None  # 6番目がcluster_id

                querier = ScholarQuerierWithSnippets()
                settings = ScholarSettings()
                querier.apply_settings(settings)
                query = SearchScholarQuery()
                query.set_words(citation_title.encode('utf-8'))
                query.set_scope(True)
                query.set_num_page_results(1) # 返す検索結果は1件
                querier.send_query(query)
                result = put_json(querier)
                citation_cid = result["cluster_id"][0]

                if citation_cid is not None:
                    citations.append(citation_cid)
    
    return citations

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] != '':
        print json.dumps(get_citation(sys.argv[1].strip()))
