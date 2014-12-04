ready = ->
        $('#checkbox_experimental_mode').click ->
                checkBox = $('#checkbox_experimental_mode')
                # checkBox.prop('checked', !checkBox.prop('checked'));
                if checkBox.prop('checked')
                        $('#experimental_mode').show()
                else
                        $('#experimental_mode').hide()
$(document).ready(ready)
$(document).on('page:load', ready)
