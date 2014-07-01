#! /usr/bin/python
# -*- coding: utf-8 -*-

import commands

from citeseerx_crawler import CiteSeerXCrawler
from google_scholar_bibliography import *
from bs4 import BeautifulSoup

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
            'authors':       [[],   'Authors',       11]  # 著者(新たに追加)
    }

    if len(querier.articles) > 0:
        articles = querier.articles[0].as_json()

    return articles

def get_citation(cluster_id):
    '''
    Cluster_idを受け取り，その論文が引用している論文のcluster_idを返す
    '''
    abspath = os.path.dirname(os.path.abspath(__file__))
    citation = filecache.Client(abspath + '/citation/')

    cache = citation.get(str(cluster_id))
    if cache is not None and cache['status'] == 'OK':
        return cache['data']
    else:
        art = get_bibliography(cluster_id) # 書誌情報を返す

        result = {'status': '', 'data': []}

        # CiteSeerXによる引用論文の取得
        if art["title"][0] is not None:
            c = CiteSeerXCrawler()
            search_results = c.search_with_title(art['title'][0], num=1)
            # print search_results
            for search_result in search_results:
                citation_titles =  c.get_citations(search_result)
                # print citation_titles
                for citation_title in citation_titles:
                    # print citation_title
                    querier = ScholarQuerierWithSnippets()
                    settings = ScholarSettings()
                    querier.apply_settings(settings)
                    query = SearchScholarQuery()
                    query.set_words(citation_title.encode('utf-8'))
                    query.set_scope(True)
                    query.set_num_page_results(1) # 返す検索結果は1件
                    querier.send_query(query)
                    res = put_json(querier)
                    citation_cid = res["cluster_id"][0]

                    if citation_cid is not None:
                        result['data'].append(citation_cid)

        # CiteSeerXによる引用論文の取得によって結果が得られなかった場合に限り，ParsCitによる引用情報の取得を行う
        if len(result['data']) == 0 and art["url_pdf"][0] is not None:
            cmd = os.path.dirname(os.path.abspath(__file__)) + "/../extract_citations.sh " + art["url_pdf"][0]
            xml = commands.getoutput(cmd)
            soup = BeautifulSoup(xml, "html.parser")

            if len(soup.find_all("citation")) > 0:
                for citation_soup in soup.find_all("citation"):
                    # 各引用論文について，タイトルで検索した時の上位1件のcluster_idを取得
                    citation_title = citation_soup.title.string if citation_soup.title else ''
     
                    querier = ScholarQuerierWithSnippets()
                    settings = ScholarSettings()
                    querier.apply_settings(settings)
                    query = SearchScholarQuery()
                    query.set_words(citation_title.encode('utf-8'))
                    query.set_scope(True)
                    query.set_num_page_results(1) # 返す検索結果は1件
                    querier.send_query(query)
                    res = put_json(querier)
                    citation_cid = res["cluster_id"][0]

                    if citation_cid is not None:
                        result['data'].append(citation_cid)
        
        # とりあえず結果が空でないならOKとする(←あまりよくない…)
        if len(result['data']) > 0:
            result['status'] = 'OK'
            citation.set(str(cluster_id), result)
        else:
            result['status'] = 'NG'

        return result['data']

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] != '':
        print json.dumps(get_citation(sys.argv[1].strip()))
