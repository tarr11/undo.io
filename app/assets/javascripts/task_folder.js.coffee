# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  $('.edit-button').click (event) ->
    if $('.edit-button').html() == 'Save'
      $('.edit-button').html('Edit')
      $('.summary-content').show()
      $('.ace-editor').hide()
      window.editor = null
    else
      $('.summary-content').hide()
      $('.ace-editor').show()
      $('.ace-editor').width(930);
      $('.ace-editor').height(470);

      window.editor = ace.edit("editor")
      $('.edit-button').html('Save')

    #$('.timebox').click (event) ->
    #window.location =  $(event.target).attr('href')
