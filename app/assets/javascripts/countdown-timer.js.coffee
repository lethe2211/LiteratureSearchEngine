# 実験用のタイマーの設定
ready = ->
        exports = this          # グローバル変数
        exports.experimentSeconds = 300
        countdown = {}

        remainingSeconds = Cookie.getCookie 'remaining_seconds'
        if remainingSeconds? and remainingSeconds != 'null'
                countdown =
                        until: remainingSeconds
                        format: 'MS'
                        compact: true
                        onExpiry: ->
                                $(this).css({"fontSize": '28px', "textAlign": 'center'}).text('終了!').css({"fontSize": '20px', "textAlign": 'center'})
        else
                countdown =
                        until: exports.experimentSeconds
                        format: 'MS'
                        compact: true
                        onExpiry: ->
                                $(this).css({"fontSize": '28px', "textAlign": 'center'}).text('終了!').css({"fontSize": '20px', "textAlign": 'center'})
        # alert countdown['until']
        $('#countdown_timer').countdown countdown
        $('#countdown_timer').countdown 'pause'

        $(window).on 'beforeunload', ->
                periods = $('#countdown_timer').countdown('getTimes')
                remainingSeconds = $.countdown.periodsToSeconds(periods)
                Cookie.setCookie 'remaining_seconds', remainingSeconds, 1
                return

        $('#start_countdown_timer_button').click ->
                $('#countdown_timer').countdown('resume')
                
        $('#reload_countdown_timer_button').click ->
                # $('#countdown_timer').countdown('until', exports.experimentSeconds)
                $('#countdown_timer').countdown('destroy')
                $('#countdown_timer').countdown
                        until: exports.experimentSeconds
                        format: 'MS'
                        compact: true
                        onExpiry: ->
                                $(this).css({"fontSize": '28px', "textAlign": 'center'}).text('終了!').css({"fontSize": '20px', "textAlign": 'center'})
                $('#countdown_timer').countdown('pause')
                                

$(document).ready(ready)
$(document).on('page:load', ready)

        
