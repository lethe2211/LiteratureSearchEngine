# -*- coding: utf-8 -*-

# Arbor.jsを用いてグラフを構成するために必要なJSONを管理するクラス
# 必要に応じて継承し，様々なタイプのグラフを構成する
class Graph
  def initialize
    @graph = {nodes: {}, edges: {}}
  end

  def count_node
    return @graph[:nodes].length
  end

  def count_edge
    return @graph[:edges].length
  end

  # IDを受け取り，ノードが存在するかを返す
  def exists_node?(id)
    return @graph[:nodes].has_key?(id.to_s)
  end

  # GraphNodeクラスのオブジェクトを受け取り，@graphに追加する
  # すでにノードが存在する場合は追加しない
  def append_node(node)
    unless exists_node?(node.id.to_s)
      @graph[:nodes][node.id.to_s] = node
    end
  end

  # IDを受け取り，@graphから，そのノードと，そのノードに連結しているエッジすべてを削除する
  def delete_node(id)
    @graph[:nodes].delete(id.to_s)
    @graph[:edges].each do |key, value|
      if key == id.to_s
        @graph[:edges].delete(id.to_s)
      elsif value.has_key?(id.to_s)
        @graph[:edges][key].delete(id.to_s)
      end
    end
  end

  # 始点と終点のIDを受け取り，エッジが存在するかを返す
  def exists_edge?(source, destination)
    return (@graph[:edges].has_key?(source.to_s) and @graph[:edges][source].has_key?(destination.to_s))
  end

  # GraphEdgeクラスのオブジェクトを受け取り，@graphに追加する
  # すでにエッジが存在する場合は追加しない
  def append_edge(edge)
    if exists_node?(edge.source.to_s) and exists_node?(edge.destination.to_s)
      unless exists_edge?(edge.source.to_s, edge.destination.to_s)
        unless @graph[:edges].has_key?(edge.source.to_s)
          @graph[:edges][edge.source.to_s] = {}
        end
        @graph[:edges][edge.source.to_s][edge.destination.to_s] = edge
      end
    end
  end

  # 始点と終点のIDを受け取り，@graphから，それらに張られたエッジを削除する
  def delete_edge(source, destination)
    @graph[:edges][source.to_s].delete(destination.to_s)
  end

  # @graphをHashオブジェクトとして整形し，返す
  def to_h
    rubyobj = {nodes: {}, edges: {}}
    @graph[:nodes].each do |key, node|
      rubyobj[:nodes][key] = {id: node.id, type: node.type, weight: node.weight, bibliography: node.bibliography["data"], color: node.color, rank: node.rank}
    end
    @graph[:edges].each_key do |src_key|
      @graph[:edges][src_key].each do |dest_key, edge|
        unless rubyobj[:edges].has_key?(src_key)
          rubyobj[:edges][src_key] = {}
        end
        rubyobj[:edges][src_key][dest_key] = {source: edge.source, destination: edge.destination, directed: edge.directed, weight: edge.weight, color: edge.color}
      end
    end
    return rubyobj
  end
end

# グラフのノードに相当するクラス
class GraphNode
  attr_accessor :id, :weight, :bibliography, :type, :color, :rank

  def initialize(id, weight, bibliography)
    @id = id
    @weight = weight
    @bibliography = bibliography
    @type = "normal"
    @color = "#cccccc"
    @rank = "-"
  end
end

# 検索結果ノードに相当するクラス
class SearchResultGraphNode < GraphNode
  def initialize(id, weight, bibliography, rank)
    super(id, weight, bibliography)
    @type = "search_result"
    @color = "#dd3333"
    @rank = rank
  end
end

# グラフのエッジに相当するクラス
# このクラスではインスタンスを生成せず，サブクラスを用いる
class GraphEdge
  attr_accessor :weight, :color, :bibliography

  def initialize(weight, color, bibliography)
    @weight = weight
    @color = color
    @bibliography = bibliography
  end
end

# グラフの有向枝に相当するクラス
class DirectedGraphEdge < GraphEdge
  attr_accessor :source, :destination, :directed

  def initialize(source, destination, weight, color, bibliography)
    super(weight, color, bibliography)
    @source = source
    @destination = destination
    @directed = true
  end
end

# グラフの無向枝に相当するクラス
class UndirectedGraphEdge < GraphEdge
  attr_accessor :source, :destination, :directed

  def initialize(source, destination, weight, color, bibliography)
    super(weight, color, bibliography)
    @source = source
    @destination = destination
    @directed = false
  end
end

if __FILE__ == $0
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

  gc = Graph.new
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
end
