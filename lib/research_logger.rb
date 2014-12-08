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

  # sessionsに新たなセッション情報を追加
  def add_session(userid, interfaceid, query)
    session = Session.new(userid: userid, interfaceid: interfaceid, query: query)
    session.save
  end

  # accessesに新たなアクセス情報を追加
  def add_access(userid, interfaceid, query, type, options: {})
    session = Session.where(userid: userid, interfaceid: interfaceid, query: query).last
    session_id = session.id

    if options.key?('rank')
      access = Access.new(session_id: session_id, access_type: type, rank: options['rank'])
    else
      access = Access.new(session_id: session_id, access_type: type)
    end
    access.save
  end

  # クエリが投入された際に適合性のログを初期化
  def initialize_relevances(userid, interfaceid, query)    
    session = Session.where(userid: userid, interfaceid: interfaceid, query: query).last
    session_id = session.id
    if Relevance.where(session_id: session_id, rank: 1).empty?
      relevances = []
      for i in 1..10
        relevances.push(Relevance.new(session_id: session_id, rank: i, relevance: 'none'))
      end
      Relevance.import relevances
    end
  end

  # フィードバックに応じてログを書き換える
  def update_relevance(userid, interfaceid, query, rank, relev)
    session = Session.where(userid: userid, interfaceid: interfaceid, query: query).last
    session_id = session.id
    relevance = Relevance.where(session_id: session_id, rank: rank).last
    relevance.update(relevance: relev)
  end
end
