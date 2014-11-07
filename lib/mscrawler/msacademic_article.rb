#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

module Mscrawler
  # 書誌情報を保持するクラス
  class MsacademicArticle
    attr_writer :data

    # use_cacheフラグを変更することで，キャッシュからの読み込みをサポートする
    # idは必須
    def initialize(id, title: '', year: '', abstract: '', authors: [],
                   url: '', num_citations: 0, use_cache: true)
      @base_url = 'http://academic.research.microsoft.com/'
      @json_cache = JsonCache.new(dir: './mscrawler/cache/article/', prefix: 'article_cache_')
      cache = @json_cache.get(id)
      if (not cache.nil?) and cache['status'] == 'OK' and use_cache == true
        @status = 'OK'
        @data = cache['data']
      else
        @status = 'NG'
        postfix = 'Publication'
        bib_url = "#{ @base_url }#{ postfix }/#{ id }"
        u = UrlOpen.new
        bib_html = u.get(bib_url)
        
        charset = u.charset
        doc = Nokogiri::HTML.parse(bib_html, nil, charset)
        title = ''
        title = doc.css('.title-span').first.text if doc.css('.title-span').first
        num_citations = doc.css('#ctl00_MainContent_PaperItem_Citation').first.text.split[1] unless doc.css('#ctl00_MainContent_PaperItem_Citation').empty?
        authors = ''
        authors = doc.css('.author-name-tooltip').map { |elem| elem.text } if doc.css('.author-name-tooltip').first
        abstract = ''
        abstract = doc.css('#ctl00_MainContent_PaperItem_snippet').first.text if doc.css('#ctl00_MainContent_PaperItem_snippet').first
        year = Mscrawler::MsacademicApiWrapper.get_year(id)
        url = ''
        @data = {
          'id' => id,
          'title' => title,
          'year' => year,
          'authors' => authors,
          'abstract' => abstract,
          'url' => url,
          'num_citations' => num_citations
        }
        @status = 'OK' if @data['id'] != ''
      end
    end

    # Rubyオブジェクトとして整形して返す
    def to_h
      if @status == 'OK'
        return { 'status' => @status, 'data' => @data }
      else
        return { 'status' => 'NG', 'data' => { 'id' => '', 'title' => '', 'year' => '', 'authors' => '', 'abstract' => '', 'url' => '', 'num_citations' => '' } }
      end
    end

    # JSONファイルにキャッシュする
    def set_cache
      @json_cache.set(@data['id'], to_h)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require_relative '../json_cache.rb'
  ma = Mscrawler::MsacademicArticle.new('100', title: 'title', year: 'year', abstract: 'abstract', authors: ['author1', 'author2'], url: 'url', num_citations: 5, use_cache: true)  
  puts ma.to_h
  ma.set_cache
  mb = Mscrawler::MsacademicArticle.new('100', use_cache: true)
  puts mb.to_h
end
