#! /usr/bin/python
# -*- coding: utf-8 -*-

import json
import requests
import commands
import urlparse

from google_scholar_bibliography import *
import filecache

from bs4 import BeautifulSoup

def get_citedby(cluster_id):
    '''
    Cluster_idを受け取り，その論文に引用されている論文のcluster_idを返す

    TODO:
    10件以上の被引用論文を取得できるように改良する
    '''

    abspath = os.path.dirname(os.path.abspath(__file__))
    citedby = filecache.Client(abspath + '/citedby/')

    cache = citedby.get(str(cluster_id))
    if cache is not None and cache['status'] == 'OK':
        return cache['data']
    else:
        art = get_bibliography(cluster_id) # 書誌情報を返す

        result = {'status': '', 'data': []} # 被引用論文のcluster_id

        # 被引用提示ページの各検索結果に対して，被引用提示ページへのリンクからcluster_idを取得する
        if art["url_citations"][0] is not None:
            html = requests.get(art["url_citations"][0]).text
            #print html
            soup = BeautifulSoup(html)
            for soup_gs_ri in soup.find_all('div', {'class': 'gs_ri'}):
                if not hasattr(soup_gs_ri, 'name'):
                    continue

                if soup_gs_ri.find('div', {'class': 'gs_fl'}):
                    soup_fl = soup_gs_ri.find('div', {'class': 'gs_fl'})
                    #print soup_fl
                    if soup_fl.find('a') is None or soup_fl.a.get('href') is None:
                        continue

                    if soup_fl.a.get('href').startswith('/scholar?cites'):
                        if hasattr(soup_fl.a, 'string') and soup_fl.a.string.startswith(u'引用'):
                            parse = urlparse.urlparse(soup_fl.a.get('href'))
                            #print parse
                            citedby_cid = urlparse.parse_qs(parse.query)['cites'][0]

                    if citedby_cid is not None:
                        result['data'].append(citedby_cid)

            # soup_titles = soup.find_all("h3", "gs_rt")
            # for soup_title in soup_titles:
            #     # 各被引用論文について，タイトルで検索した時の上位1件のcluster_idを取得
            #     # ↑これって，被引用提示ページの各検索結果に対して被引用提示ページへのリンクを見てcitesパラメータを見たら一発じゃないの？？？
            #     citedby_title = soup_title.a.get_text() if soup_title.a else ''
            #     # print citedby_title
            #     # citedby_cmd = os.path.dirname(sys.argv[0]) + "/scholarpy/scholar.py -c 1 -t --csv --phrase " # CSV形式で検索
            #     # citedby_cmd += '"' + citedby_title + '"' 
            #     # csv = commands.getoutput(citedby_cmd)
            #     # #print csv
            #     # citedby_cid = csv.split('|')[5] if len(csv.split('|')) >= 6 else None  # 6番目がcluster_id

            #     querier = ScholarQuerierWithSnippets()
            #     settings = ScholarSettings()
            #     querier.apply_settings(settings)
            #     query = SearchScholarQuery()
            #     query.set_words(citedby_title.encode('utf-8'))
            #     query.set_scope(True)
            #     query.set_num_page_results(1) # 返す検索結果は1件
            #     querier.send_query(query)
            #     res = put_json(querier)
            #     citedby_cid = res["cluster_id"][0]

            #     if citedby_cid is not None:
            #         result['data'].append(citedby_cid)

        # とりあえず結果が空でないならOKとする(←あまりよくない…)
        if len(result['data']) > 0:
            result['status'] = 'OK'
            citedby.set(str(cluster_id), result)
        else:
            result['status'] = 'NG'


        return result['data']

if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] != '':
        print json.dumps(get_citedby(sys.argv[1].strip()))