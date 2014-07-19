# -*- coding: utf-8 -*-
require 'open3'
require 'json'
require 'jsoncache'

class StaticPagesController < ApplicationController
  def search
    @interface = params[:interface].to_i # インタフェースの番号(1: 従来の検索エンジン，2: 提案手法)
    gon.interface = @interface
  end

  def result
    @interface = params[:interface].to_i
    gon.interface = @interface

    @text_field_val = params[:search_string] if params[:search_string] # フォームに入力された文字

    # クエリの正規化
    @query = params[:search_string] # クエリ
    if @query.strip! == ""
      return
    end
    @query = @query.gsub(/(\s|　)+/, "+")
    
    out = crawl(@query)
    logger.debug(out)

    # JSONの処理とグラフへの整形    
    @articles = JSON.parse(out)

    if @interface == 2
      gon.graph = shape_graph(@articles) # グラフを記述したJSONをJavaScript側の"gon.graph"に送る
    end

    
  end

  # グラフを記述したJSONをJavaScript側に送る
  # def send_graph
  #   # render :json => @@graph
  # end

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
    command = Rails.root.to_s + "/lib/crawler/google_scholar_citation.py " 
    command += cluster_id.to_s
    out, err, status = Open3.capture3(command)

    return out
  end

  # Cluster_idを受け取り，google_scholar_citedby.pyを呼び出して被引用論文のcluster_idを返す  
  def get_citedby(cluster_id)
    command = Rails.root.to_s + "/lib/crawler/google_scholar_citedby.py " 
    command += cluster_id.to_s
    out, err, status = Open3.capture3(command)

    return out
  end

  # Cluster_idを受け取り，google_scholar_bibliography.pyを呼び出して書誌情報を返す  
  def get_bibliography(cluster_id)
    command = Rails.root.to_s + "/lib/crawler/google_scholar_bibliography.py " 
    command += cluster_id.to_s
    out, err, status = Open3.capture3(command)

    return out
  end

  # グラフを生成
  def shape_graph(articles)
    graph_cache = JsonCache.new(dir: "../../lib/crawler/graph/")

    cache = graph_cache.get(@query)
    logger.debug(cache.nil?)

    if (not cache.nil?) and cache["status"] == 'OK'
      return cache["data"]
    else
      result = {}

      graph_json = {nodes: {}, edges: {}} # グラフ
      citations = {} # 論文のCluster_idをキーとして，引用論文の配列を値として持つハッシュ
      citedbyes = {} # 論文のCluster_idをキーとして，被引用論文の配列を値として持つハッシュ

      articles.each do |article|
        cid = article["cluster_id"][0].to_s

        # 引用論文
        logger.debug("citation: " + cid)
        citation = get_citation(cid.to_i)
        citations[cid] = citation.blank? ? [] : JSON.parse(citation)
        logger.debug(citations[cid])
        
        # 被引用論文
        logger.debug("citedby: " + cid)
        citedby = get_citedby(cid.to_i)
        citedbyes[cid] = citedby.blank? ? [] : JSON.parse(citedby)
        logger.debug(citedbyes[cid])
        
      end

      logger.debug(citations)
      logger.debug(citedbyes)

      used_cids = [] # ループ中ですでに1度呼ばれた論文
      used_result_cids = [] # ループ中ですでに1度呼ばれた検索結果論文

      # 任意の一対の検索結果論文について
      articles.each do |article1|
        cid1 = article1["cluster_id"][0].to_s
        articles.each do |article2|
          cid2 = article2["cluster_id"][0].to_s
          if cid1.to_i >= cid2.to_i
            next
          end

          logger.debug("cid1: " + cid1)
          logger.debug("cid2: " + cid2)
          logger.debug("")

          # 論文ノードの初期化
          unless used_result_cids.include?(cid1)
            graph_json[:nodes][cid1] = {type: "search_result", weight: article1["num_citations"][0], title: article1["title"][0], year: article1["year"][0], color: "#dd3333", rank: article1["rank"][0]}
            used_result_cids.push(cid1)
            unless used_cids.include?(cid1)
              graph_json[:edges][cid1] = {}
              used_cids.push(cid1)
            end
          end

          unless used_result_cids.include?(cid2)
            graph_json[:nodes][cid2] = {type: "search_result", weight: article2["num_citations"][0], title: article2["title"][0], year: article2["year"][0], color: "#dd3333", rank: article2["rank"][0]}
            used_result_cids.push(cid2)
            unless used_cids.include?(cid2)
              graph_json[:edges][cid2] = {}
              used_cids.push(cid2)
            end
          end

          # 両方が(共)引用する論文
          (citations[cid1] & citations[cid2]).each do |cit|
            bib = JSON.parse(get_bibliography(cit.to_i))
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["num_citations"][0], title: bib["title"][0], year: bib["year"][0], color: "#cccccc"}
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            logger.debug("citation of cid1 and cid2: " + cit)
            graph_json[:edges][cid1][cit] = {directed: true, weight: 10, color: "#cccccc"}
            graph_json[:edges][cid2][cit] = {directed: true, weight: 10, color: "#cccccc"}
          end

          # 片方が引用し，もう片方が被引用する論文
          (citations[cid1] & citedbyes[cid2]).each do |cit|
            bib = JSON.parse(get_bibliography(cit.to_i))
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["num_citations"][0], title: bib["title"][0], year: bib["year"][0], color: "#cccccc"} 
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            logger.debug("citation of cid1 and cited by cid2: " + cit)
            graph_json[:edges][cid1][cit] = {directed: true, weight: 10, color: "#cccccc"}
            graph_json[:edges][cit][cid2] = {directed: true, weight: 10, color: "#888888"}
          end

          # 片方が被引用し，もう片方が引用する論文
          (citedbyes[cid1] & citations[cid2]).each do |cit|
            bib = JSON.parse(get_bibliography(cit.to_i))
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["num_citations"][0], title: bib["title"][0], year: bib["year"][0], color: "#cccccc"} 
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            logger.debug("cited by cid1 and citation of cid2: " + cit)
            graph_json[:edges][cit][cid1] = {directed: true, weight: 10, color: "#888888"}
            graph_json[:edges][cid2][cit] = {directed: true, weight: 10, color: "#cccccc"}
          end 

          # 両方が被引用される論文
          (citedbyes[cid1] & citedbyes[cid2]).each do |cit|
            bib = JSON.parse(get_bibliography(cit.to_i))
            unless used_cids.include?(cit)
              graph_json[:nodes][cit] = {type: "normal", weight: bib["num_citations"][0], title: bib["title"][0], year: bib["year"][0], color: "#cccccc"} 
              graph_json[:edges][cit] = {} 
              used_cids.push(cit)
            end
            logger.debug("cited by cid1 and cid2: " + cit)
            graph_json[:edges][cit][cid1] = {directed: true, weight: 10, color: "#888888"}
            graph_json[:edges][cit][cid2] = {directed: true, weight: 10, color: "#888888"}
          end

          # cid1の論文がcid2の論文を引用している
          if (citedbyes[cid2]).include?(cid1) or (citations[cid1]).include?(cid2)
            graph_json[:edges][cid1][cid2] = {directed: true, weight: 10, color: "#333333"}
          end

          # cid2の論文がcid1の論文を引用している
          if (citations[cid2]).include?(cid1) or (citedbyes[cid1]).include?(cid2)
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
