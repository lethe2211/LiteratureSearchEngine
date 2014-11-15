#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

# 検索結果を表すノードとエッジからなるグラフ
class SearchResultGraph < CacheableGraph
  def exists_search_result_node?(id)
    return (@graph[:nodes].key?(id.to_s) and @graph[:nodes][id.to_s].type == 'search_result')
  end

  def exists_normal_node?(id)
    return (@graph[:nodes].key?(id.to_s) and @graph[:nodes][id.to_s].type == 'normal')
  end

  def append_node(node)
    # NormalGraphNodeにSearchResultGraphNodeを上書きすることは可能だが，逆はできないようにする
    case node
      when SearchResultGraphNode
      unless exists_search_result_node?(node.id)
        @graph[:nodes][node.id.to_s] = node
      end
      when NormalGraphNode
      unless exists_node?(node.id)
        @graph[:nodes][node.id.to_s] = node
      end
    end
  end

  def append_edge(edge)
    
  end
end

if __FILE__ == $PROGRAM_NAME
  require_relative './json_cache.rb'

  require 'active_support/core_ext'
  bib1 = {"status" => "OK", "data" => {"title" => "title1", "year" => "year1"}}
  bib2 = {"status" => "OK", "data" => {"title" => "title2", "year" => "year2"}}
  bib3 = {"status" => "OK", "data" => {"title" => "title3", "year" => "year3"}}
  n1 = GraphNode.new(1, 10, bib1)
  n2 = SearchResultGraphNode.new(2, 20, bib2, 5)
  n3 = SearchResultGraphNode.new(3, 30, bib3, 1)
  n4 = SearchResultGraphNode.new(1, 30, bib3, 1)
  e1 = DirectedGraphEdge.new(1, 2, 5, "#cccccc", {})
  e2 = UndirectedGraphEdge.new(2, 3, 10, "#dddddd", {})
  e3 = UndirectedGraphEdge.new(1, 2, 10, "#dddddd", {})

  gc = SearchResultGraph.new('1')
  gc.append_node(n1)
  p gc.to_h
  gc.append_node(n2)
  p gc.to_h
  gc.append_node(n3)
  p gc.to_h
  gc.append_node(n4)
  p gc.to_h
  gc.delete_node(3)
  p gc.to_h
  gc.append_edge(e1)
  p gc.to_h
  gc.append_edge(e2)
  p gc.to_h
  gc.append_edge(e3)
  p gc.to_h
  gc.delete_edge(1, 2)
  p gc.to_h
  gc.set_cache
  gc2 = SearchResultGraph.new('1')
  puts gc2
  p gc2.to_h
  gc3 = SearchResultGraph.new('2')
  p gc3.to_h
end
