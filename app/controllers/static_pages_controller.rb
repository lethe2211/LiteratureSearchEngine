# -*- coding: utf-8 -*-
require 'open3'
require 'json'

class StaticPagesController < ApplicationController
  def search
  end

  def result
    command = Rails.root.to_s + "/lib/crawler/google_scholar_crawler.py"
    query = params[:search_string]
    if query.strip! == ""
      return
    end
    query = query.gsub(/(\s|　)+/, "+")

    @text_field_val = params[:search_string] if params[:search_string]

    # command += " " + query + " | tee  " + Rails.root.to_s + "/lib/crawler/citations/" + query + ".json"
    command += " " + query
    out, err, status = Open3.capture3(command)
    logger.debug(out)
    json = JSON.parser.new(out)
    @articles = json.parse()
    # @articles.each do |article|
    #   article.each_key do |key|
    #     p "#{key}: #{article[key][0]}"
    #   end
    # end

    @@graph = {nodes: {}, edges: {}}
    @articles.each do |article|
      cid = article["cluster_id"][0].to_s
      @@graph[:nodes][cid] = {}

      @@graph[:edges][cid] = {}
      citation = article["citation"][0]
      logger.debug(citation)
      citation.each do |cit|
        @@graph[:edges][cid][cid + "_" + cit["num"].to_s] = {directed: true, weight: 3}
      end
    end

  end

  def get_citation
    render :json => @@graph
    # content = open(Rails.root.to_s + "/lib/crawler/citations/data.json").read
    # @json = JSON.parse(content)
    # logger.debug(@json)
    # render :text => @json.to_json
  end
end


