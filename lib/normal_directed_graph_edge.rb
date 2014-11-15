#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# 非検索結果論文ノード同士や，非検索結果論文ノードと検索結果論文ノードをつなぐエッジ
class NormalDirectedGraphEdge < DirectedGraphEdge
  def initialize(source, destination, weight, bibliography)
    super(source, destionation, weight, '#cccccc', bibliography)
  end
end

if __FILE__ == $PROGRAM_NAME
end
