#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# 書誌情報を保持するクラス
module Mscrawler
  class MsacademicArticle
    attr_writer :data

    # use_cacheフラグを変更することで，キャッシュからの読み込みをサポートする
    # idは必須
    def initialize(id, title: '', year: '', abstract: '', authors: [],
                   url: '', num_citations: 0, use_cache: true)
      @json_cache = JsonCache.new(dir: './mscrawler/article/', prefix: 'article_cache_')
      cache = @json_cache.get(id)
      p cache
      if (not cache.nil?) and cache['status'] == 'OK' and use_cache == true
        @status = 'OK'
        @data = cache["data"]
      else
        @status = 'NG'
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
