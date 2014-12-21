# -*- coding: utf-8 -*-

class LogsController < ApplicationController
  def initialize
    @rl = ResearchLogger.new
    @experiment_seconds = 3600
  end

  # accessesに関するログ

  # ページのロードがすべて終了した時
  def page_loaded
    userid = params[:userid]
    interfaceid = params[:interface]
    query = params[:search_string]
    start_num = params[:start_num]
    end_num = params[:end_num]
    elapsed_time = params[:elapsed_time].to_i

    @rl.add_access(userid, interfaceid, query, start_num, end_num, 'page_loaded', elapsed_time)
    render :text => 'OK'
  end

  # 適合性のログを変更する時
  def update_relevance
    userid = params[:userid]
    interfaceid = params[:interface]
    query = params[:search_string]
    start_num = params[:start_num]
    end_num = params[:end_num]
    rank = params[:rank]
    relevance = params[:relevance]
    
    @rl.update_relevance(userid, interfaceid, query, start_num, end_num, rank, relevance, options: {} )
    render :text => 'OK'
  end

  # 論文リンクを辿る時
  def read_paper
    userid = params[:userid]
    interfaceid = params[:interface]
    query = params[:search_string]
    start_num = params[:start_num]
    end_num = params[:end_num]
    rank = params[:rank]
    literature_id = params[:literature_id]
    elapsed_time = params[:elapsed_time]

    @rl.add_access(userid, interfaceid, query, start_num, end_num, 'read_paper', elapsed_time, options: { 'rank' => rank, 'literature_id' => literature_id })
    render :text => 'OK'
  end

  # グラフの読み込みに失敗した時
  def graph_load_failed
    userid = params[:userid]
    interfaceid = params[:interface]
    query = params[:search_string]
    start_num = params[:start_num]
    end_num = params[:end_num]
    elapsed_time = params[:elapsed_time]

    @rl.add_access(userid, interfaceid, query, start_num, end_num, 'graph_load_failed', elapsed_time, options: {})
    render :text => 'OK'
  end
  # eventsに関するログ

  def reload_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    elapsed_time = params[:elapsed_time]
    @rl.add_event(userid, interfaceid, 'reload_countdown', elapsed_time)
    render :text => 'OK'
  end

  def load_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    elapsed_time = params[:elapsed_time]
    @rl.add_event(userid, interfaceid, 'load_countdown', elapsed_time)
    render :text => 'OK'
  end

  def start_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    elapsed_time = params[:elapsed_time]
    @rl.add_event(userid, interfaceid, 'start_countdown', elapsed_time)
    render :text => 'OK'
  end

  def pause_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    elapsed_time = params[:elapsed_time]
    @rl.add_event(userid, interfaceid, 'pause_countdown', elapsed_time)
    render :text => 'OK'
  end

  def resume_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    elapsed_time = params[:elapsed_time]
    @rl.add_event(userid, interfaceid, 'resume_countdown', elapsed_time)
    render :text => 'OK'
  end

  def expire_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    elapsed_time = params[:elapsed_time]
    @rl.add_event(userid, interfaceid, 'expire_countdown', elapsed_time)
    render :text => 'OK'
  end
end
