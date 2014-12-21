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

  # tasksにタスク追加
  def start_task(userid, interfaceid)
    task = Task.where(userid: userid, interfaceid: interfaceid).last
    if task.nil?
      task = Task.new(userid: userid, interfaceid: interfaceid)
      task.save
    else
      task.touch
    end
  end

  # eventsに時間経過によるイベント追加
  def add_event(userid, interfaceid, event_type, elapsed_time, options: {})
    task = Task.where(userid: userid, interfaceid: interfaceid).last
    task_id = task.id
    record = { task_id: task_id, event_type: event_type, elapsed_time: elapsed_time }
    options.each do |key, value|
      record[key] = value
    end
    event = Event.new(record)
    event.save
  end

  # queriesにクエリの情報を追加
  def add_query(userid, interfaceid, q)
    task = Task.where(userid: userid, interfaceid: interfaceid).last
    task_id = task.id
    query = Query.where(task_id: task_id, query: q).last
    if query.nil?
      query = Query.new(task_id: task_id, query: q)
      query.save
    else
      query.touch
    end
  end

  # sessionsに新たなセッション情報を追加
  def add_session(userid, interfaceid, q, start_num, end_num)
    task = Task.where(userid: userid, interfaceid: interfaceid).last
    task_id = task.id
    query = Query.where(task_id: task_id, query: q).last
    query_id = query.id
    session = Session.new(query_id: query_id, start_num: start_num, end_num: end_num)
    session.save
  end

  # accessesに新たなアクセス情報を追加
  def add_access(userid, interfaceid, q, start_num, end_num, access_type, elapsed_time, options: {})
    task = Task.where(userid: userid, interfaceid: interfaceid).last
    task_id = task.id
    query = Query.where(task_id: task_id, query: q).last
    query_id = query.id
    session = Session.where(query_id: query_id, start_num: start_num, end_num: end_num).last
    session_id = session.id

    record = { session_id: session_id, access_type: access_type, elapsed_time: elapsed_time }
    options.each do |key, value|
      record[key] = value
    end
    access = Access.new(record)
    access.save
  end

  # クエリが投入された際に適合性のログを初期化
  def initialize_relevances(userid, interfaceid, q, start_num, end_num, articles)
    task = Task.where(userid: userid, interfaceid: interfaceid).last
    task_id = task.id
    query = Query.where(task_id: task_id, query: q).last
    query_id = query.id
    session = Session.where(query_id: query_id, start_num: start_num, end_num: end_num).last
    session_id = session.id
    if Relevance.where(session_id: session_id, rank: 1).empty?
      relevances = []
      for i in (start_num)..(start_num + 9)
        if articles['data']['search_results'][i-1].nil?
          break
        else
          literature_id = articles['data']['search_results'][i-1]['id']
          relevances.push(Relevance.new(session_id: session_id, rank: i, relevance: 'none', literature_id: literature_id))
        end
      end
      Relevance.import relevances
    end
  end

  # フィードバックに応じてログを書き換える
  def update_relevance(userid, interfaceid, q, start_num, end_num, rank, relev, options: {})
    task = Task.where(userid: userid, interfaceid: interfaceid).last
    task_id = task.id
    query = Query.where(task_id: task_id, query: q).last
    query_id = query.id
    session = Session.where(query_id: query_id, start_num: start_num, end_num: end_num).last
    session_id = session.id
    relevance = Relevance.where(session_id: session_id, rank: rank).last

    record = { relevance: relev }
    options.each do |key, value|
      record[key] = value
    end
    relevance.update(record)
  end
end
