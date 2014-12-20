# -*- coding: utf-8 -*-

require 'citation_controller'
require 'parallel'

# 引用グラフを生成するためのクラス
class CitationGraphComposer
  def initialize
    @mm = Mscrawler::MsacademicManager.new
    @citation_threshold = -1
  end

  def compose_graph(articles, start_num: 1, end_num: 10)
    query = articles['data']['query']
    search_results = articles['data']['search_results']
    Rails.logger.debug(search_results)
    graph = compute_graph(query, search_results, start_num, end_num)
    Rails.logger.debug(graph.to_h['data'])
    return graph.to_h['data']
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

  def compute_graph(query, search_results, start_num, end_num)
    keyword = "citation_#{ query }"
    graph = SearchResultGraph.new(keyword, use_cache: false)

    bibliographies = extract_bibliographies(search_results)
    citations = extract_citations(search_results)
    citedbyes = extract_citedbyes(search_results)
    citation_contexts = {}

    # used_cids = [] # ループ中ですでに1度呼ばれた論文
    # used_result_cids = [] # ループ中ですでに1度呼ばれた検索結果論文

    # 任意の一対の検索結果論文について
    search_results_combination = search_results.combination(2)
    # Parallel.each(search_results_combination.to_a, in_processes: search_results_combination.to_a.length) do |search_result1, search_result2| # search_results_combination.reduce(0) { |sum, i| sum += 1 } ) do |search_result1, search_result2|

    search_results_target = search_results.select { |item| start_num <= item['rank'].to_i && item['rank'].to_i <= end_num } # 検索結果ノードとなる検索結果集合
    search_results_top = search_results
      .select { |item| item['rank'].to_i < start_num }
      .map { |item| item['id'].to_s }

    search_results_target.combination(2) do |search_result1, search_result2|
      id1 = search_result1["id"].to_s
      id2 = search_result2["id"].to_s
      Rails.logger.debug("id1: " + id1)
      Rails.logger.debug("id2: " + id2)
      Rails.logger.debug("")

      init_paper_node(id1, search_result1, bibliographies, graph)
      init_paper_node(id2, search_result2, bibliographies, graph)
      
      citation_contexts[id1] = @mm.get_citation_contexts(id1)
      citation_contexts[id2] = @mm.get_citation_contexts(id2)

      Rails.logger.debug((citations[id1] & citations[id2]).to_s)
      Rails.logger.debug((citations[id1] & citedbyes[id2]).to_s)
      Rails.logger.debug((citedbyes[id1] & citations[id2]).to_s)
      Rails.logger.debug((citedbyes[id1] & citedbyes[id2]).to_s)

      append_co_citation_node(id1, id2, citations, search_results_top, graph)

      append_citation_and_citedby_node(id1, id2, citations, citedbyes, search_results_top, graph)
      
      append_co_citedby_node(id1, id2, citedbyes, search_results_top, graph)

      append_between_search_results_directed_graph_edge(id1, id2, citations, citedbyes, graph)
      append_between_search_results_directed_graph_edge(id2, id1, citations, citedbyes, graph)
    end

    graph.set_cache
    return graph
  end

  # 論文ノードの初期化
  def init_paper_node(id, search_result, bibliographies, graph)
    search_result_node = SearchResultGraphNode.new(id, bibliographies[id]["data"]["num_citations"], bibliographies[id], search_result["rank"])
    graph.append_node(search_result_node)
  end

  # 両方が(共)引用する論文
  def append_co_citation_node(id1, id2, citations, search_results_top, graph)
    co_citation = citations[id1] & citations[id2]
    Parallel.each(co_citation, in_threads: co_citation.length) do |cit|
    # (citations[id1] & citations[id2]).each do |cit|
      b = @mm.get_bibliography(cit)
      bib = b.blank? ? { 'status' => 'NG', 'data' => {} } : b

      Rails.logger.debug(bib['data'])
      if bib['data']['num_citations'].to_i > @citation_threshold
        node = NormalGraphNode.new(cit, bib["data"]["num_citations"], bib)
        if search_results_top.include?(cit)
          node.color = '#00FF00'
        end

        graph.append_node(node)

        edge_id1 = NormalDirectedGraphEdge.new(id1, cit, 10, { 'citation_context' => @mm.get_citation_context(id1, cit) })
        graph.append_edge(edge_id1)
        edge_id2 = NormalDirectedGraphEdge.new(id2, cit, 10, { 'citation_context' => @mm.get_citation_context(id2, cit) })
        graph.append_edge(edge_id2)
      else
        Rails.logger.debug('break!')
      end
    end
  end

  def append_citation_and_citedby_node(id1, id2, citations, citedbyes, search_results_top, graph)
    citation_and_citedby = citedbyes[id1] & citations[id2]
    # (citedbyes[id1] & citations[id2]).each do |cit|
    Parallel.each(citation_and_citedby, in_threads: citation_and_citedby.length) do |cit|
      b = @mm.get_bibliography(cit)
      bib = b.blank? ?  { 'status' => 'NG', 'data' => {} } : b

      Rails.logger.debug(bib['data'])
      if bib['data']['num_citations'].to_i > @citation_threshold
        node = NormalGraphNode.new(cit, bib["data"]["num_citations"], bib)
        if search_results_top.include?(cit)
          node.color = '#00FF00'
        end

        graph.append_node(node)

        edge_id1 = NormalDirectedGraphEdge.new(cit, id1, 10, { 'citation_context' => @mm.get_citation_context(cit, id1) })
        graph.append_edge(edge_id1)
        edge_id2 = NormalDirectedGraphEdge.new(id2, cit, 10, { 'citation_context' => @mm.get_citation_context(id2, cit) })
        graph.append_edge(edge_id2)
      else
        Rails.logger.debug('break!')
      end
    end 
  end

  def append_co_citedby_node(id1, id2, citedbyes, search_results_top, graph)
    co_citedby = citedbyes[id1] & citedbyes[id2]
    Rails.logger.debug(co_citedby.to_s)
    # (citedbyes[id1] & citedbyes[id2]).each do |cit|
    Parallel.each(co_citedby, in_threads: co_citedby.length) do |cit|
      b = @mm.get_bibliography(cit)
      bib = b.blank? ?  { 'status' => 'NG', 'data' => {} } : b

      Rails.logger.debug(bib['data'])
      if bib['data']['num_citations'].to_i > @citation_threshold
        node = NormalGraphNode.new(cit, bib["data"]["num_citations"], bib)
        if search_results_top.include?(cit)
          node.color = '#00FF00'
        end

        graph.append_node(node)

        citation_context_cit_id1 = @mm.get_citation_context(cit, id1)
        citation_context_cit_id2 = @mm.get_citation_context(cit, id2)
        edge_id1 = NormalDirectedGraphEdge.new(cit, id1, 10, { 'citation_context' => citation_context_cit_id1, 'co-citation_context' => (citation_context_cit_id1 & citation_context_cit_id2) })
        graph.append_edge(edge_id1)
        edge_id2 = NormalDirectedGraphEdge.new(cit, id2, 10, { 'citation_context' => citation_context_cit_id2, 'co-citation_context' => (citation_context_cit_id1 & citation_context_cit_id2) })
        graph.append_edge(edge_id2)
      else
        Rails.logger.debug('break!')
      end
    end
  end

  def append_between_search_results_directed_graph_edge(id1, id2, citations, citedbyes, graph)
    if (citedbyes[id2]).include?(id1) or (citations[id1]).include?(id2)
      citation_context = @mm.get_citation_context(id1, id2)
      edge = BetweenSearchResultsDirectedGraphEdge.new(id1, id2, 20, { 'citation_context' => citation_context })
      graph.append_edge(edge)
    end    
  end
end
