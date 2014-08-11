#! /usr/bin/python
# -*- coding: utf-8 -*-

import sys
import json
import logging
import urlparse
import commands

import filecache

from fetchurl import FetchUrl
from citeseerx_crawler import CiteSeerXCrawler
from google_scholar_base import *

from bs4 import BeautifulSoup

class GoogleScholarArticleCrawler(object):

    def __init__(self):
        pass

    def crawl(self, input_query):
        abspath = os.path.dirname(os.path.abspath(__file__))
        serp = filecache.Client(abspath + '/serp/')

        cache = serp.get(input_query) # キャッシュ機構
        if cache is not None and cache['status'] == 'OK':
            return cache
        else:
            result = {'status': 'NG', 'data': {}}

            querier = ScholarQuerierWithSnippets()
            settings = ScholarSettings()
            querier.apply_settings(settings)
            query = SearchScholarQuery()
            query.set_words(input_query)
            query.set_num_page_results(10) # 返す検索結果は10件
            querier.send_query(query)
            data = self.put_json(querier, input_query)

            if len(result) > 0:
                result['status'] = 'OK'
                result['data'] = data
                serp.set(input_query, result)

            return result

    def get_citation(self, cluster_id, num=10000):
        '''
        Cluster_idを受け取り，その論文が引用している論文のcluster_idを返す
        '''
        abspath = os.path.dirname(os.path.abspath(__file__))
        citation = filecache.Client(abspath + '/citation/')

        cache = citation.get(str(cluster_id))
        if cache is not None and cache['status'] == 'OK':
            return cache
        else:
            art = self.get_bibliography(cluster_id) # 書誌情報を返す

            result = {'status': 'NG', 'data': []}

            if art['data'] == {}:
                return result

            # CiteSeerXによる引用論文の取得
            if art['data']['title'] is not None:
                logging.debug('CiteSeerX')
                c = CiteSeerXCrawler()

                # 論文タイトルでCiteSeerXを検索
                search_results = c.search_with_title(art['data']['title'], num=1)
                time.sleep(1)

                for search_result in search_results:
                    citation_titles =  c.get_citations(search_result) # 引用論文のタイトルのリスト
                    #print citation_titles

                    # 各引用論文のcluster_idを取得
                    for citation_title in citation_titles:
                        if num <= 0:
                            break
                        # print citation_title
                        querier = ScholarQuerierWithSnippets()
                        settings = ScholarSettings()
                        querier.apply_settings(settings)
                        query = SearchScholarQuery()
                        query.set_words(citation_title.encode('utf-8'))
                        query.set_scope(True)
                        query.set_num_page_results(1) # 返す検索結果は1件
                        querier.send_query(query)

                        if self.put_json_zero(querier) != []:
                            res = self.put_json_zero(querier)
                            if res.has_key("cluster_id"):
                                citation_cid = res["cluster_id"]

                                if citation_cid is not None:
                                    result['data'].append(citation_cid)
                                    num -= 1

                        time.sleep(0.1)

            # CiteSeerXによる引用論文の取得によって結果が得られなかった場合に限り，ParsCitによる引用情報の取得を行う
            if len(result['data']) == 0 and art['data']['url_pdf'] is not None:
                logging.debug('ParsCit')
                cmd = os.path.dirname(os.path.abspath(__file__)) + "/../extract_citations.sh " + art['data']["url_pdf"]
                xml = commands.getoutput(cmd)
                soup = BeautifulSoup(xml, "html.parser")

                if len(soup.find_all("citation")) > 0:
                    for citation_soup in soup.find_all("citation"):
                        if num <= 0:
                            break

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

                        if self.put_json_zero(querier):
                            res = self.put_json_zero(querier)
                            citation_cid = res["cluster_id"]

                            if citation_cid is not None:
                                result['data'].append(citation_cid)
                                num -= 1
            
                        time.sleep(0.1)

            # とりあえず結果が空でないならOKとする(←あまりよくない…)
            if len(result['data']) > 0:
                result['status'] = 'OK'
                citation.set(str(cluster_id), result)
            else:
                result['status'] = 'NG'

            return result

    def get_citedby(self, cluster_id):
        '''
        Cluster_idを受け取り，その論文に引用されている論文のcluster_idを返す

        TODO:
        10件以上の被引用論文を取得できるように改良する
        '''

        abspath = os.path.dirname(os.path.abspath(__file__))
        citedby = filecache.Client(abspath + '/citedby/')

        cache = citedby.get(str(cluster_id))
        if cache is not None and cache['status'] == 'OK':
            return cache
        else:
            art = self.get_bibliography(cluster_id) # 書誌情報を返す

            result = {'status': 'NG', 'data': []} # 被引用論文のcluster_id

            # 被引用提示ページの各検索結果に対して，被引用提示ページへのリンクからcluster_idを取得する
            if art['data']['url_citations'] is not None:
                f = FetchUrl()
                html = f.get(art['data']['url_citations'], retry=3).text
                #print html
                soup = BeautifulSoup(html, 'html.parser')
                #print soup
                for soup_gs_ri in soup.find_all('div', {'class': 'gs_ri'}):
                    citedby_cid = None
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

            # とりあえず結果が空でないならOKとする(←あまりよくない…)
            if len(result['data']) > 0:
                result['status'] = 'OK'
                citedby.set(str(cluster_id), result)
            else:
                result['status'] = 'NG'


            return result

    def get_bibliography(self, cluster_id):
        '''
        Cluster_idを受け取り，書誌情報を返す
        '''
        abspath = os.path.dirname(os.path.abspath(sys.argv[0]))
        bibliography = filecache.Client(abspath + '/bibliography/')

        cache = bibliography.get(str(cluster_id)) # キャッシュ機構
        if cache is not None and cache['status'] == 'OK':
            return cache
        else:
            result = {'status': 'NG', 'data': {}}

            querier = ScholarQuerierWithSnippets()
            settings = ScholarSettings()
            querier.apply_settings(settings)
            query = ClusterScholarQuery(cluster=cluster_id)
            query.set_num_page_results(1) # 返す検索結果は1件
            querier.send_query(query)
            data = self.put_json_zero(querier)

            if data != {} and data['cluster_id'] is not None:
                result['status'] = 'OK'
                result['data'] = data
                bibliography.set(str(cluster_id), result)

            return result

    def get_abstract(self, cluster_id):
        '''
        Cluster_idを受け取り，対応する論文のアブストラクトを返す
        '''
        abspath = os.path.dirname(os.path.abspath(__file__))
        abstract = filecache.Client(abspath + '/abstract/')

        cache = abstract.get(str(cluster_id)) # キャッシュ機構
        if cache is not None and cache['status'] == 'OK':
            return cache['data']
        else:
            art = self.get_bibliography(cluster_id) # 書誌情報を返す

            result = {'status': '', 'data': ''}

            # CiteSeerXによる引用論文の取得
            if art["title"] is not None:
                c = CiteSeerXCrawler()
                search_results = c.search_with_title(art['title'], num=1)
                time.sleep(1)
                # print search_results
                if len(search_results) > 0:
                    result['data'] = c.get_abstract(search_results[0])

                if len(result['data']) > 0:
                    result['status'] = 'OK'
                    abstract.set(str(cluster_id), result)
                else:
                    result['status'] = 'NG'

            return result

    
    def search_pdf(self, cluster_id):
        '''
        Cluster_idを受け取り，対応する論文PDFのURLを返す
        '''
        abspath = os.path.dirname(os.path.abspath(__file__))
        pdf = filecache.Client(abspath + '/pdf/')

        cache = pdf.get(str(cluster_id)) # キャッシュ機構
        if cache is not None:
            return cache
        else:
            f = FetchUrl()
            url = 'http://scholar.google.co.jp/scholar'
            payload = {'cluster': cluster_id, 'hl': 'ja'}
            html = f.get(url, params=payload, retry=3).text

            soup = BeautifulSoup(html, 'html.parser')
            for s in soup.findAll('span', {'class': 'gs_ctg2'}):
                soup_link = s.parent.parent
                if soup_link.name == 'a' and soup_link['href'].endswith('.pdf'):
                    result = soup_link['href']
                    pdf.set(str(cluster_id), result)
                    return result

            return None

    def put_json(self, querier, input_query):
        '''
        JSONを出力
        '''
        search_results_json = {}
        search_results = []

        # TODO: search_results_json['query']を求める
        search_results_json['query'] = input_query
        
        articles = querier.articles

        search_results_json['num'] = len(articles)

        for rank, art in enumerate(articles):
            art_json = art.as_json()
            art_json = {k: v[0] for k, v in art_json.items()}

            search_result = {"cluster_id": art_json['cluster_id'], "rank": rank + 1, "title": art_json['title'], "url": art_json['url'], "snippet": art_json['snippet']}
            search_results.append(search_result)

            # PDFへの直リンクは引用論文取得のために必要であるため，取得できていない場合は論文詳細ページから取得
            # if art_json['data']['url_pdf'] is None:
            #     art_json['data']['url_pdf'] = self.search_pdf(art_json['data']['cluster_id'])
            #     time.sleep(1)

            # CiteSeerXによるアブストラクトの取得
            # if art['data']['title'] is not None:
            #     c = CiteSeerXCrawler()
            #     search_results = c.search_with_title(art_json['data']['title'], num=1)
            #     time.sleep(1)
            #     # print search_results
            #     if len(search_results) > 0:
            #         art_json['data']['abstract'] = c.get_abstract(search_results[0])


            
            # art_json['rank'] = [rank + 1, 'Rank', 13] # FIXME: 書誌情報に含めるのではなく，検索結果固有の情報にする

            # articles_json.append(art_json)
            
        search_results_json['search_results'] = search_results

        return search_results_json

    def put_json_zero(self, querier):
        '''
        JSONを出力
        '''

        articles_json = []
        articles = querier.articles
        for rank, art in enumerate(articles):
            art_json = art.as_json()

            art_json = {k: v[0] for k, v in art_json.items()}            

            # PDFへの直リンクは引用論文取得のために必要であるため，取得できていない場合は論文詳細ページから取得
            if art_json['url_pdf'] is None:
                art_json['url_pdf'] = self.search_pdf(art_json['cluster_id'])
                time.sleep(1)

            art_json['abstract'] = None

            # CiteSeerXによるアブストラクトの取得
            if art["title"] is not None:
                c = CiteSeerXCrawler()
                search_results = c.search_with_title(art_json['title'], num=1)
                time.sleep(1)
                # print search_results
                if len(search_results) > 0:
                    art_json['abstract'] = c.get_abstract(search_results[0])

            # TODO: JSONの構造を見直す
            # 1. 書誌情報(cluster_idに依存するもの): cluster_id, title, url, abstract, ...
            # 2. 引用情報: cluster_id, citation, citedby
            # 3. 検索結果情報: cluster_id, rank, snippet
            # 4. 検索結果集合情報: query, num, search_results
            # それぞれ，WebAPI化を前提にstatusとdataをうまく分類した形で作る
            # Bibliographyの1番目，2番目の要素は正直不必要なのでこの機会に消しておく(内包表記とか)

            # art_json = {k: v[0] for k, v in art_json.items()}

            articles_json.append(art_json)

        # logging.debug("articles_json: " + str(articles_json))
        # for art in articles_json:
        #     logging.debug('hogehoge')
        #     logging.debug(art)

        if len(articles_json) > 0:
            return articles_json[0]
        else:
            return {}


    
