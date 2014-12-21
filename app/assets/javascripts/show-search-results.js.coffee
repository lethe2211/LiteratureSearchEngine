# グラフを表示しないインタフェースの場合，最初に隠した検索結果とグラフを再表示する必要がある
ready = ->
        exports = this          # グローバル変数

        params = getUrlVars()
        start_num = if params['start_num']? then parseInt(params['start_num']) else 1
        end_num = if params['end_num']? then parseInt(params['end_num']) else 10
        

        # 実験モード
        isExperimentalMode = Cookie.getCookie 'is_experimental_mode'
        if isExperimentalMode == 'true'
                alert 'Ready to search' 		# ユーザへの通知
                $('#search_results').show()
                $('#other_search_results').show()
                exports.resume()
                # $('#countdown_timer').countdown 'resume'
                # $.get '../../../logs/resume_countdown/' + gon.userid + '/' + gon.interface, { }, json = -> console.log('../../../logs/resume_countdown' + gon.userid + '/' + gon.interface)
        else
                $('.relevance').hide()
        $('#status').text('Search completed')
        url = '../../../logs/page_loaded/' + gon.userid + '/' + gon.interface;
        $.get url, { search_string: gon.query, start_num: start_num, end_num: end_num }, json = -> console.log(url)

getUrlVars = -> 
        vars = {}
        hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&')
        for i in [0..hashes.length-1]
                hash = hashes[i].split('=')
                vars[hash[0]] = hash[1]
        return vars

$(document).ready(ready)
$(document).on('page:load', ready)
