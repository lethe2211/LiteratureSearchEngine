#! /usr/bin/python
# -*- coding: utf-8 -*-

import os
import sys
import time
import argparse
import csv as csvfile
import logging

import requests
from bs4 import BeautifulSoup

from google_scholar_bibliography import *
import filecache


def get_citedby_count(cluster_id, from_year=2000, to_year=2014, timeout_count=10):
    '''
    Cluster_idを受け取り，指定期間の1年ごとの被引用数を取得する
    '''
    abspath = os.path.dirname(os.path.abspath(__file__))
    citedby_count = filecache.Client(abspath + '/citedby_count/')

    cache = citedby_count.get(str(cluster_id)) # キャッシュ機構

    if cache != None and cache['status'] == 'OK':
        return cache
    else:
        result = {'cluster_id': cluster_id, 'status': '', 'data': {}, }

        bibliography = get_bibliography(cluster_id)

        result['title'] = bibliography['title'][0]
        result['year'] = bibliography['year'][0]

        base_url = 'http://scholar.google.co.jp/scholar'

        payload = {'hl': 'ja', 'cites': str(cluster_id)}

        if int(result['year']) != None:
            from_year = int(result['year'])

        years = range(from_year, to_year+1)

        total = 0

        for y in years:
            payload['as_ylo'] = y
            payload['as_yhi'] = y

            t = timeout_count
            while True:
                r = requests.get(base_url, params=payload)
                logging.debug(r.url)
                logging.debug(r.status_code)

                if r.status_code == 200:
                    break

                t -= 1

                if t <= 0:
                    result['status'] = 'NG'
                    return result

                time.sleep(90)


            html = r.text
            soup = BeautifulSoup(html)
            hitcount_soup = soup.find('div', {'id': 'gs_ab_md'})

            hitcount_raw_text = hitcount_soup.text.strip()

            if hitcount_raw_text == '':
                result['data'][str(y)] = 0
            else:
                if hitcount_raw_text.startswith(u'約'):
                    result['data'][str(y)] = int(hitcount_raw_text.split()[1].encode('utf-8'))
                else:
                    result['data'][str(y)] = int(hitcount_raw_text.split()[0].encode('utf-8'))

            total += result['data'][str(y)]

            time.sleep(10)

        result['total'] = total

        result['status'] = 'OK'

        citedby_count.set(str(cluster_id), result)

        return result

def prettify(crawl_result):
    if crawl_result == None:
        print 'No result of crawl'

    elif crawl_result['status'] == 'NG':
        print 'This result is incomplete. Try again'

    else:
        print 'cluster_id: %s' % crawl_result['cluster_id']
        print 'title: %s' % crawl_result['title'] if crawl_result.has_key('title') else 'title: '
        print 'published year: %s' % crawl_result['year'] if crawl_result.has_key('year') else 'published year: '
        print 'total citedby: %d' % crawl_result['total']
        print 

        for y, c in sorted(crawl_result['data'].items()):
            print 'year: %(year)s, citedby: %(citedby)d' % {'year': y, 'citedby': c}

def put_csv(crawl_result):
    if crawl_result is None:
        print 'No result of crawl'

    elif crawl_result['status'] == 'NG':
        print 'This result is incomplete. Try again'

    else:
        abspath = os.path.dirname(os.path.abspath(__file__))
        directory = '/citedby_count_csv/'
        filename = str(crawl_result['cluster_id']) + '.csv'
        with open(abspath + directory + filename, 'w') as f:
            writer = csvfile.writer(f)
            writer.writerow([crawl_result['cluster_id'], crawl_result['title'], crawl_result['year'], crawl_result['total']])

            for y, c in sorted(crawl_result['data'].items()):
                writer.writerow([y, c])

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)

    parser = argparse.ArgumentParser(description='Count citedby according to the clusrter_id of a paper')
    parser.add_argument('-c', '--cluster_id', type=int)
    parser.add_argument('--csvfile', default=False, action='store_true')

    args = parser.parse_args()

    if args.csvfile:
        put_csv(get_citedby_count(args.cluster_id))
    else:
        prettify(get_citedby_count(args.cluster_id))

    # if len(sys.argv) < 1:
    #     pass
    # elif sys.argv[1] == '':
    #     pass
    # elif len(sys.argv) == 2:
    #     if args.c == True:
    #         csv(get_citedby_count(sys.argv[1]))
    #     else:
    #         prettify(get_citedby_count(sys.argv[1]))
    # elif len(sys.argv) == 3:
    #     prettify(get_citedby_count(sys.argv[1], int(sys.argv[2])))
    # elif len(sys.argv) == 4:
    #     prettify(get_citedby_count(sys.argv[1], int(sys.argv[2]), int(sys.argv[3])))
    # else:
    #    pass