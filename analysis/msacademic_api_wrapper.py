#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import itertools
import math
from collections import Counter, defaultdict
from bs4 import BeautifulSoup
import requests

class MsacademicApiWrapper(object):

    api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'

    def __init__(self):
        pass

    @classmethod
    def get_title(cls, id):
        xml = cls.get_paper_info(id)
        soup = BeautifulSoup(xml, features='xml')
        title = ''
        # title = soup.select('content title')
        if soup.select('content'):
            title = soup.select('content')[0].find('Title').string
        return title

    @classmethod
    def get_paper_info(cls, id):
        key = 'paper_info_{0}'.format(id)
        api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
        api_postfix = 'Paper'
        filter_by_id = '?$filter=ID%20eq%20'
        http_proxy = {'http': 'proxy.kuins.net:8080'}
        url = "{0}{1}{2}{3}".format(cls.api_base_url, api_postfix, filter_by_id, id)
        xml = requests.get(url, proxies=http_proxy).text
        return xml

if __name__ == '__main__':
    print MsacademicApiWrapper().get_title('1348993')
    
