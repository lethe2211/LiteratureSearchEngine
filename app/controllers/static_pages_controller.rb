# -*- coding: utf-8 -*-
require 'open3'
require 'json'

class StaticPagesController < ApplicationController
  def search
  end

  def result
    command = Rails.root.to_s + "/lib/crawler/google_scholar_crawler.py"
    query = params[:search_string]
    command += " " + query
    out, err, status = Open3.capture3(command)
    p out 
    logger.debug(out)
    json = JSON.parser.new(out)
    @articles = json.parse()
    @articles.each do |article|
      article.each_key do |key|
        p "#{key}: #{article[key][0]}"
      end
    end
  end

  def get_citation
    content = open(Rails.root.to_s + "/lib/crawler/citations/data.json").read
    @json = JSON.parse(content)
    logger.debug(@json)
    render :text => @json.to_json
  end
end


