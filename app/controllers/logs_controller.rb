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
    
    @rl.update_relevance(userid, interfaceid, query, rank, relevance)
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
end
