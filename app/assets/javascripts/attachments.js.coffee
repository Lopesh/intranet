# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $("#doc_show").click ->
    if $("#doc_show").text() == 'Show All'
      params = 'all_docs=true'
      $("#doc_show").text('Show Visible')
    else
      params = 'all_docs=false' 
      $("#doc_show").text('Show All')
    $.ajax
      type: 'GET'
      dataType: 'script'
      url:'/attachments' + '?' + params

  $("#policy_show").click ->
    if $("#policy_show").text() == 'Show All'
      params = 'all_policies=true'
      $("#policy_show").text('Show Published')
    else
      params = 'all_policies=false'
      $("#policy_show").text('Show All')
    $.ajax
      type: 'GET'
      dataType: 'script'
      url:'/attachments' + '?' + params