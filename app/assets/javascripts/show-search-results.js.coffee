ready = ->
        # 実験モード
        isExperimentalMode = Cookie.getCookie 'is_experimental_mode'
        if isExperimentalMode == 'true'
                alert 'Ready to search' 		# ユーザへの通知
                $('#search_results').show()
                $('#countdown_timer').countdown 'resume'
        else
                $('.relevance').hide()
        $('#status').text('Search completed')
$(document).ready(ready)
$(document).on('page:load', ready)
