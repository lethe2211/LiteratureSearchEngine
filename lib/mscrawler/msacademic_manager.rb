# -*- coding: utf-8 -*-

require 'uri'
require 'nokogiri'
require_relative '../url_open.rb'
require_relative './msacademic_search_results.rb'
require_relative './msacademic_api_wrapper.rb'

# Microsoft Academic Searchの検索，書誌情報抽出に関するメソッドを集めたクラス
module Mscrawler
  class MsacademicManager
    def initialize
      @base_url = 'http://academic.research.microsoft.com/'
      @api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
    end

    def crawl(query, start_num: 1, end_num: 30)
      msrs = Mscrawler::MsacademicSearchResults.new(query, start_num, end_num)
      postfix = 'Search'
      url = "#{ @base_url }#{ postfix }"
      Rails.logger.debug("crawl: #{ query }")
      params = { 'query' => query, 'start' => start_num, 'end' => end_num }
      u = UrlOpen.new
      html = u.get(url, params: params)
      charset = u.charset
      doc = Nokogiri::HTML.parse(html, nil, charset)
      # puts doc
      doc.css('.paper-item').each_with_index do |item, index|
        # 検索結果と書誌情報で，タイトルや著者などの情報は冗長に持たせておくと，処理をうまく分割できて良い
        id = ''
        sr_title = ''
        unless item.css('.title').empty?
          href = item.css('.title > h3 > a')[0]['href']
          id = href.split('/')[1]
          sr_title = item.css('.title > h3 > a').first.text
        end
        unless item.css('.title-fullwidth').empty?
          href = item.css('.title-fullwidth > h3 > a')[0]['href']
          id = href.split('/')[1]
          sr_title = item.css('.title-fullwidth > h3 > a').first.text
        end
        sr_authors = item.css('.content').first.text.strip!
        sr_url = URI.join(@base_url, href)
        sr_year_conference = item.css('.conference').text.strip!.gsub(/(\r\n|\r|\n|\s{3,})/, '')
        # puts id
        # puts sr_title
        # puts sr_authors
        # puts sr_url
        # puts sr_year_conference
        snippet = item.css('.abstract').text.strip! unless item.css('.abstract').empty?
        rank = (index + 1).to_s
        msr = Mscrawler::MsacademicSearchResult.new(id, sr_title: sr_title, sr_authors: sr_authors, sr_url: sr_url, sr_year_conference: sr_year_conference, snippet: snippet, rank: rank)
        msrs.append(msr)
      end
      return msrs.to_h
    end

    def get_citation(id)
      return Mscrawler::MsacademicApiWrapper.get_citations(id.to_s)
    end

    def get_citedby(id)
      return Mscrawler::MsacademicApiWrapper.get_citedbyes(id.to_s)
    end

    def get_bibliography(id)
      # API制限にひっかかるなら書誌情報ページから直接抜いてくる
      postfix = 'Publication'
      bib_url = "#{ @base_url }#{ postfix }/#{ id }"
      u = UrlOpen.new
      bib_html = u.get(bib_url)
      charset = u.charset
      doc = Nokogiri::HTML.parse(bib_html, nil, charset)
      title = ''
      title = doc.css('.title-span').first.text if doc.css('.title-span').first
      num_citations = doc.css('#ctl00_MainContent_PaperItem_Citation').first.text.split[1] unless doc.css('#ctl00_MainContent_PaperItem_Citation').empty?
      authors = doc.css('.author-name-tooltip').first.text
      abstract = ''
      abstract = doc.css('#ctl00_MainContent_PaperItem_snippet').first.text if doc.css('#ctl00_MainContent_PaperItem_snippet').first
      # puts title
      # puts num_citations
      # puts abstract

      year = Mscrawler::MsacademicApiWrapper.get_year(id)
      url = ''
      # url = Mscrawler::MsacademicApiWrapper.get_url(id)

      msa = Mscrawler::MsacademicArticle.new(id, title: title, year: year, abstract: abstract, authors: authors, url: url, num_citations: num_citations)
      return msa.to_h
    end

    def get_pdf(id)

    end
  end
end

if __FILE__ == $PROGRAM_NAME
  mm = Mscrawler::MsacademicManager.new
  # p mm.crawl('twitter', start_num: 1, end_num: 30)
  # p mm.get_bibliography(39482)
  p mm.get_citation('39482')
  p mm.get_citedby('39482')
end
