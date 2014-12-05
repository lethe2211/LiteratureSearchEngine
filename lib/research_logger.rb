# -*- coding: utf-8 -*-
require 'open-uri'
require 'crawl_controller'

=begin
実験用に，適合・非適合のログを取るためのクラス
=end
class ResearchLogger
  def initialize
  end

  # クエリ入力に応じて，検索結果についてのログを書き込む
  def write_initial_log(userid, interfaceid, query, articles)
    # バルクインサート
    logs = []
    articles["data"]["search_results"].each_with_index do |article, index|
      logs << Log.new(userid: userid, interfaceid: interfaceid, query: query, rank: index + 1, relevance: "none")
    end
    Log.import logs
  end

  # ボタンからの入力に応じて，ログのrelevanceを書き換える
  def rewrite_log(userid, interfaceid, query, rank, relevance)
    log = Log.where(userid: userid, interfaceid: interfaceid, query: query, rank: rank).order(created_at: :desc).first
    log.update(relevance: relevance)
    return true
  end

  # 論文の閲覧情報のログを書き込む
  def write_read_paper_log(userid, interfaceid, query, rank) 
    log = Log.new(userid: userid, interfaceid: interfaceid, query: query, rank: rank)
    log.save
  end

  def add_session(userid, interfaceid, query)
    session = Session.new(userid: userid, interfaceid: interfaceid, query: query)
    session.save
  end

  def add_access(type)
    session = Session.last
    session_id = session.id

    access = Access.new(session_id: session_id, access_type: type)
    access.save
  end

  def initialize_relevances
    session = Session.last
    session_id = session.id
    if Relevance.where(session_id: session_id, rank: 1).empty?
      relevances = []
      for i in 1..10
        relevances.push(Relevance.new(session_id: session_id, rank: i, relevance: 'none'))
      end
      Relevance.import relevances
    end
  end

  def update_relevance(rank, relev)
    session = Session.last
    session_id = session.id
    relevance = Relevance.where(session_id: session_id, rank: rank).last
    relevance.update(relevance: relev)
  end
end
