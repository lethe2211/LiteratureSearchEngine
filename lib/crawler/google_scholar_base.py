#! /usr/bin/python
# -*- coding: utf-8 -*-

import time

from scholarpy.scholar import *

class ScholarArticleWithSnippets(ScholarArticle):
    '''
    著者・スニペットを追加
    JSONを出力できるように変更
    '''
    def __init__(self):
        self.attrs = {
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

        # The citation data in one of the standard export formats,
        # e.g. BibTeX.
        self.citation_data = None

    # JSON出力
    def as_json(self):
        return self.attrs

class ScholarArticle(object):
    '''

    '''
    def as_txt(self):
        # Get items sorted in specified order:
        items = sorted(list(self.attrs.values()), key=lambda item: item[2])
        # Find largest label length:
        max_label_len = max([len(str(item[1])) for item in items])
        fmt = '%%%ds %%s' % max_label_len
        res = []
        for item in items:
            #if item[0] is not None:
            res.append(fmt % (item[1], item[0]))
        return '\n'.join(res)


class ScholarArticleParser120726WithSnippets(ScholarArticleParser120726):
    '''
    著者・スニペット追加に対応した変更
    被引用数・バージョン数の日本語対応
    "gs_r"クラスのdivタグの内部の要素がそれぞれの検索結果
    '''

    # 引数divが"gs_r"クラスのdivタグの集合
    def _parse_article(self, div):
        self.article = ScholarArticleWithSnippets()

        for tag in div:
            if not hasattr(tag, 'name'):
                continue
            if str(tag).lower().find('.pdf'):
                if tag.find('div', {'class': 'gs_ttss'}):
                    self._parse_links(tag.find('div', {'class': 'gs_ttss'}))

            # "gs_ggs"クラスのdivタグにはPDFへの直リンクを含むものがあるので，url_pdfに追加しておく
            if tag.name == 'div' and self._tag_has_class(tag, 'gs_ggs'):
                for a in tag.find_all('a'):
                    if a.get('href').endswith('.pdf'):
                        self.article['url_pdf'] = a.get('href')
                        #print a.get('href')

            if tag.name == 'div' and self._tag_has_class(tag, 'gs_ri'):
                # There are (at least) two formats here. In the first
                # one, we have a link, e.g.:
                #
                # <h3 class="gs_rt">
                #   <a href="http://dl.acm.org/citation.cfm?id=972384" class="yC0">
                #     <b>Honeycomb</b>: creating intrusion detection signatures using
                #        honeypots
                #   </a>
                # </h3>
                #
                # In the other, there's no actual link -- it's what
                # Scholar renders as "CITATION" in the HTML:
                #
                # <h3 class="gs_rt">
                #   <span class="gs_ctu">
                #     <span class="gs_ct1">[CITATION]</span>
                #     <span class="gs_ct2">[C]</span>
                #   </span>
                #   <b>Honeycomb</b> automated ids signature creation using honeypots
                # </h3>
                #
                # We now distinguish the two.
                try:
                    atag = tag.h3.a
                    self.article['title'] = ''.join(atag.findAll(text=True))
                    self.article['url'] = self._path2url(atag['href'])
                    if self.article['url'].endswith('.pdf'): # 論文URLの内，リンク先アドレスが'.pdf'で終わるものがPDFへのリンク
                        self.article['url_pdf'] = self.article['url']
                except:
                    # Remove a few spans that have unneeded content (e.g. [CITATION])
                    for span in tag.h3.findAll(name='span'):
                        span.clear()
                    self.article['title'] = ''.join(tag.h3.findAll(text=True))


                # スニペットを追加
                if tag.find('div', {'class': 'gs_rs'}):
                    self.article['snippet'] = tag.find('div', {'class': 'gs_rs'}).get_text()

                if tag.find('div', {'class': 'gs_a'}):
                    # 著者を追加
                    authors = []
                    for a in tag.find('div', {'class': 'gs_a'}).get_text().split('-')[0].split(','):
                        authors.append(a.strip())
                    self.article['authors'] = authors

                    year = self.year_re.findall(tag.find('div', {'class': 'gs_a'}).text)
                    self.article['year'] = year[0] if len(year) > 0 else None

                if tag.find('div', {'class': 'gs_fl'}):
                    self._parse_links(tag.find('div', {'class': 'gs_fl'}))

    def _parse_links(self, span):
        for tag in span:
            if not hasattr(tag, 'name'):
                continue
            if tag.name != 'a' or tag.get('href') is None:
                continue

            if tag.get('href').startswith('/scholar?cites'):
                if hasattr(tag, 'string') and tag.string.startswith(u'引用'): # "startwith.('Cited by')"になっていた所を日本語版用に修正
                    self.article['num_citations'] = \
                        self._as_int(tag.string.split()[-1])

                # Weird Google Scholar behavior here: if the original
                # search query came with a number-of-results limit,
                # then this limit gets propagated to the URLs embedded
                # in the results page as well. Same applies to
                # versions URL in next if-block.
                self.article['url_citations'] = \
                    self._strip_url_arg('num', self._path2url(tag.get('href')))

                # We can also extract the cluster ID from the versions
                # URL. Note that we know that the string contains "?",
                # from the above if-statement.
                args = self.article['url_citations'].split('?', 1)[1]
                for arg in args.split('&'):
                    if arg.startswith('cites='):
                        self.article['cluster_id'] = arg[6:]

            if tag.get('href').startswith('/scholar?cluster'):
                if hasattr(tag, 'string') and tag.string.startswith(u'全 '): # ".startwith('All ')"となっていた所を日本語版用に修正
                    self.article['num_versions'] = \
                        self._as_int(tag.string.split()[1])
                self.article['url_versions'] = \
                    self._strip_url_arg('num', self._path2url(tag.get('href')))

            if tag.getText().startswith('Import'):
                self.article['url_citation'] = self._path2url(tag.get('href'))

class ClusterScholarQuery(ClusterScholarQuery):
    # 日本語版用に'hl=ja'を追加
    SCHOLAR_CLUSTER_URL = ScholarConf.SCHOLAR_SITE + '/scholar?' \
        + 'hl=ja' \
        + '&cluster=%(cluster)s' \
        + '&num=%(num)s'

class SearchScholarQuery(SearchScholarQuery):
    # 日本語版用に'hl=ja'を追加
    SCHOLAR_QUERY_URL = ScholarConf.SCHOLAR_SITE + '/scholar?' \
        + 'hl=ja' \
        + '&start=%(start)s' \
        + '&as_q=%(words)s' \
        + '&as_epq=%(phrase)s' \
        + '&as_oq=%(words_some)s' \
        + '&as_eq=%(words_none)s' \
        + '&as_occt=%(scope)s' \
        + '&as_sauthors=%(authors)s' \
        + '&as_publication=%(pub)s' \
        + '&as_ylo=%(ylo)s' \
        + '&as_yhi=%(yhi)s' \
        + '&btnG=&as_sdt=0,5&num=%(num)s'

    def __init__(self, start=0):
        ScholarQuery.__init__(self)
        self.start = start
        self.words = None # The default search behavior And検索
        self.words_some = None # At least one of those words OR検索
        self.words_none = None # None of these words NOT検索
        self.phrase = None     # 完全一致検索
        self.scope_title = False # If True, search in title only タイトルのみを検索
        self.author = None       # 著者検索
        self.pub = None          # 論文誌検索
        self.timeframe = [None, None] # 発行年の範囲を指定した検索

    def get_url(self):
        if self.words is None and self.words_some is None \
           and self.words_none is None and self.phrase is None \
           and self.author is None and self.pub is None \
           and self.timeframe[0] is None and self.timeframe[1] is None:
            raise QueryArgumentError('search query needs more parameters')

        urlargs = {'start': self.start or '',
                   'words': self.words or '',
                   'words_some': self.words_some or '',
                   'words_none': self.words_none or '',
                   'phrase': self.phrase or '',
                   'scope': 'title' if self.scope_title else 'any',
                   'authors': self.author or '',
                   'pub': self.pub or '',
                   'ylo': self.timeframe[0] or '',
                   'yhi': self.timeframe[1] or '',
                   'num': self.num_results or ScholarConf.MAX_PAGE_RESULTS}

        for key, val in urlargs.items():
            urlargs[key] = quote(str(val))

        return self.SCHOLAR_QUERY_URL % urlargs

class ScholarQuerierWithSnippets(ScholarQuerier):
    '''
    著者・スニペット追加に対応した変更
    HTMLの取得に失敗した時，同じ試行を10回まで繰り返すように変更
    '''
    class Parser(ScholarArticleParser120726WithSnippets):
        def __init__(self, querier):
            ScholarArticleParser120726WithSnippets.__init__(self)
            self.querier = querier

        def handle_article(self, art):
            self.querier.add_article(art)

    def _get_http_response(self, url, log_msg=None, err_msg=None):
        if log_msg is None:
            log_msg = 'HTTP response data follow'
        if err_msg is None:
            err_msg = 'request failed'

        retry = 10  # 試行回数

        while True:
            try:
                if retry <= 0:
                    return None

                ScholarUtils.log('info', 'requesting %s' % url)

                req = Request(url=url, headers={'User-Agent': ScholarConf.USER_AGENT})
                hdl = self.opener.open(req)
                html = hdl.read()

                ScholarUtils.log('debug', log_msg)
                ScholarUtils.log('debug', '>>>>' + '-'*68)
                ScholarUtils.log('debug', 'url: %s' % hdl.geturl())
                ScholarUtils.log('debug', 'result: %s' % hdl.getcode())
                ScholarUtils.log('debug', 'headers:\n' + str(hdl.info()))
                ScholarUtils.log('debug', 'data:\n' + html)
                ScholarUtils.log('debug', '<<<<' + '-'*68)

                return html
            except Exception as err:
                ScholarUtils.log('info', err_msg + ': %s' % err)
                retry -= 1
                time.sleep(10)  # 試行が失敗した際の待ち時間
                continue

