# -*- coding: utf-8 -*-

require 'nokogiri'

module Mscrawler
  class MsacademicApiWrapper
    def initialize
      @api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
    end

    def self.get_title(id)
      html = get_paper_info(id)
      doc = Nokogiri::HTML.parse(html)
      title = ''
      title = doc.css('content title').first.text if doc.css('content title').first
      return title
    end

    def self.get_year(id)
      html = get_paper_info(id)
      doc = Nokogiri::HTML.parse(html)
      year = ''
      year = doc.css('year').first.text if doc.css('year').first
      return year
    end

    def self.get_authors(id)
      html = get_paper_author(id)
      doc = Nokogiri::HTML.parse(html)
      # TODO: authorのIDを取る？
      authors = doc.css('entry').map { |item| item.css('content name').text }
      return authors
    end

    def self.get_url(id)
      html = get_paper_url(id)
      doc = Nokogiri::HTML.parse(html)
      Rails.logger.debug(doc)
      url = ''
      url = doc.css('url').first.text if doc.css('url').first
      return url
    end

    def self.get_citations(id)
      html = get_paper_ref(src_id: id)
      doc = Nokogiri::HTML.parse(html)
      citations = doc.css('entry').map { |item| item.css('content dstid').text }
      return citations
    end

    def self.get_citedbyes(id)
      html = get_paper_ref(dst_id: id)
      doc = Nokogiri::HTML.parse(html)
      citedbyes = doc.css('entry').map { |item| item.css('content srcid').text }
      return citedbyes
    end

    def self.get_paper_info(id)
      api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
      api_postfix = 'Paper'
      filter_by_id = '?$filter=ID%20eq%20'
      http_proxy = 'http://proxy.kuins.net:8080/'
      url = "#{ api_base_url }#{ api_postfix }#{ filter_by_id }#{ id }"
      html = open(url, proxy: http_proxy).read
      return html
    end

    def self.get_paper_author(id)
      api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
      api_postfix = 'Paper_Author'
      filter_by_paperid = '?$filter=PaperID%20eq%20'
      http_proxy = 'http://proxy.kuins.net:8080/'
      url = "#{ api_base_url }#{ api_postfix }#{ filter_by_paperid }#{ id }"
      html = open(url, proxy: http_proxy).read
      return html
    end

    def self.get_paper_url(id)
      api_base_url = 'https://api.datamarket.azure.com/MRC/MicrosoftAcademic/v2/'
      api_postfix = 'Paper_Url'
      filter_by_paperid = '?$filter=PaperID%20eq%20'
      http_proxy = 'http://proxy.kuins.net:8080/'
      url = "#{ api_base_url }#{ api_postfix }#{ filter_by_paperid }#{ id }"
      html = open(url, proxy: http_proxy).read
      return html
    end

    def self.get_paper_ref(src_id: '', dst_id: '')
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
      html = open(url, proxy: http_proxy).read
      return html      
    end
  end
end
