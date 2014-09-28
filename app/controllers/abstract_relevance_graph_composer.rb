# -*- coding: utf-8 -*-

require 'citation_controller'

class AbstractRelevanceGraphComposer
  def initialize
    @mm = Mscrawler::MsacademicManager.new
  end

  # アブストラクトの類似度に応じたグラフを作成
  def compose_graph_(articles)
    graph_cache = JsonCache.new(dir: "../lib/crawler/graph/", prefix: "cache_relevance_")
    
    @query = articles["data"]["query"]
    cache = graph_cache.get(@query)

    if (not cache.nil?) and cache["status"] == 'OK'
      return cache["data"]
    else
      result = {}               
      #abstrg = Graph.new
      graph_json = {nodes: {}, edges: {}}
      bibliographies = {}
      
      search_results = articles["data"]["search_results"]
      search_results.each do |search_result|
        cid  = search_result["cluster_id"].to_s
        Rails.logger.debug("abstract: " + cid)
        bib = CitationController.get_bibliography(cid.to_i)
        bibliographies[cid] = bib.blank? ? [] : Oj.load(bib)
      end

      Rails.logger.debug(bibliographies)

      used_cids = [] # ループ中ですでに1度呼ばれた論文
      used_result_cids = [] # ループ中ですでに1度呼ばれた検索結果論文

      threshold = 0.2           # 類似度のしきい値

      # 任意の一対の検索結果論文について
      search_results.each do |search_result1|
        cid1 = search_result1["cluster_id"].to_s
        search_results.each do |search_result2|
          cid2 = search_result2["cluster_id"].to_s
          if cid1.to_i >= cid2.to_i
            next
          end

          # 論文ノードの初期化
          unless used_result_cids.include?(cid1)
            graph_json[:nodes][cid1] = {type: "search_result", weight: bibliographies[cid1]["data"]["num_citations"], title: search_result1["title"], year: bibliographies[cid1]["data"]["year"], color: "#dd3333", rank: search_result1["rank"]}
            used_result_cids.push(cid1)
            unless used_cids.include?(cid1)
              graph_json[:edges][cid1] = {}
              used_cids.push(cid1)
            end
          end

          unless used_result_cids.include?(cid2)
            graph_json[:nodes][cid2] = {type: "search_result", weight: bibliographies[cid2]["data"]["num_citations"], title: search_result2["title"], year: bibliographies[cid2]["data"]["year"], color: "#dd3333", rank: search_result2["rank"]}
            used_result_cids.push(cid2)
            unless used_cids.include?(cid2)
              graph_json[:edges][cid2] = {}
              used_cids.push(cid2)
            end
          end

          if bibliographies[cid1]["data"]["abstract"] and bibliographies[cid2]["data"]["abstract"]
            words1 = StringUtil.count_frequency(bibliographies[cid1]["data"]["abstract"])
            words2 = StringUtil.count_frequency(bibliographies[cid2]["data"]["abstract"])

            Rails.logger.debug("cid1: " + cid1)
            Rails.logger.debug("abst: " + words1.to_s)
            Rails.logger.debug("cid2: " + cid2)
            Rails.logger.debug("abst: " + words2.to_s)

            Rails.logger.debug("similarity: " + SimilarityCalculator.cosine_similarity(words1, words2).to_s)
            if SimilarityCalculator.cosine_similarity(words1, words2) >= threshold
              graph_json[:edges][cid1][cid2] = {directed: false, weight: 10, color: "#333333"}
              Rails.logger.debug(cid1 + " " + cid2 + " is connected")
            end
          end
          
        end
      end

      if graph_json[:nodes] != {} and graph_json[:edges] != {}
        result[:data] = graph_json
        result[:status] = "OK"
        graph_cache.set(@query, result)
      else
        result[:status] = "NG"
      end

      Rails.logger.debug(result[:data])
      return result[:data]
    end
  end

  # アブストラクトの類似度に応じたグラフを作成
  def compose_graph(articles)
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
      cid  = search_result["cluster_id"].to_s
      Rails.logger.debug("abstract: " + cid)
      bib = CitationController.get_bibliography(cid.to_i)
      bibliographies[cid] = bib.blank? ? [] : Oj.load(bib)
    end

    Rails.logger.debug(bibliographies)
    return bibliographies
  end

  def compute_graph(search_results, bibliographies, threshold)
    graph = Graph.new

    used_cids = [] # ループ中ですでに1度呼ばれた論文
    used_result_cids = [] # ループ中ですでに1度呼ばれた検索結果論文

    # 任意の一対の検索結果論文について
    search_results.each do |search_result1|
      cid1 = search_result1["cluster_id"].to_s
      search_results.each do |search_result2|
        cid2 = search_result2["cluster_id"].to_s
        if cid1.to_i >= cid2.to_i
          next
        end

        # 論文ノードの初期化
        unless used_result_cids.include?(cid1)
          # graph_json[:nodes][cid1] = {type: "search_result", weight: bibliographies[cid1]["data"]["num_citations"], title: search_result1["title"], year: bibliographies[cid1]["data"]["year"], color: "#dd3333", rank: search_result1["rank"]}
          search_result_node = SearchResultGraphNode.new(cid1, bibliographies[cid1]["data"]["num_citations"], bibliographies[cid1], search_result1["rank"])            
          graph.append_node(search_result_node)
          used_result_cids.push(cid1)
          unless used_cids.include?(cid1)
            # graph_json[:edges][cid1] = {}
            used_cids.push(cid1)
          end
        end

        unless used_result_cids.include?(cid2)
          # graph_json[:nodes][cid2] = {type: "search_result", weight: bibliographies[cid2]["data"]["num_citations"], title: search_result2["title"], year: bibliographies[cid2]["data"]["year"], color: "#dd3333", rank: search_result2["rank"]}
          search_result_node = SearchResultGraphNode.new(cid2, bibliographies[cid2]["data"]["num_citations"], bibliographies[cid2], search_result2["rank"])            
          graph.append_node(search_result_node)
          used_result_cids.push(cid2)
          unless used_cids.include?(cid2)
            # graph_json[:edges][cid2] = {}
            used_cids.push(cid2)
          end
        end

        if bibliographies[cid1]["data"]["abstract"] and bibliographies[cid2]["data"]["abstract"]
          words1 = StringUtil.count_frequency(bibliographies[cid1]["data"]["abstract"])
          words2 = StringUtil.count_frequency(bibliographies[cid2]["data"]["abstract"])

          Rails.logger.debug("cid1: " + cid1)
          Rails.logger.debug("abst: " + words1.to_s)
          Rails.logger.debug("cid2: " + cid2)
          Rails.logger.debug("abst: " + words2.to_s)

          Rails.logger.debug("similarity: " + SimilarityCalculator.cosine_similarity(words1, words2).to_s)
          if SimilarityCalculator.cosine_similarity(words1, words2) >= threshold
            # graph_json[:edges][cid1][cid2] = {directed: false, weight: 10, color: "#333333"}
            edge = UndirectedGraphEdge.new(cid1, cid2, 10, "#cccccc", {})
            graph.append_edge(edge)
            Rails.logger.debug(cid1 + " " + cid2 + " is connected")
          end
        end
        
      end
    end

    return graph
  end
end
