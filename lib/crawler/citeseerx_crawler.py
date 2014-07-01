#! /usr/bin/python
# -*- coding: utf-8 -*-

import re
from urlparse import urljoin

from bs4 import BeautifulSoup

import filecache
from fetchurl import FetchUrl

class CiteSeerXCrawler(object):
    '''
    CiteSeerXをクローリング/スクレイピングするクラス
    '''

    def __init__(self):
        pass

    def search_with_title(self, title, num=10):
        '''
        タイトルを入力して，CiteSeerXによる検索結果のURLのリストを返す
        '''
        results = []
        title = self._remove_symbol(title)
        title = self._escape_whitespace(title)
        title = title.encode('utf-8')

        base_url = 'http://citeseerx.ist.psu.edu/' # 基底URL

        search_url = base_url + 'search'
        query = 'title:{0}'.format(title)
        params = {'q': query, 't': 'doc'}
        html = self._get_html(search_url, params)

        soup = BeautifulSoup(html)
        i = 0
        for soup_result in soup.findAll('div', {'class': 'result'}):
            if i >= num:
                break
            i += 1

            if soup_result.h3.a is not None:
                result = urljoin(base_url, soup_result.h3.a['href'])
                results.append(result)

        return results

    def get_citations(self, url):
        '''
        CiteSeerXの論文詳細ページから，引用論文のタイトルのリストを返す
        '''
        citation_titles = []

        html = self._get_html(url)

        soup = BeautifulSoup(html)

        if soup.find('div', {'id': 'citations'}).table.findAll('tr'):
            soup_table = soup.find('div', {'id': 'citations'}).table.findAll('tr')
            for soup_tr in soup_table:
                if soup_tr.findAll('td') and len(soup_tr.findAll('td')) >= 2:
                    soup_citation = soup_tr.findAll('td')[1]
                    if soup_citation.a:
                        citation_titles.append(soup_tr.findAll('td')[1].a.string)

        return citation_titles

    def _get_html(self, url, params={}):
        '''
        URLを入力し，Webから取得したHTMLを返す
        '''
        f = FetchUrl()
        html = f.get(url, params, retry=3).text
        return html

    def _remove_symbol(self, string):
        '''
        文字列から，半角記号を除く
        '''
        return re.sub(re.compile("[!-/:-@[-`{-~]"), '', string)

    def _escape_whitespace(self, string):
        '''
        文字列中の半角スペースを'+'に置き換える
        '''
        return re.sub(re.compile(' '), '+', string)

if __name__ == '__main__':
    c = CiteSeerXCrawler()
    results = c.search_with_title('pagerank:')
    #print results
    for result in results:
        print c.get_citations(result)


