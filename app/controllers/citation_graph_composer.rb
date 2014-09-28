# -*- coding: utf-8 -*-

require 'citation_controller'

class CitationGraphComposer
  def initialize
    @mm = Mscrawler::MsacademicManager.new
  end

  def compose_graph(articles)
    graph_cache = JsonCache.new(dir: "./crawler/graph/")

    @query = articles["data"]["query"]
    cache = graph_cache.get(@query)

    if (not cache.nil?) and cache["status"] == 'OK'
      return cache["data"]
    else
      result = {status: "NG", data: {}}

      search_results = articles["data"]["search_results"]

      bibliographies = extract_bibliographies(search_results)
      citations = extract_citations(search_results)
      citedbyes = extract_citedbyes(search_results)

      graph = compute_graph(search_results, bibliographies, citations, citedbyes)
      Rails.logger.debug(graph.inspect)
      if graph.count_node != 0
        result[:data] = graph.to_h
        result[:status] = "OK"
        graph_cache.set(@query, result)
      else
        result[:status] = "NG"
      end

      Rails.logger.debug(result[:data])
      return result[:data]
    end
  end

  private

  # def extract_bibliographies(search_results)
  #   bibliographies = {}
  #   search_results.each do |search_result|
  #     cid  = search_result["cluster_id"].to_s
  #     Rails.logger.debug("bibliography: " + cid)
  #     bib = CitationController.get_bibliography(cid.to_i)
  #     bibliographies[cid] = bib.blank? ? [] : Oj.load(bib)
  #   end
  #   Rails.logger.debug(bibliographies)
  #   return bibliographies
  # end

  def extract_bibliographies(search_results)
    bibliographies = {}
    search_results.each do |search_result|
      id  = search_result["id"].to_s
      Rails.logger.debug("bibliography: " + id)
      bib = @mm.get_bibliography(id.to_i)
      bibliographies[id] = bib.blank? ? [] : bib
    end
    Rails.logger.debug(bibliographies)
    return bibliographies
  end

  # def extract_citations(search_results)
  #   citations = {}
  #   search_results.each do |search_result|
  #     cid  = search_result["cluster_id"].to_s
  #     Rails.logger.debug("citation: " + cid)
  #     citation = CitationController.get_citation(cid.to_i)
  #     citations[cid] = citation.blank? ? {'status' => 'NG', 'data' => []} : Oj.load(citation)
  #   end
  #   Rails.logger.debug(citations)
  #   return citations
  # end

  def extract_citations(search_results)
    citations = {}
    search_results.each do |search_result|
      id  = search_result["id"].to_s
      Rails.logger.debug("citation: " + id)
      citation = @mm.get_citation(id.to_i)
      citations[id] = citation.blank? ? [] : citation
    end
    Rails.logger.debug(citations)
    return citations
  end

  # def extract_citedbyes(search_results)
  #   citedbyes = {}
  #   search_results.each do |search_result|
  #     cid  = search_result["cluster_id"].to_s
  #     Rails.logger.debug("citedby: " + cid)
  #     citedby = CitationController.get_citedby(cid.to_i)
  #     citedbyes[cid] = citedby.blank? ? {'status' => 'NG', 'data' => []} : Oj.load(citedby)
  #   end
  #   Rails.logger.debug(citedbyes)        
  #   return citedbyes
  # end

  def extract_citedbyes(search_results)
    citedbyes = {}
    search_results.each do |search_result|
      id  = search_result["id"].to_s
      Rails.logger.debug("citedby: " + id)
      citedby = @mm.get_citedby(id.to_i)
      citedbyes[id] = citedby.blank? ? [] : citedby
    end
    Rails.logger.debug(citedbyes)        
    return citedbyes
  end

  def compute_graph(search_results, bibliographies, citations, citedbyes)
    graph = Graph.new

    used_cids = [] # ループ中ですでに1度呼ばれた論文
    used_result_cids = [] # ループ中ですでに1度呼ばれた検索結果論文

    # 任意の一対の検索結果論文について
    search_results.each do |search_result1|
      id1 = search_result1["id"].to_s
      search_results.each do |search_result2|
        id2 = search_result2["id"].to_s
        if id1.to_i >= id2.to_i
          next
        end

        Rails.logger.debug("id1: " + id1)
        Rails.logger.debug("id2: " + id2)
        Rails.logger.debug("")

        # 論文ノードの初期化
        unless used_result_cids.include?(id1)
          # graph_json[:nodes][id1] = {type: "search_result", weight: bibliographies[id1]["data"]["num_citations"], title: search_result1["title"], year: bibliographies[id1]["data"]["year"], color: "#dd3333", rank: search_result1["rank"]}
          search_result_node = SearchResultGraphNode.new(id1, bibliographies[id1]["data"]["num_citations"], bibliographies[id1], search_result1["rank"])            
          graph.append_node(search_result_node)
          used_result_cids.push(id1)
          unless used_cids.include?(id1)
            # graph_json[:edges][id1] = {}
            used_cids.push(id1)
          end
        end

        unless used_result_cids.include?(id2)
          # graph_json[:nodes][id2] = {type: "search_result", weight: bibliographies[id2]["data"]["num_citations"], title: search_result2["title"], year: bibliographies[id2]["data"]["year"], color: "#dd3333", rank: search_result2["rank"]}            
          search_result_node = SearchResultGraphNode.new(id2, bibliographies[id2]["data"]["num_citations"], bibliographies[id2], search_result2["rank"])            
          graph.append_node(search_result_node)
          used_result_cids.push(id2)
          unless used_cids.include?(id2)
            # graph_json[:edges][id2] = {}
            used_cids.push(id2)
          end
        end

        Rails.logger.debug((citations[id1] & citations[id2]).to_s)
        Rails.logger.debug((citations[id1] & citedbyes[id2]).to_s)
        Rails.logger.debug((citedbyes[id1] & citations[id2]).to_s)
        Rails.logger.debug((citedbyes[id1] & citedbyes[id2]).to_s)

        # 両方が(共)引用する論文
        (citations[id1] & citations[id2]).each do |cit|
          # b = CitationController.get_bibliography(cit.to_i)
          b = @mm.get_bibliography(cit)
          bib = b.blank? ? { 'status' => 'NG', 'data' => {} } : b
          unless used_cids.include?(cit)
            # graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
            node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
            graph.append_node(node)
            used_cids.push(cit)
          end
          Rails.logger.debug("citation of id1 and id2: " + cit)
          # graph_json[:edges][id1][cit] = {directed: true, weight: 10, color: "#cccccc"}
          # graph_json[:edges][id2][cit] = {directed: true, weight: 10, color: "#cccccc"}
          edge_id1 = DirectedGraphEdge.new(id1, cit, 10, "#cccccc", {})
          graph.append_edge(edge_id1)
          edge_id2 = DirectedGraphEdge.new(id2, cit, 10, "#cccccc", {})
          graph.append_edge(edge_id2)
        end

        # 片方が引用し，もう片方が被引用する論文
        (citations[id1] & citedbyes[id2]).each do |cit|
          # b = CitationController.get_bibliography(cit.to_i)
          b = @mm.get_bibliography(cit)
          bib = b.blank? ?  { 'status' => 'NG', 'data' => {} } : b
          unless used_cids.include?(cit)
            # graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
            node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
            graph.append_node(node)
            # graph_json[:edges][cit] = {} 
            used_cids.push(cit)
          end
          Rails.logger.debug("citation of id1 and cited by id2: " + cit)
          # graph_json[:edges][id1][cit] = {directed: true, weight: 10, color: "#cccccc"}
          # graph_json[:edges][cit][id2] = {directed: true, weight: 10, color: "#888888"}
          edge_id1 = DirectedGraphEdge.new(id1, cit, 10, "#cccccc", {})
          graph.append_edge(edge_id1)
          edge_id2 = DirectedGraphEdge.new(cit, id2, 10, "#cccccc", {})
          graph.append_edge(edge_id2)
        end

        # 片方が被引用し，もう片方が引用する論文
        (citedbyes[id1] & citations[id2]).each do |cit|
          # b = CitationController.get_bibliography(cit.to_i)
          b = @mm.get_bibliography(cit)
          # bib = b.blank? ? {} : JSON.parse(b)
          bib = b.blank? ?  { 'status' => 'NG', 'data' => {} } : b
          unless used_cids.include?(cit)
            # graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
            node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
            graph.append_node(node)
            # graph_json[:edges][cit] = {} 
            used_cids.push(cit)
          end
          Rails.logger.debug("cited by id1 and citation of id2: " + cit)
          # eraph_eson[:edges][cit][id1] = {directed: true, weight: 10, color: "#888888"}
          # graph_json[:edges][id2][cit] = {directed: true, weight: 10, color: "#cccccc"}
          edge_id1 = DirectedGraphEdge.new(cit, id1, 10, "#cccccc", {})
          graph.append_edge(edge_id1)
          edge_id2 = DirectedGraphEdge.new(id2, cit, 10, "#cccccc", {})
          graph.append_edge(edge_id2)  
        end 
        
        # 両方が被引用される論文
        (citedbyes[id1] & citedbyes[id2]).each do |cit|
          # b = CitationController.get_bibliography(cit.to_i)
          b = @mm.get_bibliography(cit)
          # bib = b.blank? ? {} : JSON.parse(b)
          bib = b.blank? ?  { 'status' => 'NG', 'data' => {} } : b
          unless used_cids.include?(cit)
            # graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
            # graph_json[:edges][cit] = {} 
            node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
            graph.append_node(node)
            used_cids.push(cit)
          end
          Rails.logger.debug("cited by id1 and id2: " + cit)
          # graph_json[:edges][cit][id1] = {directed: true, weight: 10, color: "#888888"}
          # graph_json[:edges][cit][id2] = {directed: true, weight: 10, color: "#888888"}
          edge_id1 = DirectedGraphEdge.new(cit, id1, 10, "#cccccc", {})
          graph.append_edge(edge_id1)
          edge_id2 = DirectedGraphEdge.new(cit, id2, 10, "#cccccc", {})
          graph.append_edge(edge_id2)  
        end

        # id1の論文がid2の論文を引用している
        if (citedbyes[id2]).include?(id1) or (citations[id1]).include?(id2)
          # graph_json[:edges][id1][id2] = {directed: true, weight: 10, color: "#333333"}
          edge = DirectedGraphEdge.new(id1, id2, 10, "#333333", {})
          graph.append_edge(edge)
        end

        # id2の論文がid1の論文を引用している
        if (citations[id2]).include?(id1) or (citedbyes[id1]).include?(id2)
          # graph_json[:edges][id2][id1] = {directed: true, weight: 10, color: "#333333"}
          edge = DirectedGraphEdge.new(id2, id1, 10, "#333333", {})
          graph.append_edge(edge)
        end
      end
    end
    return graph
  end
  
  # def compute_graph(search_results, bibliographies, citations, citedbyes)
  #   graph = Graph.new

  #   used_cids = [] # ループ中ですでに1度呼ばれた論文
  #   used_result_cids = [] # ループ中ですでに1度呼ばれた検索結果論文

  #   # 任意の一対の検索結果論文について
  #   search_results.each do |search_result1|
  #     cid1 = search_result1["cluster_id"].to_s
  #     search_results.each do |search_result2|
  #       cid2 = search_result2["cluster_id"].to_s
  #       if cid1.to_i >= cid2.to_i
  #         next
  #       end

  #       Rails.logger.debug("cid1: " + cid1)
  #       Rails.logger.debug("cid2: " + cid2)
  #       Rails.logger.debug("")

  #       # 論文ノードの初期化
  #       unless used_result_cids.include?(cid1)
  #         # graph_json[:nodes][cid1] = {type: "search_result", weight: bibliographies[cid1]["data"]["num_citations"], title: search_result1["title"], year: bibliographies[cid1]["data"]["year"], color: "#dd3333", rank: search_result1["rank"]}
  #         search_result_node = SearchResultGraphNode.new(cid1, bibliographies[cid1]["data"]["num_citations"], bibliographies[cid1], search_result1["rank"])            
  #         graph.append_node(search_result_node)
  #         used_result_cids.push(cid1)
  #         unless used_cids.include?(cid1)
  #           # graph_json[:edges][cid1] = {}
  #           used_cids.push(cid1)
  #         end
  #       end

  #       unless used_result_cids.include?(cid2)
  #         # graph_json[:nodes][cid2] = {type: "search_result", weight: bibliographies[cid2]["data"]["num_citations"], title: search_result2["title"], year: bibliographies[cid2]["data"]["year"], color: "#dd3333", rank: search_result2["rank"]}            
  #         search_result_node = SearchResultGraphNode.new(cid2, bibliographies[cid2]["data"]["num_citations"], bibliographies[cid2], search_result2["rank"])            
  #         graph.append_node(search_result_node)
  #         used_result_cids.push(cid2)
  #         unless used_cids.include?(cid2)
  #           # graph_json[:edges][cid2] = {}
  #           used_cids.push(cid2)
  #         end
  #       end

  #       Rails.logger.debug((citations[cid1]["data"] & citations[cid2]["data"]).to_s)
  #       Rails.logger.debug((citations[cid1]["data"] & citedbyes[cid2]["data"]).to_s)
  #       Rails.logger.debug((citedbyes[cid1]["data"] & citations[cid2]["data"]).to_s)
  #       Rails.logger.debug((citedbyes[cid1]["data"] & citedbyes[cid2]["data"]).to_s)

  #       # 両方が(共)引用する論文
  #       (citations[cid1]["data"] & citations[cid2]["data"]).each do |cit|
  #         b = CitationController.get_bibliography(cit.to_i)
  #         bib = b.blank? ? {'status' => 'NG', 'data' => {}} : Oj.load(b)
  #         unless used_cids.include?(cit)
  #           # graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
  #           node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
  #           graph.append_node(node)
  #           used_cids.push(cit)
  #         end
  #         Rails.logger.debug("citation of cid1 and cid2: " + cit)
  #         # graph_json[:edges][cid1][cit] = {directed: true, weight: 10, color: "#cccccc"}
  #         # graph_json[:edges][cid2][cit] = {directed: true, weight: 10, color: "#cccccc"}
  #         edge_cid1 = DirectedGraphEdge.new(cid1, cit, 10, "#cccccc", {})
  #         graph.append_edge(edge_cid1)
  #         edge_cid2 = DirectedGraphEdge.new(cid2, cit, 10, "#cccccc", {})
  #         graph.append_edge(edge_cid2)
  #       end

  #       # 片方が引用し，もう片方が被引用する論文
  #       (citations[cid1]["data"] & citedbyes[cid2]["data"]).each do |cit|
  #         b = CitationController.get_bibliography(cit.to_i)
  #         bib = b.blank? ? {'status' => 'NG', 'data' => {}} : Oj.load(b)
  #         unless used_cids.include?(cit)
  #           # graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
  #           node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
  #           graph.append_node(node)
  #           # graph_json[:edges][cit] = {} 
  #           used_cids.push(cit)
  #         end
  #         Rails.logger.debug("citation of cid1 and cited by cid2: " + cit)
  #         # graph_json[:edges][cid1][cit] = {directed: true, weight: 10, color: "#cccccc"}
  #         # graph_json[:edges][cit][cid2] = {directed: true, weight: 10, color: "#888888"}
  #         edge_cid1 = DirectedGraphEdge.new(cid1, cit, 10, "#cccccc", {})
  #         graph.append_edge(edge_cid1)
  #         edge_cid2 = DirectedGraphEdge.new(cit, cid2, 10, "#cccccc", {})
  #         graph.append_edge(edge_cid2)
  #       end

  #       # 片方が被引用し，もう片方が引用する論文
  #       (citedbyes[cid1]["data"] & citations[cid2]["data"]).each do |cit|
  #         b = CitationController.get_bibliography(cit.to_i)
  #         # bib = b.blank? ? {} : JSON.parse(b)
  #           bib = b.blank? ? {'status' => 'NG', 'data' => {}} : Oj.load(b)
  #           unless used_cids.include?(cit)
  #             # graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
  #             node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
  #             graph.append_node(node)
  #             # graph_json[:edges][cit] = {} 
  #             used_cids.push(cit)
  #           end
  #           Rails.logger.debug("cited by cid1 and citation of cid2: " + cit)
  #           # eraph_eson[:edges][cit][cid1] = {directed: true, weight: 10, color: "#888888"}
  #           # graph_json[:edges][cid2][cit] = {directed: true, weight: 10, color: "#cccccc"}
  #           edge_cid1 = DirectedGraphEdge.new(cit, cid1, 10, "#cccccc", {})
  #           graph.append_edge(edge_cid1)
  #           edge_cid2 = DirectedGraphEdge.new(cid2, cit, 10, "#cccccc", {})
  #           graph.append_edge(edge_cid2)  
  #         end 
          
  #         # 両方が被引用される論文
  #         (citedbyes[cid1]["data"] & citedbyes[cid2]["data"]).each do |cit|
  #           b = CitationController.get_bibliography(cit.to_i)
  #           # bib = b.blank? ? {} : JSON.parse(b)
  #           bib = b.blank? ? {'status' => 'NG', 'data' => {}} : Oj.load(b)
  #           unless used_cids.include?(cit)
  #             # graph_json[:nodes][cit] = {type: "normal", weight: bib["data"]["num_citations"], title: bib["data"]["title"], year: bib["data"]["year"], color: "#cccccc"}
  #             # graph_json[:edges][cit] = {} 
  #             node = GraphNode.new(cit, bib["data"]["num_citations"], bib)
  #             graph.append_node(node)
  #             used_cids.push(cit)
  #           end
  #           Rails.logger.debug("cited by cid1 and cid2: " + cit)
  #           # graph_json[:edges][cit][cid1] = {directed: true, weight: 10, color: "#888888"}
  #           # graph_json[:edges][cit][cid2] = {directed: true, weight: 10, color: "#888888"}
  #           edge_cid1 = DirectedGraphEdge.new(cit, cid1, 10, "#cccccc", {})
  #           graph.append_edge(edge_cid1)
  #           edge_cid2 = DirectedGraphEdge.new(cit, cid2, 10, "#cccccc", {})
  #           graph.append_edge(edge_cid2)  
  #         end

  #         # cid1の論文がcid2の論文を引用している
  #         if (citedbyes[cid2]["data"]).include?(cid1) or (citations[cid1]["data"]).include?(cid2)
  #           # graph_json[:edges][cid1][cid2] = {directed: true, weight: 10, color: "#333333"}
  #           edge = DirectedGraphEdge.new(cid1, cid2, 10, "#333333", {})
  #           graph.append_edge(edge)
  #         end

  #         # cid2の論文がcid1の論文を引用している
  #         if (citations[cid2]["data"]).include?(cid1) or (citedbyes[cid1]["data"]).include?(cid2)
  #           # graph_json[:edges][cid2][cid1] = {directed: true, weight: 10, color: "#333333"}
  #           edge = DirectedGraphEdge.new(cid2, cid1, 10, "#333333", {})
  #           graph.append_edge(edge)
  #         end
  #       end
  #     end
  #   return graph
  # end

end
