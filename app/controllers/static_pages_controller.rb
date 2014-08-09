# -*- coding: utf-8 -*-
require 'open3'
require 'json'
require 'jsoncache'             # FIXME: autoloadしてるはずなのに外すと動かない
require 'similarity_calculator'
require 'research_logger'

class StaticPagesController < ApplicationController
  def search
    (not params[:userid].nil?) ? @userid = params[:userid] : @userid = "anonymous"
    gon.userid = @userid
    @interface = params[:interface].to_i # インタフェースの番号
    gon.interface = @interface
    gon.action = "search"
  end

  def result
    (not params[:userid].nil?) ? @userid = params[:userid] : @userid = "anonymous"
    gon.userid = @userid
    @interface = params[:interface].to_i
    gon.interface = @interface
    gon.action = "result"

    @text_field_val = params[:search_string] if params[:search_string] # フォームに入力された文字

    # クエリの正規化
    @query = params[:search_string] # クエリ
    if @query.strip! == ""
      return
    end
    @query = @query.gsub(/(\s|　)+/, "+")
    gon.query = @query
    
    # 検索結果の取得と整形
    out = crawl(@query)
    @articles = JSON.parse(out)
    logger.debug(@articles)

    rl = ResearchLogger.new
    rl.write_initial_log(@userid, @interface, @query)
    
  end

  # グラフを記述したJSONをJavaScript側に送る
  def graph
    @interface = params[:interface].to_i
    
    # クエリの正規化
    @query = params[:search_string] # クエリ
    @query = @query.gsub(/(\s|　)+/, "+")
    
    # 検索結果の取得と整形
    out = crawl(@query)
    logger.debug(out)
    @articles = JSON.parse(out) 

    # 1: 従来の検索エンジン，2: 類似度に基づいたグラフを付与，3: 引用関係に基づいたグラフを付与
    if @interface == 1
      render :json => JSON.dump({:nodes => {}, :edges => {}})
    elsif @interface == 2
      render :json => shape_graph_with_relevance(@articles) # グラフを記述したJSONを呼び出す
    elsif @interface == 3
      render :json => shape_graph(@articles)
    end

  end

  # ログを書き換える
  # TODO: ログを扱うコントローラを作るべき
  def change_relevance
    (not params[:userid].nil?) ? userid = params[:userid] : userid = "anonymous"
    interfaceid = params[:interfaceid].to_i
    query = params[:search_string] 
    query = query.gsub(/(\s|　)+/, "+")
    rank = params[:rank]
    relevance = params[:relevance]
    
    rl = ResearchLogger.new
    render :text => rl.rewrite_log(userid, interfaceid, query, rank, relevance)
        
  end

  private
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

  # アブストラクトの類似度に応じたグラフを作成
  def shape_graph_with_relevance(articles)
    graph_cache = JsonCache.new(dir: "./crawler/graph/", prefix: "cache_relevance_")
  
    cache = graph_cache.get(@query)

    if (not cache.nil?) and cache["status"] == 'OK'
      return cache["data"]
    else
      result = {}

      graph_json = {nodes: {}, edges: {}} # グラフ
      bibliographies = {}

      logger.debug(articles)
      
      search_results = articles["data"]["search_results"]

      search_results.each do |search_result|
        logger.debug(search_result)
        cid = search_result["cluster_id"].to_s

        logger.debug("abstract: " + cid)

        bib = get_bibliography(cid.to_i)
        bibliographies[cid] = bib.blank? ? [] : JSON.parse(bib)

      end

      logger.debug(bibliographies)

      used_cids = [] # ループ中ですでに1度呼ばれた論文
      used_result_cids = [] # ループ中ですでに1度呼ばれた検索結果論文

      threshold = 0.2

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
            su = StringUtil.new
            words1 = su.count_frequency(bibliographies[cid1]["data"]["abstract"])
            words2 = su.count_frequency(bibliographies[cid2]["data"]["abstract"])

            logger.debug(cid1)
            logger.debug(cid2)

            sc = SimCalculator.new
            logger.debug(sc.cosine_similarity(words1, words2))
            if sc.cosine_similarity(words1, words2) >= threshold
              graph_json[:edges][cid1][cid2] = {directed: false, weight: 10, color: "#333333"}
              logger.debug(cid1 + " " + cid2 + " is connected")
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

      logger.debug(result[:data])
      return result[:data]

    end

  end

  # グラフを生成
  def shape_graph(articles)
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
      logger.debug(articles)

      search_results = articles["data"]["search_results"]

      search_results.each do |search_result|
        cid = search_result["cluster_id"].to_s

        bib = get_bibliography(cid.to_i)
        bibliographies[cid] = bib.blank? ? {'status' => 'NG', 'data' => {}} : JSON.parse(bib)

        # 引用論文
        logger.debug("citation: " + cid)
        citation = get_citation(cid.to_i)
        citations[cid] = citation.blank? ? {'status' => 'NG', 'data' => []} : JSON.parse(citation)
        logger.debug(citations[cid])
        
        # 被引用論文
        logger.debug("citedby: " + cid)
        citedby = get_citedby(cid.to_i)
        citedbyes[cid] = citedby.blank? ? {'status' => 'NG', 'data' => []} : JSON.parse(citedby)
        logger.debug(citedbyes[cid])
        
      end

      logger.debug(citations)
      logger.debug(citedbyes)

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

          logger.debug("cid1: " + cid1)
          logger.debug("cid2: " + cid2)
          logger.debug("")

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

          # 両方が(共)引用する論文
          (citations[cid1]["data"] & citations[cid2]["data"]).each do |cit|
            b = get_bibliography(cit.to_i)
            bib = b.blank? ? {} : JSON.parse(b)
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            logger.debug("citation of cid1 and cid2: " + cit)
            graph_json[:edges][cid1][cit] = {directed: true, weight: 10, color: "#cccccc"}
            graph_json[:edges][cid2][cit] = {directed: true, weight: 10, color: "#cccccc"}
          end

          # 片方が引用し，もう片方が被引用する論文
          (citations[cid1]["data"] & citedbyes[cid2]["data"]).each do |cit|
            b = get_bibliography(cit.to_i)
            bib = b.blank? ? {} : JSON.parse(b)
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            logger.debug("citation of cid1 and cited by cid2: " + cit)
            graph_json[:edges][cid1][cit] = {directed: true, weight: 10, color: "#cccccc"}
            graph_json[:edges][cit][cid2] = {directed: true, weight: 10, color: "#888888"}
          end

          # 片方が被引用し，もう片方が引用する論文
          (citedbyes[cid1]["data"] & citations[cid2]["data"]).each do |cit|
            b = get_bibliography(cit.to_i)
            bib = b.blank? ? {} : JSON.parse(b)
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            logger.debug("cited by cid1 and citation of cid2: " + cit)
            graph_json[:edges][cit][cid1] = {directed: true, weight: 10, color: "#888888"}
            graph_json[:edges][cid2][cit] = {directed: true, weight: 10, color: "#cccccc"}
          end 

          # 両方が被引用される論文
          (citedbyes[cid1]["data"] & citedbyes[cid2]["data"]).each do |cit|
            logger.debug(cit)
            b = get_bibliography(cit.to_i)
            bib = b.blank? ? {} : JSON.parse(b)
            logger.debug(bib)
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            logger.debug("cited by cid1 and cid2: " + cit)
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

      logger.debug(result[:data])
      return result[:data]

    end   
    
  end

end
