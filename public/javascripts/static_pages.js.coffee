# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
ready = ->
        # alert(gon.interface)
        $(".nav > li a").eq(parseInt(gon.interface) - 1).css("color", "#111111")
        $(".nav > li a").eq(parseInt(gon.interface) - 1).css("background-color", "#5555ee")
        # $(".nav > li a").click ->
        #         $(".nav > li a").eq(gon.interface - 1).css("background-color", "#ffffff")

$(document).ready(ready)
$(document).on('page:load', ready)
