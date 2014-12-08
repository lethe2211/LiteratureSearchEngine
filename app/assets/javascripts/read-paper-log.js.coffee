# 論文リンクをたどって論文を閲覧した時にログを書き込む
ready = ->
        $('.search_result_title > a').on 'click', ->
                url = "../../../logs/read_paper/#{ gon.userid }/#{ gon.interface }"
                parent = $(this).parent().get(0)
                index = $('.search_result_title').index(parent) # 何番目の検索結果をクリックしたか
                $.get url, {search_string: gon.query, rank: index + 1}, json = -> console.log(url)
                        
$(document).ready(ready)
$(document).on('page:load', ready)
