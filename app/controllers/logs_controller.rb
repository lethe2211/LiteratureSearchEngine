class LogsController < ApplicationController
  def initialize
    @rl = ResearchLogger.new
  end

  def page_loaded
    @rl.add_access('page_loaded')
    render :text => 'OK'
  end

  def update_relevance
    rank = params[:rank]
    relevance = params[:relevance]
    
    @rl.update_relevance(rank, relevance)
    render :text => 'OK'
  end

  def read_paper
    @rl.add_access('read_paper')
    render :text => 'OK'
  end
end
