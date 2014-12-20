# -*- coding: utf-8 -*-
require 'open3'
require 'json'
require 'oj'
require 'uri'

class StaticPagesController < ApplicationController
  def search
    gon.clear
    (not params[:userid].nil?) ? @userid = params[:userid] : @userid = "anonymous" # ユーザID
    gon.userid = @userid
    @interface = params[:interface].to_i # インタフェースの番号
    gon.interface = @interface
    gon.action = "search"

    rl = ResearchLogger.new
    rl.start_task(@userid, @interface)
    rl.add_event(@userid, @interface, 'search')
  end

  def result
    gon.clear
    (not params[:userid].nil?) ? @userid = params[:userid] : @userid = "anonymous"
    gon.userid = @userid
    @interface = params[:interface].to_i
    gon.interface = @interface
    gon.action = "result"
    @start_num = params.key?(:start_num) ? params[:start_num].to_i : 1
    @end_num = params.key?(:end_num) ? params[:end_num].to_i : 10
    # gon.watch.start_num = @start_num
    # gon.watch.end_num = @end_num
    @text_field_val = params[:search_string] if params[:search_string] # フォームに入力された文字

    # クエリの正規化
    @query = params[:search_string]
    gon.query = @query
    
    # 検索結果の取得と整形
    @articles = crawl(@query)

    # 閲覧する検索結果を変えるためのリンクのURLを求める
    @links_to_other_search_results = links_to_other_search_results

    # ログ取得
    rl = ResearchLogger.new
    rl.write_initial_log(@userid, @interface, @query, @articles)

    rl.start_task(@userid, @interface)
    rl.add_session(@userid, @interface, @query)
    rl.add_access(@userid, @interface, @query, 'result')
    rl.initialize_relevances(@userid, @interface, @query, @articles)
  end

  # グラフを記述したJSONをJavaScript側に送る
  def graph
    @interface = params[:interface].to_i
    # start_num = params.key?(:start_num) ? params[:start_num].to_i : 1
    # end_num = params.key?(:end_num) ? params[:end_num].to_i : 10
    start_num = params[:start_num].to_i if params.key?(:start_num)
    end_num = params[:end_num].to_i  if params.key?(:end_num)
    # parameters = URI::parse(request.url).query
    # array = URI.decode_www_form(parameters)
    # q = Hash[*array.flatten]
    # start_num = q['start_num'].to_i
    # end_num = q['end_num'].to_i

    # クエリの正規化
    # @query = StringUtil.space_to_plus(params[:search_string])
    @query = params[:search_string]
    
    # 検索結果の取得と整形
    @articles = crawl(@query)
    Rails.logger.debug(@articles)

    # 1: 従来の検索エンジン，2: 類似度に基づいたグラフを付与，3: 引用関係に基づいたグラフを付与
    case @interface
    when 1
      render :json => Oj.dump({:nodes => {}, :edges => {}})
    when 2
      argc = AbstractRelevanceGraphComposer.new
      render :json => argc.compose_graph(@articles) # グラフを記述したJSONを呼び出す
    when 3
      cgc = CitationGraphComposer.new
      render :json => cgc.compose_graph(@articles, start_num: start_num, end_num: end_num)
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
    # rl.update_relevance(rank, relevance)
    render :text => rl.rewrite_log(userid, interfaceid, query, rank, relevance)        
  end

  private

  # クエリを受け取り，検索結果を返す
  def crawl(query)
    mm = Mscrawler::MsacademicManager.new
    search_results = mm.crawl(query, end_num: 100)
    @max_num = search_results['data']['num']
    return search_results
  end

  def links_to_other_search_results
    current_url = request.url
    links = []
    10.times do |i|
      uri = URI::parse(current_url)
      array = URI.decode_www_form(uri.query)
      q = Hash[*array.flatten]
      q['start_num'] = 10 * i + 1
      q['end_num'] = 10 * i + 10
      q.delete('utf8')
      q.delete('commit')
      uri.query = URI.encode_www_form(q)
      links.push(uri.to_s)
    end
    return links
  end
end
