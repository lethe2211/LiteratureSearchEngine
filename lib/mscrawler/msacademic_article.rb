#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# 書誌情報を保持するクラス
module Mscrawler
  class MsacademicArticle
    attr_writer :data

    # idは必須
    def initialize(id, title: '', year: '', abstract: '', authors: [],
                   url: '', num_citations: 0)
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

    # Rubyオブジェクトとして整形し返す
    def to_h
      return { 'status' => @status, 'data' => @data } if @status == 'OK'
    end
  end
end
