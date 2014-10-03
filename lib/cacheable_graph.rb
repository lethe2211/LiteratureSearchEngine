# -*- coding: utf-8 -*-

# JSONファイルへのキャッシュを可能にしたグラフ
class CacheableGraph < Graph
  def initialize(keyword, use_cache: true)
    @keyword = keyword
    @json_cache = JsonCache.new(dir: './mscrawler/graph/', prefix: 'graph_cache_')
    cache = @json_cache.get(@keyword)
    # p cache
    if (not cache.nil?) and cache['status'] == 'OK' and use_cache == true
      @status = 'OK'
      graph_json = cache['data']
      # p graph_json
      @graph = { nodes: {}, edges: {} }
      graph_json['nodes'].each do |key, node|
        case node['type']
        when 'search_result'
          @graph[:nodes][key] = SearchResultGraphNode.new(node['id'], node['weight'], { 'status' => 'OK', 'data' => node['bibliography'] }, node['rank'])
        when 'normal'
          @graph[:nodes][key] = GraphNode.new(node['id'], node['weight'], { 'status' => 'OK', 'data' => node['bibliography'] })
        end
      end
      graph_json['edges'].each_key do |src_key|
        unless @graph[:edges].has_key?(src_key)
          @graph[:edges][src_key] = {}
        end
        unless @graph[:edges].has_key?(src_key)
          @graph[:edges][src_key] = {}
        end
        graph_json['edges'][src_key].each do |dest_key, edge|
          if edge['directed'] == true
            @graph[:edges][src_key][dest_key] = DirectedGraphEdge.new(edge['source'], edge['destination'], edge['weight'], edge['color'], {})
          else
            @graph[:edges][src_key][dest_key] = UndirectedGraphEdge.new(edge['source'], edge['destination'], edge['weight'], edge['color'], {})
          end
        end
      end
      # p @graph
    else
      @status = 'OK'
      @graph = { nodes: {}, edges: {} }
    end
  end

  def set_cache
    @json_cache.set(@keyword, to_h)
  end

  def to_h
    rubyobj = super
    if @status == 'OK'
      return { 'status' => 'OK', 'data' => rubyobj }
    else
      return { 'status' => 'NG', 'data' => { nodes: {}, edges: {} } }
    end
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

  gc = CacheableGraph.new('1')
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
  gc2 = CacheableGraph.new('1')
  puts gc2
  p gc2.to_h
  gc3 = CacheableGraph.new('2')
  p gc3.to_h
end
