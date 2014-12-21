# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
ready = ->
        # $(".nav > li a").eq(parseInt(gon.interface) - 1).css("color", "#111111")
        # $(".nav > li a").eq(parseInt(gon.interface) - 1).css("background-color", "#5555ee")

        # hotfix for experiment
        if gon.interface == 1
                $(".nav > li a").eq(0).css("color", "#111111")
                $(".nav > li a").eq(0).css("background-color", "#5555ee")
        else if gon.interface == 3
                $(".nav > li a").eq(1).css("color", "#111111")
                $(".nav > li a").eq(1).css("background-color", "#5555ee")
        
$(document).ready(ready)
$(document).on('page:load', ready)
