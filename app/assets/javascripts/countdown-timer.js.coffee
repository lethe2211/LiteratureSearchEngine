# 実験用のタイマーの設定
ready = ->
        exports = this          # グローバル変数
        exports.experimentSeconds = 300
        countdown = {}
        url = '../../../logs/'

        load = ->
                $.get "#{ url }load_countdown/#{ gon.userid }/#{ gon.interface }", {search_string: gon.query}, json = -> console.log "#{ url }load_countdown/#{ gon.userid }/#{ gon.interface }"
                
        reload = ->
                $.get "#{ url }reload_countdown/#{ gon.userid }/#{ gon.interface }", {search_string: gon.query}, json = -> console.log "#{ url }reload_countdown/#{ gon.userid }/#{ gon.interface }"
                $('#countdown_timer').countdown('destroy')
                $('#countdown_timer').countdown
                        until: exports.experimentSeconds
                        format: 'MS'
                        compact: true
                        onExpiry: ->
                                expire()
                                $(this).css({"fontSize": '28px', "textAlign": 'center'}).text('終了!').css({"fontSize": '20px', "textAlign": 'center'})

        start = ->
                $.get "#{ url }start_countdown/#{ gon.userid }/#{ gon.interface }", {search_string: gon.query}, json = -> console.log "#{ url }start_countdown/#{ gon.userid }/#{ gon.interface }"
                $('#countdown_timer').countdown('resume')

        pause = ->
                $('#countdown_timer').countdown('pause')
                $.get "#{ url }pause_countdown/#{ gon.userid }/#{ gon.interface }", {}, json = -> console.log "#{ url }pause_countdown/#{ gon.userid }/#{ gon.interface }"
                
        resume = ->
                $.get "#{ url }resume_countdown/#{ gon.userid }/#{ gon.interface }", {}, json = -> console.log "#{ url }resume_countdown/#{ gon.userid }/#{ gon.interface }"
                $('#countdown_timer').countdown('resume')
        expire = ->
                $.get "#{ url }expire_countdown/#{ gon.userid }/#{ gon.interface }", {}, json = -> console.log "#{ url }expire_countdown/#{ gon.userid }/#{ gon.interface }"


        remainingSeconds = Cookie.getCookie 'remaining_seconds'
        if remainingSeconds? and remainingSeconds != 'null'
                countdown =
                        until: remainingSeconds
                        format: 'MS'
                        compact: true
                        onExpiry: ->
                                expire()
                                $(this).css({"fontSize": '28px', "textAlign": 'center'}).text('終了!').css({"fontSize": '20px', "textAlign": 'center'})
        else
                countdown =
                        until: exports.experimentSeconds
                        format: 'MS'
                        compact: true
                        onExpiry: ->
                                expire()
                                $(this).css({"fontSize": '28px', "textAlign": 'center'}).text('終了!').css({"fontSize": '20px', "textAlign": 'center'})
        $('#countdown_timer').countdown countdown
        load()
        pause()
        
        $(window).on 'beforeunload', ->
                periods = $('#countdown_timer').countdown('getTimes')
                remainingSeconds = $.countdown.periodsToSeconds(periods)
                Cookie.setCookie 'remaining_seconds', remainingSeconds, 1
                return

        $('#start_countdown_timer_button').click ->
                start()
                
        $('#reload_countdown_timer_button').click ->
                reload()
                pause()
                
$(document).ready(ready)
$(document).on('page:load', ready)

        
