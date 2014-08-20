# -*- coding: utf-8 -*-
require 'open-uri'

=begin
クエリ入力をシミュレートし，キャッシュを取得するためのクラス
=end
class QuerySimulator

  def initialize(queries)
    @queries = queries
    @search_result_url = "http://10.238.27.184:3000/static_pages/result/anonymous/3?utf8=%E2%9C%93&commit=%E6%A4%9C%E7%B4%A2&search_string="
    @graph_url = "http://10.238.27.184:3000/static_pages/graph/3?search_string="
    @relevance_graph_url = "http://10.238.27.184:3000/static_pages/graph/2?search_string="
  end

  # 複数のクエリ語に対して，入力をシミュレート
  def simulate(interfaceid)
    @queries.each do |query|
      simulate_query(query, interfaceid)
    end
  end

  # 単一のクエリ語に対して，入力をシミュレート
  def simulate_query(query, interfaceid)
    puts open("#{ @search_result_url }#{ query }").read
    if interfaceid == 2
        puts open("#{ @relevance_graph_url }#{ query }", {read_timeout: nil}).read
    elsif interfaceid == 3
        puts open("#{ @graph_url }#{ query }", {read_timeout: nil}).read
    end
  end

end

if __FILE__ == $0
  q = QuerySimulator.new(ARGV[1..-1])
  q.simulate(ARGV[0].to_i)
end
