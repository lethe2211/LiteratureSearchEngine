# -*- coding: utf-8 -*-

require 'citation_controller'
require 'parallel'

# 引用グラフを生成するためのクラス
class CitationGraphComposer
  def initialize
    @mm = Mscrawler::MsacademicManager.new
  end

  def compose_graph(articles)
    query = articles['data']['query']
    search_results = articles['data']['search_results']
    Rails.logger.debug(search_results)
    graph = compute_graph(query, search_results)
    Rails.logger.debug(graph.to_h['data'])
    return graph.to_h['data']
  end

  def compose_graph_(articles)
    graph_cache = JsonCache.new(dir: "./crawler/graph/")

    @query = articles["data"]["query"]
    cache = graph_cache.get(@query)

    if (not cache.nil?) and cache["status"] == 'OK'
      return cache["data"]
    else
      result = {status: "NG", data: {}}

      search_results = articles["data"]["search_results"]

      bibliographies = extract_bibliographies(search_results)
      citations = extract_citations(search_results)
      citedbyes = extract_citedbyes(search_results)

      graph = compute_graph(search_results, bibliographies, citations, citedbyes)
      if graph.count_node != 0
        result[:data] = graph.to_h
        result[:status] = "OK"
        graph_cache.set(@query, result)
      else
        result[:status] = "NG"
      end

      Rails.logger.debug(result[:data])
      return result[:data]
    end
  end

  private

  def extract_bibliographies(search_results)
    bibliographies = {}
    ids = search_results.map { |item| item['id'].to_s }
    Parallel.each(ids, in_threads: ids.length) do |id|
      Rails.logger.debug("bibliography: #{ id }")
      bibliography = @mm.get_bibliography(id.to_i)
      bibliographies[id] = bibliography
    end
    Rails.logger.debug(bibliographies)
    return bibliographies
  end

  def extract_citations(search_results)
    citations = {}
    ids = search_results.map { |item| item['id'].to_s }
    Parallel.each(ids, in_threads: ids.length) do |id|
      Rails.logger.debug("citation: #{ id }")
      citation = @mm.get_citation(id.to_i)
      citations[id] = citation
    end
    Rails.logger.debug(citations)
    return citations
  end

  def extract_citedbyes(search_results)
    citedbyes = {}
    ids = search_results.map { |item| item['id'].to_s }
    Parallel.each(ids, in_threads: ids.length) do |id|
      Rails.logger.debug("citedby: #{ id }")
      citedby = @mm.get_citedby(id.to_i)
      citedbyes[id] = citedby
    end
    Rails.logger.debug(citedbyes)
    return citedbyes
  end

  def compute_graph(query, search_results)
    keyword = "citation_#{ query }"
    graph = CacheableGraph.new(keyword, use_cache: false)
    if graph.count_node != 0
      return graph
    end

    bibliographies = extract_bibliographies(search_results)
    citations = extract_citations(search_results)
    citedbyes = extract_citedbyes(search_results)
    citation_contexts = {}

    used_cids = [] # ループ中ですでに1度呼ばれた論文
    used_result_cids = [] # ループ中ですでに1度呼ばれた検索結果論文

    # 任意の一対の検索結果論文について
    # search_results.each do |search_result1|
    #   id1 = search_result1["id"].to_s
    #   search_results.each do |search_result2|
    #     id2 = search_result2["id"].to_s
    #     if id1.to_i >= id2.to_i
    #       next
    #     end
    search_results.combination(2) do |search_result1, search_result2|
      id1 = search_result1["id"].to_s
      id2 = search_result2["id"].to_s
      Rails.logger.debug("id1: " + id1)
      Rails.logger.debug("id2: " + id2)
      Rails.logger.debug("")

      # 論文ノードの初期化
      unless used_result_cids.include?(id1)
        search_result_node = SearchResultGraphNode.new(id1, bibliographies[id1]["data"]["num_citations"], bibliographies[id1], search_result1["rank"])            
        graph.append_node(search_result_node)
        used_result_cids.push(id1)
        unless used_cids.include?(id1)
          used_cids.push(id1)
        end
      end

      unless used_result_cids.include?(id2)
        search_result_node = SearchResultGraphNode.new(id2, bibliographies[id2]["data"]["num_citations"], bibliographies[id2], search_result2["rank"])            
        graph.append_node(search_result_node)
        used_result_cids.push(id2)
        unless used_cids.include?(id2)
          used_cids.push(id2)
        end
      end

      citation_contexts[id1] = @mm.get_citation_contexts(id1)
      citation_contexts[id2] = @mm.get_citation_contexts(id2)

      Rails.logger.debug((citations[id1] & citations[id2]).to_s)
      Rails.logger.debug((citations[id1] & citedbyes[id2]).to_s)
      Rails.logger.debug((citedbyes[id1] & citations[id2]).to_s)
      Rails.logger.debug((citedbyes[id1] & citedbyes[id2]).to_s)

      # 両方が(共)引用する論文
      (citations[id1] & citations[id2]).each do |cit|
        b = @mm.get_bibliography(cit)
        bib = b.blank? ? { 'status' => 'NG', 'data' => {} } : b
        unless used_cids.include?(cit)
          node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
          graph.append_node(node)
          used_cids.push(cit)
        end
        # Rails.logger.debug("citation of id1 and id2: " + cit)
        edge_id1 = DirectedGraphEdge.new(id1, cit, 10, "#cccccc", { 'citation_context' => @mm.get_citation_context(id1, cit) })
        graph.append_edge(edge_id1)
        edge_id2 = DirectedGraphEdge.new(id2, cit, 10, "#cccccc", { 'citation_context' => @mm.get_citation_context(id2, cit) })
        graph.append_edge(edge_id2)
      end

      # 片方が引用し，もう片方が被引用する論文
      (citations[id1] & citedbyes[id2]).each do |cit|
        b = @mm.get_bibliography(cit)
        bib = b.blank? ?  { 'status' => 'NG', 'data' => {} } : b
        unless used_cids.include?(cit)
          node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
          graph.append_node(node)
          used_cids.push(cit)
        end
        # Rails.logger.debug("citation of id1 and cited by id2: " + cit)
        edge_id1 = DirectedGraphEdge.new(id1, cit, 10, "#cccccc", { 'citation_context' => @mm.get_citation_context(id1, cit) })
        graph.append_edge(edge_id1)
        edge_id2 = DirectedGraphEdge.new(cit, id2, 10, "#cccccc", { 'citation_context' => @mm.get_citation_context(cit, id2) })
        graph.append_edge(edge_id2)
      end

      # 片方が被引用し，もう片方が引用する論文
      (citedbyes[id1] & citations[id2]).each do |cit|
        b = @mm.get_bibliography(cit)
        bib = b.blank? ?  { 'status' => 'NG', 'data' => {} } : b
        unless used_cids.include?(cit)
          node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
          graph.append_node(node)
          used_cids.push(cit)
        end
        # Rails.logger.debug("cited by id1 and citation of id2: " + cit)
        edge_id1 = DirectedGraphEdge.new(cit, id1, 10, "#cccccc", { 'citation_context' => @mm.get_citation_context(cit, id1) })
        graph.append_edge(edge_id1)
        edge_id2 = DirectedGraphEdge.new(id2, cit, 10, "#cccccc", { 'citation_context' => @mm.get_citation_context(id2, cit) })
        graph.append_edge(edge_id2)  
      end 
      
      # 両方が被引用される論文
      (citedbyes[id1] & citedbyes[id2]).each do |cit|
        b = @mm.get_bibliography(cit)
        bib = b.blank? ?  { 'status' => 'NG', 'data' => {} } : b
        unless used_cids.include?(cit)
          node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
          graph.append_node(node)
          used_cids.push(cit)
        end
        # Rails.logger.debug("cited by id1 and id2: " + cit)
        citation_context_cit_id1 = @mm.get_citation_context(cit, id1)
        citation_context_cit_id2 = @mm.get_citation_context(cit, id2)
        edge_id1 = DirectedGraphEdge.new(cit, id1, 10, "#cccccc", { 'citation_context' => citation_context_cit_id1, 'co-citation_context' => (citation_context_cit_id1 & citation_context_cit_id2) })
        graph.append_edge(edge_id1)
        edge_id2 = DirectedGraphEdge.new(cit, id2, 10, "#cccccc", { 'citation_context' => citation_context_cit_id2, 'co-citation_context' => (citation_context_cit_id1 & citation_context_cit_id2) })
        graph.append_edge(edge_id2)
      end

      # id1の論文がid2の論文を引用している
      if (citedbyes[id2]).include?(id1) or (citations[id1]).include?(id2)
        citation_context = @mm.get_citation_context(id1, id2)
        edge = DirectedGraphEdge.new(id1, id2, 10, "#333333", { 'citation_context' => citation_context })
        graph.append_edge(edge)
      end

      # id2の論文がid1の論文を引用している
      if (citations[id2]).include?(id1) or (citedbyes[id1]).include?(id2)
        citation_context = @mm.get_citation_context(id2, id1)
        edge = DirectedGraphEdge.new(id2, id1, 10, "#333333", { 'citation_context' => citation_context })
        graph.append_edge(edge)
      end
    end
    graph.set_cache
    return graph
  end
end
