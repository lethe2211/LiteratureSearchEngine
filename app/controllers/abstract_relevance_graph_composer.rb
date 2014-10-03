# -*- coding: utf-8 -*-

require 'citation_controller'

class AbstractRelevanceGraphComposer
  def initialize
    @mm = Mscrawler::MsacademicManager.new
  end

  # アブストラクトの類似度に応じたグラフを作成
  def compose_graph(articles)
    query = articles['data']['query']
    search_results = articles['data']['search_results']

    graph = compute_graph(query, search_results)
    return graph.to_h['data']
  end

  # アブストラクトの類似度に応じたグラフを作成
  def compose_graph_(articles)
    graph_cache = JsonCache.new(dir: "../lib/crawler/graph/", prefix: "cache_relevance_")
    
    @query = articles["data"]["query"]
    cache = graph_cache.get(@query)

    if (not cache.nil?) and cache["status"] == 'OK'
      return cache["data"]
    else
      result = {status: "NG", data: {}}               

      search_results = articles["data"]["search_results"]
      bibliographies = extract_bibliographies(search_results) # 検索結果の各論文の書誌情報

      threshold = 0.2           # 類似度のしきい値

      graph = compute_graph(search_results, bibliographies, threshold)

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
    search_results.each do |search_result|
      id  = search_result["id"].to_s
      Rails.logger.debug("bibliography: " + id)
      bib = @mm.get_bibliography(id)
      bibliographies[id] = bib.blank? ? [] : bib
    end
    Rails.logger.debug(bibliographies)
    return bibliographies
  end

  def compute_graph(query, search_results)
    keyword = "abstract_relevance_#{ query }"
    graph = CacheableGraph.new(keyword)
    if graph.count_node != 0
      return graph
    end
    bibliographies = extract_bibliographies(search_results) # 検索結果の各論文の書誌情報
    threshold = 0.1             # 類似度のしきい値

    used_ids = [] # ループ中ですでに1度呼ばれた論文
    used_result_ids = [] # ループ中ですでに1度呼ばれた検索結果論文

    # 任意の一対の検索結果論文について
    search_results.each do |search_result1|
      id1 = search_result1["id"].to_s
      search_results.each do |search_result2|
        id2 = search_result2["id"].to_s
        if id1.to_i >= id2.to_i
          next
        end

        # 論文ノードの初期化
        unless used_result_ids.include?(id1)
          search_result_node = SearchResultGraphNode.new(id1, bibliographies[id1]["data"]["num_citations"], bibliographies[id1], search_result1["rank"])            
          graph.append_node(search_result_node)
          used_result_ids.push(id1)
          unless used_ids.include?(id1)
            used_ids.push(id1)
          end
        end

        unless used_result_ids.include?(id2)
          search_result_node = SearchResultGraphNode.new(id2, bibliographies[id2]["data"]["num_citations"], bibliographies[id2], search_result2["rank"])            
          graph.append_node(search_result_node)
          used_result_ids.push(id2)
          unless used_ids.include?(id2)
            used_ids.push(id2)
          end
        end

        if bibliographies[id1]["data"]["abstract"] and bibliographies[id2]["data"]["abstract"]
          words1 = StringUtil.count_frequency(bibliographies[id1]["data"]["abstract"])
          words2 = StringUtil.count_frequency(bibliographies[id2]["data"]["abstract"])

          Rails.logger.debug("id1: " + id1)
          Rails.logger.debug("abst: " + words1.to_s)
          Rails.logger.debug("id2: " + id2)
          Rails.logger.debug("abst: " + words2.to_s)

          Rails.logger.debug("similarity: " + SimilarityCalculator.cosine_similarity(words1, words2).to_s)
          if SimilarityCalculator.cosine_similarity(words1, words2) >= threshold
            edge = UndirectedGraphEdge.new(id1, id2, 10, "#cccccc", {})
            graph.append_edge(edge)
            Rails.logger.debug(id1 + " " + id2 + " is connected")
          end
        end
        
      end
    end
    graph.set_cache
    return graph
  end
end
