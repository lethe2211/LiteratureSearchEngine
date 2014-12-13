# グラフを表示しないインタフェースの場合，最初に隠した検索結果とグラフを再表示する必要がある
ready = ->
        # 実験モード
        isExperimentalMode = Cookie.getCookie 'is_experimental_mode'
        if isExperimentalMode == 'true'
                alert 'Ready to search' 		# ユーザへの通知
                $('#search_results').show()
                $('#countdown_timer').countdown 'resume'
                $.get '../../../logs/resume_countdown/' + gon.userid + '/' + gon.interface, {}, json = -> console.log('../../../logs/resume_countdown' + gon.userid + '/' + gon.interface)
        else
                $('.relevance').hide()
        $('#status').text('Search completed')
        url = '../../../logs/page_loaded/' + gon.userid + '/' + gon.interface;
        $.get url, {search_string: gon.query}, json = -> console.log(url)

$(document).ready(ready)
$(document).on('page:load', ready)
