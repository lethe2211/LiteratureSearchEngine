# 論文リンクをたどって論文を閲覧した時にログを書き込む
ready = ->
        exports = this          # グローバル変数
        calculateElapsedTime = ->
                periods = $('#countdown_timer').countdown('getTimes')
                remainingSeconds = $.countdown.periodsToSeconds(periods)
                elapsedTime = exports.experimentSeconds - remainingSeconds
                return elapsedTime

        params = getUrlVars()
        start_num = if params['start_num']? then parseInt(params['start_num']) else 1
        end_num = if params['end_num']? then parseInt(params['end_num']) else 10
        $('.search_result_title > a').on 'click', ->
                url = "../../../logs/read_paper/#{ gon.userid }/#{ gon.interface }"
                parent = $(this).parent().get(0)
                index = $('.search_result_title').index(parent) # 何番目の検索結果をクリックしたか
                href = $(this).attr('href')
                literatureId = parseInt(href.split('/')[4])
                if Number.isNaN(literatureId)
                        literatureId = ''
                $.get url, { search_string: gon.query, start_num: start_num, end_num: end_num, elapsed_time: calculateElapsedTime(), rank: start_num + index, literature_id: literatureId }, json = -> console.log(url)

        

getUrlVars = -> 
        vars = {}
        hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&'); 
        for i in [0..hashes.length-1]
                hash = hashes[i].split('=')
                vars[hash[0]] = hash[1]
        return vars
        
$(document).ready(ready)
$(document).on('page:load', ready)
