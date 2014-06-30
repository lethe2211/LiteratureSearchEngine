#! /usr/bin/python
# -*- coding: utf-8 -*-

import sys
import os
import logging
from bs4 import BeautifulSoup

import filecache
from fetchurl import FetchUrl

def search_pdf(cluster_id):
    '''
    Cluster_idを受け取り，対応する論文PDFのURLを返す
    '''
    abspath = os.path.dirname(os.path.abspath(__file__))
    pdf = filecache.Client(abspath + '/pdf/')

    cache = pdf.get(str(cluster_id)) # キャッシュ機構
    if cache != None:
        return cache
    else:
        f = FetchUrl()
        url = 'http://scholar.google.co.jp/scholar'
        payload = {'cluster': cluster_id, 'hl': 'ja'}
        html = f.get(url, params=payload, retry=3).text

        soup = BeautifulSoup(html)
        for s in soup.findAll('span', {'class': 'gs_ctg2'}):
            soup_link = s.parent.parent
            if soup_link.name == 'a' and soup_link['href'].endswith('.pdf'):
                result = soup_link['href']
                pdf.set(str(cluster_id), result)
                return result

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)

    if len(sys.argv) == 2 and sys.argv[1] != '':
        print search_pdf(sys.argv[1])