# -*- coding: utf-8 -*-
require 'open3'

class CitationController < ApplicationController

  def citation
    render :json => get_citation(params[:cluster_id])
  end

  def citedby
    render :json => get_citedby(params[:cluster_id])
  end

  def bibliography
    render :json => get_bibliography(params[:cluster_id])
  end

  def abstract
    render :text => get_abstract(params[:cluster_id])
  end

  # # クエリを受け取り，google_scholar_crawler.pyを呼び出す
  # # TODO: これだけクエリ依存なので直すべき
  # def crawl(query)
  #   filepath = "#{ Rails.root.to_s }/lib/crawler/google_scholar_crawler.py"
  #   return Util.execute_command(filepath, query)
  # end

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
