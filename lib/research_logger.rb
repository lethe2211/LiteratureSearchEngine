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

end
