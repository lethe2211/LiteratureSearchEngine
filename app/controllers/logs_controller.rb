# -*- coding: utf-8 -*-

class LogsController < ApplicationController
  def initialize
    @rl = ResearchLogger.new
  end

  # ページのロードがすべて終了した時
  def page_loaded
    userid = params[:userid]
    interfaceid = params[:interface]
    query = params[:search_string]

    @rl.add_access(userid, interfaceid, query, 'page_loaded')
    render :text => 'OK'
  end

  # 適合性のログを変更する時
  def update_relevance
    userid = params[:userid]
    interfaceid = params[:interface]
    query = params[:search_string]
    rank = params[:rank]
    relevance = params[:relevance]
    
    @rl.update_relevance(userid, interfaceid, query, rank, relevance, options: {} )
    render :text => 'OK'
  end

  # 論文リンクを辿る時
  def read_paper
    userid = params[:userid]
    interfaceid = params[:interface]
    query = params[:search_string]
    rank = params[:rank]
    literature_id = params[:literature_id]
    @rl.add_access(userid, interfaceid, query, 'read_paper', options: { 'rank' => rank, 'literature_id' => literature_id })
    render :text => 'OK'
  end

  def reload_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    @rl.add_event(userid, interfaceid, 'reload_countdown')
    render :text => 'OK'
  end

  def load_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    @rl.add_event(userid, interfaceid, 'load_countdown')
    render :text => 'OK'
  end

  def start_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    @rl.add_event(userid, interfaceid, 'start_countdown')
    render :text => 'OK'
  end

  def pause_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    @rl.add_event(userid, interfaceid, 'pause_countdown')
    render :text => 'OK'
  end

  def resume_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    @rl.add_event(userid, interfaceid, 'resume_countdown')
    render :text => 'OK'
  end

  def expire_countdown
    userid = params[:userid]
    interfaceid = params[:interface]
    @rl.add_event(userid, interfaceid, 'expire_countdown')
    render :text => 'OK'
  end
end
