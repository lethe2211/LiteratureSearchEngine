#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require_relative './msacademic_search_result'

# 検索結果集合を保持するクラス
module Mscrawler
  class MsacademicSearchResults
    def initialize(query, start_num, end_num, search_results: [])
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

    # 検索結果を追加
    def append(search_result)
      @data['search_results'].push(search_result)
    end

    def [](index)
      return @data[index]
    end

    # Rubyオブジェクトとして整形し返す
    def to_h
      return { 'status' => @status, 'data' => @data } if @status == 'OK'
    end
  end
end
