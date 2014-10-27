# -*- coding: utf-8 -*-

require 'open-uri'
require 'uri'
require 'logger'
require 'active_support/core_ext'

class UrlOpen
  attr_accessor :content, :url, :status_code, :charset
  def initialize
  end

  def get(url, params: {}, headers: {}, try: 0, timeout: 100, sleep_time: 60)
    while try >= 0
      html = get_http_response(url, params, headers, timeout)
      if @status_code == 200
        break
      else
        try -= 1
        sleep(sleep_time) if try > 0
      end
    end
    return @content
  end

  private

  def get_http_response(base_url, params, headers, timeout)
    @base_url = base_url
    @params = params
    @headers = headers
    @url = compose_url(@base_url, @params)
    @status_code = 0
    @content = ''
    
    loop do
      begin 
        @charset = nil
        open(@url) do |f|
          @status_code = f.status[0]
          @charset = f.charset
          @content = f.read
        end
        break
      rescue OpenURI::HTTPError => ex
        @status_code = ex.io.status[0]
        if @status_code == '404'
          puts "url_open.rb: #{ @url }"
          puts 'file not found...'
          break
        else
          sleep_time = rand(5) + 3
          puts "url_open.rb: #{ @url }"
          puts "sleep #{ sleep_time } sec..."
          sleep(sleep_time)
        end
      rescue => e
      end
    end

    return @content
  end

  def compose_url(base_url, params)
    url = URI(base_url)
    url.query = params.to_param
    puts url
    return url.to_s
  end
end

if __FILE__ == $0
  f = UrlOpen.new
  f.get("http://google.com/search", params: {"q" => "twitter"})
  puts "The content of #{f.url} is below"
  puts f.content
end
