#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# 検索結果論文ノード同士をつなぐエッジ
class BetweenSearchResultsDirectedGraphEdge < DirectedGraphEdge
  def initialize(source, destination, weight, bibliography)
    super(source, destination, weight, '#ff6666', bibliography)
  end
end

if __FILE__ == $PROGRAM_NAME
end
