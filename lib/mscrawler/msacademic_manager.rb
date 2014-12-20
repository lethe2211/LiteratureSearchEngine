# -*- coding: utf-8 -*-

require 'uri'
require 'nokogiri'
require 'parallel'
require_relative '../json_cache.rb'
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

    # クエリとランクの始点，終点を受け取り，検索結果を返す
    def crawl(query, start_num: 1, end_num: 30)
      msrs = Mscrawler::MsacademicSearchResults.new(query, start_num, end_num, use_cache: true)
      if msrs['search_results'].length > 0
        Rails.logger.debug("returned cached value: MsacademicSearchResults")
        return msrs.to_h 
      end

      postfix = 'Search'
      url = "#{ @base_url }#{ postfix }"
      Rails.logger.debug("crawl: #{ query }")
      params = { 'query' => query, 'start' => start_num, 'end' => end_num }
      u = UrlOpen.new
      html = u.get(url, params: params)
      charset = u.charset
      doc = Nokogiri::HTML.parse(html, nil, charset)
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
        sr_authors = item.css('.content > .author-name-tooltip').map { |elem| elem.text }
        sr_url = URI.join(@base_url, href).to_s
        sr_year_conference = item.css('.conference').text.strip!.gsub(/(\r\n|\r|\n|\s{3,})/, '')
        snippet = item.css('.abstract').text.strip! unless item.css('.abstract').empty?
        rank = (start_num + index).to_s
        msr = Mscrawler::MsacademicSearchResult.new(id, sr_title: sr_title, sr_authors: sr_authors, sr_url: sr_url, sr_year_conference: sr_year_conference, snippet: snippet, rank: rank)
        puts msr.to_h
        msrs.append(msr)
      end
      msrs.set_cache
      return msrs.to_h
    end

    def get_citation(id)
      return Mscrawler::MsacademicApiWrapper.get_citations(id.to_s)
    end

    def get_citedby(id)
      return Mscrawler::MsacademicApiWrapper.get_citedbyes(id.to_s)
    end

    # src_id(引用論文のid)，dest_id(被引用論文のid)を入力として受け取り，citation_contextを返す
    def get_citation_context(src_id, dest_id)
      citation_contexts = get_citation_contexts(dest_id)
      if citation_contexts.key?(src_id)
        return citation_contexts[src_id]
      else
        return []
      end
    end

    def get_citation_contexts(dest_id, start_num: 1, end_num: 100)
      json_cache = JsonCache.new(dir: './mscrawler/cache/citation_context/', prefix: 'citation_context_cache_')
      key = "#{ dest_id }"
      cache = json_cache.get(key)
      return cache['citation_contexts'] if cache

      hash = { 'dest_id' => dest_id, 'citation_contexts' => {} }
      postfix = 'Detail'
      url = "#{ @base_url }#{ postfix }"
      u = UrlOpen.new
      html = u.get(url, params: { 'id' => dest_id, 'entitytype' => 1, 'searchtype' => 7, 'start' => 1, 'end' => 100 })
      return hash['citation_contexts'] if html == ''
      charset = u.charset
      doc = Nokogiri::HTML.parse(html, nil, charset)
      header = doc.css('.bing-summary > .declare > span').first.text if doc.css('.bing-summary > .declare > span') and doc.css('.bing-summary > .declare > span').first
      return hash['citation_contexts'] unless header
      end_num = header.split()[2].gsub(/\(|\)/, '').to_i
      doc.css('.paper-citation-item').each do |item|
        citation_context = item.css('.content > .quot > li').map { |i| i.text }
        if item.css('h3 > .title').first
          href = item.css('h3 > .title').first['href']
          sid = href.split('/')[1]
          hash['citation_contexts'][sid] = citation_context
        end
      end
      params_array = []
      s = 101
      e = 200
      while s <= end_num
        if e > end_num
          params_array.push({ 'id' => dest_id, 'entitytype' => 1, 'searchtype' => 7, 'start' => s, 'end' => end_num })
        else
          params_array.push({ 'id' => dest_id, 'entitytype' => 1, 'searchtype' => 7, 'start' => s, 'end' => e })
        end
        s += 100
        e += 100
      end
      Parallel.each(params_array, in_threads: 4) do |params|
        url = "#{ @base_url }#{ postfix }"
        u = UrlOpen.new
        html = u.get(url, params: params)
        next if html == ''
        charset = u.charset
        doc = Nokogiri::HTML.parse(html, nil, charset)
        header = doc.css('.bing-summary > .declare > span').first.text if doc.css('.bing-summary > .declare > span') and doc.css('.bing-summary > .declare > span').first
        next unless header
        end_num = header.split()[2].gsub(/\(|\)/, '').to_i
        doc.css('.paper-citation-item').each do |item|
          citation_context = item.css('.content > .quot > li').map { |i| i.text }
          if item.css('h3 > .title').first
            href = item.css('h3 > .title').first['href']
            sid = href.split('/')[1]
            hash['citation_contexts'][sid] = citation_context
          end
        end
      end
      # until num > end_num
      #   if num + 100 > end_num
      #     params = { 'id' => dest_id, 'entitytype' => 1, 'searchtype' => 7, 'start' => start_num + num, 'end' => end_num }
      #   else
      #     params = { 'id' => dest_id, 'entitytype' => 1, 'searchtype' => 7, 'start' => start_num + num, 'end' => start_num + num + 99 }
      #   end
      #   u = UrlOpen.new
      #   html = u.get(url, params: params)
      #   charset = u.charset
      #   doc = Nokogiri::HTML.parse(html, nil, charset)
      #   header = doc.css('.bing-summary > .declare > span').first.text if doc.css('.bing-summary > .declare > span') and doc.css('.bing-summary > .declare > span').first
      #   break unless header
      #   end_num = header.split()[2].gsub(/\(|\)/, '').to_i
      #   doc.css('.paper-citation-item').each do |item|
      #     citation_context = item.css('.content > .quot > li').map { |i| i.text }
      #     if item.css('h3 > .title').first
      #       href = item.css('h3 > .title').first['href']
      #       sid = href.split('/')[1]
      #       hash['citation_contexts'][sid] = citation_context
      #     end
      #   end
      #   num += 100
      # end
      json_cache.set(key, hash)
      return hash['citation_contexts']
    end

    def get_bibliography(id)
      msa = Mscrawler::MsacademicArticle.new(id, use_cache: true)
      msa.set_cache
      return msa.to_h
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  mm = Mscrawler::MsacademicManager.new
  # p mm.crawl('twitter', start_num: 1, end_num: 30)
  # p mm.get_bibliography(39482)
  # p mm.get_citation('39482')
  # p mm.get_citedby('39482')
  p mm.get_citation_context('4710843', '39247661')
end
