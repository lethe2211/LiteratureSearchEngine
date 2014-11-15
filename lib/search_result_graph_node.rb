#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# 検索結果ノードに相当するクラス
class SearchResultGraphNode < GraphNode
  def initialize(id, weight, bibliography, rank)
    super(id, weight, bibliography)
    @type = "search_result"
    @color = "#dd3333"
    @rank = rank
  end
end

if __FILE__ == $PROGRAM_NAME
end
