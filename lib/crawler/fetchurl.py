#! /usr/bin/python
# -*- coding: utf-8 -*-

import sys
import time

import logging

try:
    import requests
except ImportError:
    print 'This program needs requests module to use'
    sys.exit(1)

class FetchUrl(object):
    '''
    Requestsモジュールを使うことでWebからHTMLを取得する
    '''

    def __init__(self):
        pass

    def base_url(self):
        return self.base_url

    def params(self):
        return self.params

    def headers(self):
        return self.headers

    def _get_http_response(self, url, params, headers, timeout):
        self.base_url = url
        self.params = params
        self.headers = headers

        self.response = requests.get(self.base_url, params=self.params, headers=self.headers, timeout=timeout)

    def get(self, url, params={}, headers={}, retry=0, timeout=100, sleep_time=60):
        while retry >= 0:
            self._get_http_response(url, params, headers, timeout)

            if self.status_code() == 200:
                break

            retry -= 1

            if retry > 0:
               time.sleep(sleep_time)

        return self.response

    def content(self):
        return self.response.content

    def text(self):
        return self.response.text

    def json(self):
        return self.response.json

    def url(self):
        return self.response.url

    def status_code(self):
        return self.response.status_code

    def encoding(self):
        return self.response.encoding

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)

    if len(sys.argv) == 2:
        f = FetchUrl()
        f.get('http://google.com/search', params={'q': 'twitter'})
        print 'The content of {0} is below:'.format(f.url)
        print f.content()
    elif len(sys.argv) == 3:
        f = FetchUrl()
        f.get('http://piyo.com/')
