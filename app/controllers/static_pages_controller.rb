# -*- coding: utf-8 -*-
require 'open3'
require 'json'

class StaticPagesController < ApplicationController
  def search
  end

  def result
    @text_field_val = params[:search_string] if params[:search_string] # フォームに入力された文字

    # クエリの正規化
    query = params[:search_string] # クエリ
    if query.strip! == ""
      return
    end
    query = query.gsub(/(\s|　)+/, "+")
    

    # google_scholar_crawler.pyを呼び出す
    command = Rails.root.to_s + "/lib/crawler/google_scholar_crawler.py " # コマンド
    command += query
    out, err, status = Open3.capture3(command) # 実行(outが結果の標準出力)

    # JSONの処理とグラフへの整形
    logger.debug(out)
    @articles = JSON.parse(out)

    @@graph = {nodes: {}, edges: {}}
    @articles.each do |article|
      cid = article["cluster_id"][0].to_s
      @@graph[:nodes][cid] = {}

      @@graph[:edges][cid] = {}
      citation = article["citation"][0]
      logger.debug(citation)
      citation.each do |cit|
        @@graph[:edges][cid][cid + "_" + cit["num"].to_s] = {directed: true, weight: 3}
      end
    end

  end

  def get_citation
    render :json => @@graph
  end
end


