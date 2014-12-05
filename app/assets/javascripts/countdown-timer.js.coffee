ready = ->
        class window.Cookie
                @setCookie = (name, value, days) ->
                        if days
                                date = new Date()
                                date.setTime date.getTime() + (days * 24 * 60 * 60 * 1000)
                                expires = '; expires=' + date.toGMTString()
                        else
                                expires = ''
                        document.cookie = name + '=' + value + expires + '; path=/'
                @getCookie = (name) ->
                        nameEQ = name + '='
                        ca = document.cookie.split(';')
                        i = 0

                        while i < ca.length
                                c = ca[i]
                                c = c.substring(1, c.length)  while c.charAt(0) is ' '
                                return c.substring(nameEQ.length, c.length)  if c.indexOf(nameEQ) is 0
                                i++
                        null
                @deleteCookie = (name) ->
                        setCookie name, '', -1

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
        $('#countdown_timer').countdown(countdown)
        $('#countdown_timer').countdown('pause')

        $(window).on 'beforeunload', ->
                periods = $('#countdown_timer').countdown('getTimes')
                remainingSeconds = $.countdown.periodsToSeconds(periods)
                Cookie.setCookie 'remaining_seconds', remainingSeconds, 1
                # return null
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
                                

$(document).ready(ready)
$(document).on('page:load', ready)

        
