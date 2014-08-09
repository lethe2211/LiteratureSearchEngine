# -*- coding: utf-8 -*-
class CrawlController < ApplicationController

  def search_results
    render :json => get_search_results(params[:query])
  end

  # クエリを受け取り，google_scholar_crawler.pyを呼び出す
  def get_search_results(query)
    filepath = "#{ Rails.root.to_s }/lib/crawler/google_scholar_crawler.py"
    return Util.execute_command(filepath, query)
  end

end
