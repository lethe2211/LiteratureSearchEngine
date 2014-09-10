# -*- coding: utf-8 -*-

class AbstractRelevanceGraphComposer
  def initialize
  end

  # アブストラクトの類似度に応じたグラフを作成
  def compose_graph(articles)
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
        bib = get_bibliography(cid.to_i)
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

  # クエリを受け取り，google_scholar_crawler.pyを呼び出す
  def crawl(query)
    command = Rails.root.to_s + "/lib/crawler/google_scholar_crawler.py " # コマンド
    command += query
    out, err, status = Open3.capture3(command) # 実行(outが結果の標準出力)

    return out
  end

  # Cluster_idを受け取り，google_scholar_citation.pyを呼び出して引用論文のcluster_idを返す  
  def get_citation(cluster_id)
    filepath = "#{ Rails.root.to_s }/lib/crawler/google_scholar_citation.py"
    return Util.execute_command(filepath, cluster_id)
  end

  # Cluster_idを受け取り，google_scholar_citedby.pyを呼び出して被引用論文のcluster_idを返す  
  def get_citedby(cluster_id)
    filepath = "#{ Rails.root.to_s }/lib/crawler/google_scholar_citedby.py"
    return Util.execute_command(filepath, cluster_id)
  end

  # Cluster_idを受け取り，google_scholar_bibliography.pyを呼び出して書誌情報を返す  
  def get_bibliography(cluster_id)
    filepath = "#{ Rails.root.to_s }/lib/crawler/google_scholar_bibliography.py"
    return Util.execute_command(filepath, cluster_id)
  end

  # Cluster_idを受け取り，google_scholar_abstract.pyを呼び出してアブストラクトを返す  
  def get_abstract(cluster_id)
    filepath = "#{ Rails.root.to_s }/lib/crawler/google_scholar_abstract.py"
    return Util.execute_command(filepath, cluster_id)
  end
end
