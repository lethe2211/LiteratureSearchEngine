# -*- coding: utf-8 -*-

require 'nokogiri'
require_relative '../json_cache.rb'
require 'logger'

module Mscrawler
  # Microsoft Academic Search APIを扱うためのクラス
  class MsacademicApiWrapper
    @@json_cache = JsonCache.new(dir: './mscrawler/cache/msacademic_api/', prefix: 'msacademic_api_cache_')

    def initialize
      @api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
    end

    def self.get_cache(id)
      return @@json_cache.get(id)
    end

    def self.set_cache(id, xml)
      @@json_cache.set(id, xml)
    end
    
    def self.get_title(id)
      xml = get_paper_info(id)
      doc = Nokogiri::HTML.parse(xml)
      title = ''
      title = doc.css('content title').first.text if doc.css('content title').first
      return title
    end

    def self.get_year(id)
      xml = get_paper_info(id)
      doc = Nokogiri::HTML.parse(xml)
      year = ''
      year = doc.css('year').first.text if doc.css('year').first
      return year
    end

    def self.get_authors(id)
      xml = get_paper_author(id)
      doc = Nokogiri::HTML.parse(xml)
      # TODO: authorのIDを取る？
      authors = doc.css('entry').map { |item| item.css('content name').text }
      return authors
    end

    def self.get_url(id)
      xml = get_paper_url(id)
      doc = Nokogiri::HTML.parse(xml)
      Rails.logger.debug(doc)
      url = ''
      url = doc.css('url').first.text if doc.css('url').first
      return url
    end

    def self.get_citations(id)
      xml = get_paper_ref(src_id: id)
      doc = Nokogiri::HTML.parse(xml)
      citations = doc.css('entry').map { |item| item.css('content dstid').text }
      return citations
    end

    def self.get_citedbyes(id)
      xml = get_paper_ref(dst_id: id)
      doc = Nokogiri::HTML.parse(xml)
      citedbyes = doc.css('entry').map { |item| item.css('content srcid').text }
      return citedbyes
    end

    def self.get_paper_info(id)
      key = "paper_info_#{ id }"
      cache = Mscrawler::MsacademicApiWrapper.get_cache(key)
      if cache
        return cache['xml']
      else
        api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
        api_postfix = 'Paper'
        filter_by_id = '?$filter=ID%20eq%20'
        http_proxy = 'http://proxy.kuins.net:8080/'
        url = "#{ api_base_url }#{ api_postfix }#{ filter_by_id }#{ id }"
        xml = open(url, proxy: http_proxy).read
        set_cache(key, { 'xml' => xml })
        return xml
      end
    end

    def self.get_paper_author(id)
      key = "paper_author_#{ id }"
      cache = Mscrawler::MsacademicApiWrapper.get_cache(key)
      if cache
        return cache['xml']
      else
        api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
        api_postfix = 'Paper_Author'
        filter_by_paperid = '?$filter=PaperID%20eq%20'
        http_proxy = 'http://proxy.kuins.net:8080/'
        url = "#{ api_base_url }#{ api_postfix }#{ filter_by_paperid }#{ id }"
        xml = open(url, proxy: http_proxy).read
        set_cache(key, { 'xml' => xml })
        return xml
      end
    end

    def self.get_paper_url(id)
      key = "paper_url_#{ id }"
      cache = Mscrawler::MsacademicApiWrapper.get_cache(key)
      if cache
        return cache['xml']
      else
        api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
        api_postfix = 'Paper_Url'
        filter_by_paperid = '?$filter=PaperID%20eq%20'
        http_proxy = 'http://proxy.kuins.net:8080/'
        url = "#{ api_base_url }#{ api_postfix }#{ filter_by_paperid }#{ id }"
        xml = open(url, proxy: http_proxy).read
        set_cache(key, { 'xml' => xml })
        return xml
      end
    end

    def self.get_paper_ref(src_id: '', dst_id: '')
      key = "paper_ref_src_id=#{ src_id }_dst_id=#{ dst_id }"
      cache = Mscrawler::MsacademicApiWrapper.get_cache(key)
      if cache
        return cache['xml']
      else
        api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
        api_postfix = 'Paper_Ref'
        filter = ''
        unless src_id.empty?
          unless dst_id.empty?
            filter = "?$filter=SrcID%20eq%20#{ src_id }%20and%20DstID%20eq%20#{ dst_id }"
          else
            filter = "?$filter=SrcID%20eq%20#{ src_id }"
          end
        else
          unless dst_id.empty?
            filter = "?$filter=DstID%20eq%20#{ dst_id }"
          else
            return ''
          end
        end
        http_proxy = 'http://proxy.kuins.net:8080/'
        url = "#{ api_base_url }#{ api_postfix }#{ filter }"
        xml = open(url, proxy: http_proxy).read
        set_cache(key, { 'xml' => xml })
        return xml
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require 'open-uri'
  puts Mscrawler::MsacademicApiWrapper.get_title('39482')
  puts Mscrawler::MsacademicApiWrapper.get_year('39482')
  puts Mscrawler::MsacademicApiWrapper.get_authors('39482')
  puts Mscrawler::MsacademicApiWrapper.get_url('39482')
  puts Mscrawler::MsacademicApiWrapper.get_citations('39482')
  puts Mscrawler::MsacademicApiWrapper.get_citedbyes('39482')
end
