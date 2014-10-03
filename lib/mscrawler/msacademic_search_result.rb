#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require_relative './msacademic_article'

# 検索結果を保持するクラス
module Mscrawler
  class MsacademicSearchResult
    # idは必須
    def initialize(id, sr_title: '', sr_authors: [], sr_url: '', sr_year_conference: '', bibliography: {}, snippet: '', rank: -1)
      @data = {
        'id' => id,
        'sr_title' => sr_title,
        'sr_authors' => sr_authors,
        'sr_url' => sr_url,
        'sr_year_conference' => sr_year_conference,
        'bibliography' => bibliography,
        'snippet' => snippet,
        'rank' => rank
      }
    end

    def [](index)
      return @data[index]
    end

    # Rubyオブジェクトとして整形し返す
    def to_h
      return @data
    end
  end
end
