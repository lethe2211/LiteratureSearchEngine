# -*- coding: utf-8 -*-
require 'open3'
require 'json'
require 'jsoncache'

class StaticPagesController < ApplicationController
  def search
  end

  def result
    @text_field_val = params[:search_string] if params[:search_string] # フォームに入力された文字

    # クエリの正規化
    @query = params[:search_string] # クエリ
    if @query.strip! == ""
      return
    end
    @query = @query.gsub(/(\s|　)+/, "+")
    

    out = crawl(@query)

    # JSONの処理とグラフへの整形
    logger.debug(out)
    @articles = JSON.parse(out)

    shape_graph(@articles)

  end

  # グラフを記述したJSONをJavaScript側に送る
  def send_graph
    render :json => @@graph
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

  def shape_graph(articles)
    graph_cache = JsonCache.new(dir: "../../lib/crawler/graph/")

    cache = graph_cache.get(@query)
    logger.debug(cache.nil?)

    if (not cache.nil?) and cache["status"] == 'OK'
      @@graph = cache["data"]
    else
      result = {status: '', data: {nodes: {}, edges: {}}}

      articles.each do |article|
        cid = article["cluster_id"][0].to_s
        result[:data][:nodes][cid] = {weight: article["num_citations"][0], title: article["title"][0], year: article["year"][0]}

        result[:data][:edges][cid] = {}

        # 引用論文
        logger.debug(cid)
        citations = JSON.parse(get_citation(cid.to_i))
        logger.debug(citations)
        citations.each do |cit|
          bib = JSON.parse(get_bibliography(cit.to_i))

          threshold = 20
          if bib["num_citations"][0] > threshold
            result[:data][:nodes][cit] = {weight: bib["num_citations"][0], title: bib["title"][0], year: bib["year"][0]}
            result[:data][:edges][cid][cit] = {directed: true, weight: 10, color: "#cccccc"}
          end

        end

        # 被引用論文
        logger.debug(cid)
        citedbyes = JSON.parse(get_citedby(cid.to_i))
        logger.debug(citedbyes)
        citedbyes.each do |cit|
          bib = JSON.parse(get_bibliography(cit.to_i))

          threshold = 20
          if bib["num_citations"][0] > threshold
            result[:data][:nodes][cit] = {weight: bib["num_citations"][0], title: bib["title"][0], year: bib["year"][0]}
            if result[:data][:edges].has_key?(cit) == false
               result[:data][:edges][cit] = {}
            end 
            result[:data][:edges][cit][cid] = {directed: true, weight: 10, color: "#888888"}
          end

        end

      end

      if result[:data][:nodes] != {} and result[:data][:edges] != {}
        result[:status] = "OK"
        graph_cache.set(@query, result)
      else
        result[:status] = "NG"
      end

      @@graph = result[:data]
      logger.debug(@@graph)
    end 
    
  end

end


