# -*- coding: utf-8 -*-

class CitationGraphComposer
  def initialize
  end

  def compose_graph(articles)
    graph_cache = JsonCache.new(dir: "./crawler/graph/")

    cache = graph_cache.get(@query)

    if (not cache.nil?) and cache["status"] == 'OK'
      return cache["data"]
    else
      result = {}

      graph_json = {nodes: {}, edges: {}} # グラフ
      bibliographies = {}
      citations = {} # 論文のCluster_idをキーとして，引用論文の配列を値として持つハッシュ
      citedbyes = {} # 論文のCluster_idをキーとして，被引用論文の配列を値として持つハッシュ
      Rails.logger.debug(articles)

      search_results = articles["data"]["search_results"]

      search_results.each do |search_result|
        cid = search_result["cluster_id"].to_s

        bib = get_bibliography(cid.to_i)
        # bibliographies[cid] = bib.blank? ? {'status' => 'NG', 'data' => {}} : JSON.parse(bib)
        bibliographies[cid] = bib.blank? ? {'status' => 'NG', 'data' => {}} : Oj.load(bib)

        # 引用論文
        Rails.logger.debug("citation: " + cid)
        citation = get_citation(cid.to_i)
        # citations[cid] = citation.blank? ? {'status' => 'NG', 'data' => []} : JSON.parse(citation)
        citations[cid] = citation.blank? ? {'status' => 'NG', 'data' => []} : Oj.load(citation)
        Rails.logger.debug(citations[cid])
        
        # 被引用論文
        Rails.logger.debug("citedby: " + cid)
        citedby = get_citedby(cid.to_i)
        # citedbyes[cid] = citedby.blank? ? {'status' => 'NG', 'data' => []} : JSON.parse(citedby)
        citedbyes[cid] = citedby.blank? ? {'status' => 'NG', 'data' => []} : Oj.load(citedby)
        Rails.logger.debug(citedbyes[cid])
        
      end

      Rails.logger.debug(citations)
      Rails.logger.debug(citedbyes)

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

          Rails.logger.debug("cid1: " + cid1)
          Rails.logger.debug("cid2: " + cid2)
          Rails.logger.debug("")

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

          Rails.logger.debug((citations[cid1]["data"] & citations[cid2]["data"]).to_s)
          Rails.logger.debug((citations[cid1]["data"] & citedbyes[cid2]["data"]).to_s)
          Rails.logger.debug((citedbyes[cid1]["data"] & citations[cid2]["data"]).to_s)
          Rails.logger.debug((citedbyes[cid1]["data"] & citedbyes[cid2]["data"]).to_s)

          # 両方が(共)引用する論文
          (citations[cid1]["data"] & citations[cid2]["data"]).each do |cit|
            b = get_bibliography(cit.to_i)
            # bib = b.blank? ? {} : JSON.parse(b)
            bib = b.blank? ? {'status' => 'NG', 'data' => {}} : Oj.load(b)
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            Rails.logger.debug("citation of cid1 and cid2: " + cit)
            graph_json[:edges][cid1][cit] = {directed: true, weight: 10, color: "#cccccc"}
            graph_json[:edges][cid2][cit] = {directed: true, weight: 10, color: "#cccccc"}
          end

          # 片方が引用し，もう片方が被引用する論文
          (citations[cid1]["data"] & citedbyes[cid2]["data"]).each do |cit|
            b = get_bibliography(cit.to_i)
            # bib = b.blank? ? {} : JSON.parse(b)
            bib = b.blank? ? {'status' => 'NG', 'data' => {}} : Oj.load(b)
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            Rails.logger.debug("citation of cid1 and cited by cid2: " + cit)
            graph_json[:edges][cid1][cit] = {directed: true, weight: 10, color: "#cccccc"}
            graph_json[:edges][cit][cid2] = {directed: true, weight: 10, color: "#888888"}
          end

          # 片方が被引用し，もう片方が引用する論文
          (citedbyes[cid1]["data"] & citations[cid2]["data"]).each do |cit|
            b = get_bibliography(cit.to_i)
            # bib = b.blank? ? {} : JSON.parse(b)
            bib = b.blank? ? {'status' => 'NG', 'data' => {}} : Oj.load(b)
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            Rails.logger.debug("cited by cid1 and citation of cid2: " + cit)
            graph_json[:edges][cit][cid1] = {directed: true, weight: 10, color: "#888888"}
            graph_json[:edges][cid2][cit] = {directed: true, weight: 10, color: "#cccccc"}
          end 

          # 両方が被引用される論文
          (citedbyes[cid1]["data"] & citedbyes[cid2]["data"]).each do |cit|
            b = get_bibliography(cit.to_i)
            # bib = b.blank? ? {} : JSON.parse(b)
            bib = b.blank? ? {'status' => 'NG', 'data' => {}} : Oj.load(b)
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            Rails.logger.debug("cited by cid1 and cid2: " + cit)
            graph_json[:edges][cit][cid1] = {directed: true, weight: 10, color: "#888888"}
            graph_json[:edges][cit][cid2] = {directed: true, weight: 10, color: "#888888"}
          end

          # cid1の論文がcid2の論文を引用している
          if (citedbyes[cid2]["data"]).include?(cid1) or (citations[cid1]["data"]).include?(cid2)
            graph_json[:edges][cid1][cid2] = {directed: true, weight: 10, color: "#333333"}
          end

          # cid2の論文がcid1の論文を引用している
          if (citations[cid2]["data"]).include?(cid1) or (citedbyes[cid1]["data"]).include?(cid2)
            graph_json[:edges][cid2][cid1] = {directed: true, weight: 10, color: "#333333"}
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
