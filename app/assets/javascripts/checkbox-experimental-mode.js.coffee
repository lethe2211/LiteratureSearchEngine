# 実験モードへ移行するためのチェックボックス
ready = ->
        exports = this
        exports.isExperimentalMode = Cookie.getCookie 'is_experimental_mode'

        # 実験モードであれば，検索時にすぐに結果を表示せず，グラフ読み込みが行われた後にユーザにアラートを表示する 
        if exports.isExperimentalMode == 'true'
                checkBox = $('#checkbox_experimental_mode')
                checkBox.prop 'checked', true
                $('#experimental_mode').show()
                $('#citation_graph').hide()
                $('#search_results').hide()
                $('#other_search_results').hide()
                if gon.action == 'result'
                        $('#search_button').attr('disabled', true);
        else
                checkBox = $('#checkbox_experimental_mode')
                checkBox.prop 'checked', false
                $('#experimental_mode').hide()
        
        $('#checkbox_experimental_mode').click ->
                checkBox = $('#checkbox_experimental_mode')
                # checkBox.prop('checked', !checkBox.prop('checked'));
                if checkBox.prop 'checked'
                        $('#experimental_mode').show()
                        $('.relevance').show()
                else
                        $('#experimental_mode').hide()
                        exports.pause()
                        # $('#countdown_timer').countdown 'pause'
                        $('.relevance').hide()

        $(window).on 'beforeunload', ->
                checkBox = $('#checkbox_experimental_mode')
                if checkBox.prop 'checked'
                        Cookie.setCookie 'is_experimental_mode', true, 1
                else
                        Cookie.setCookie 'is_experimental_mode', false, 1
                return
$(document).ready(ready)
$(document).on('page:load', ready)
