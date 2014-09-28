#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require_relative './msacademic_search_result'

# 検索結果集合を保持するクラス
module Mscrawler
  class MsacademicSearchResults
    def initialize(query, start_num, end_num, search_results: [], use_cache: true)
      @json_cache = JsonCache.new(dir: './mscrawler/search_results/', prefix: 'search_results_cache_')
      cache = @json_cache.get("#{ query }_#{ start_num }_#{ end_num }")
      p cache
      if (not cache.nil?) and cache['status'] == 'OK' and use_cache == true
        @status = 'OK'
        @data = cache["data"]
      else
        @status = 'NG'
        @data = {
          'query' => query,
          'start' => start_num,
          'end' => end_num,
          'num' => end_num - start_num + 1,
          'search_results' => search_results
        }
        @status = 'OK' if @data['query'] != ''
      end
    end

    # 検索結果を追加
    def append(search_result)
      @data['search_results'].push(search_result)
    end

    def [](index)
      return @data[index]
    end

    # Rubyオブジェクトとして整形し返す
    def to_h
      if @status == 'OK'
        return { 'status' => @status, 'data' => @data }
      else
        return { 'status' => @status, 'data' => { 'query' => query,'start' => start_num, 'end' => end_num, 'num' => end_num - start_num + 1,'search_results' => search_results } }
      end
    end
    
    # JSONファイルにキャッシュする
    def set_cache
      @json_cache.set("#{ @data['query'] }_#{ @data['start'] }_#{ @data['end'] }", to_h)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require_relative '../json_cache.rb'
  ms = Mscrawler::MsacademicSearchResults.new('twitter', 1, 30, search_results: [Mscrawler::MsacademicSearchResult.new('200')])
  puts ms.to_h
  ms.set_cache
  ms2 = Mscrawler::MsacademicSearchResults.new('twitter', 1, 30, use_cache: true)
  ms3 = Mscrawler::MsacademicSearchResults.new('facebook', 1, 30, use_cache: true)
  ms4 = Mscrawler::MsacademicSearchResults.new('twitter', 2, 31, use_cache: true)
  puts ms2.to_h
  puts ms3.to_h
  puts ms4.to_h
end
