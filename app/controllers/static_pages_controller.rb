# -*- coding: utf-8 -*-
require 'open3'
require 'json'
require 'oj'

class StaticPagesController < ApplicationController
  def search
    (not params[:userid].nil?) ? @userid = params[:userid] : @userid = "anonymous" # ユーザID
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
    # @query = StringUtil.space_to_plus(params[:search_string])
    # gon.query = @query
    @query = params[:search_string]
    gon.query = @query
    
    # 検索結果の取得と整形
    @articles = crawl(@query)
    # logger.debug(@articles)

    rl = ResearchLogger.new
    rl.write_initial_log(@userid, @interface, @query, @articles)
  end

  # グラフを記述したJSONをJavaScript側に送る
  def graph
    @interface = params[:interface].to_i
    
    # クエリの正規化
    # @query = StringUtil.space_to_plus(params[:search_string])
    @query = params[:search_string]
    
    # 検索結果の取得と整形
    @articles = crawl(@query)
    logger.debug(@articles)

    # 1: 従来の検索エンジン，2: 類似度に基づいたグラフを付与，3: 引用関係に基づいたグラフを付与
    case @interface
    when 1
      render :json => Oj.dump({:nodes => {}, :edges => {}})
    when 2
      argc = AbstractRelevanceGraphComposer.new
      render :json => argc.compose_graph(@articles) # グラフを記述したJSONを呼び出す
    when 3
      cgc = CitationGraphComposer.new
      render :json => cgc.compose_graph(@articles)
    end

  end

  # ログを書き換える
  # TODO: ログを扱うコントローラを作るべき
  def change_relevance
    (not params[:userid].nil?) ? userid = params[:userid] : userid = "anonymous"
    interfaceid = params[:interfaceid].to_i
    query = StringUtil.space_to_plus(params[:search_string]) 
    rank = params[:rank]
    relevance = params[:relevance]
    
    rl = ResearchLogger.new
    render :text => rl.rewrite_log(userid, interfaceid, query, rank, relevance)        
  end

  private

  # クエリを受け取り，google_scholar_crawler.pyを呼び出す
  def crawl(query)
    mm = Mscrawler::MsacademicManager.new
    return mm.crawl(query, end_num: 5)
  end
end
