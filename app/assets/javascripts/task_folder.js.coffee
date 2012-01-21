# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
initAce = () ->
  $('#ace-editor').show()
  if typeof window.editor  == "undefined"
    window.editor = ace.edit("ace-editor")
    window.editor.getSession().setUseWrapMode(true);

$ ->
  $('#delete-button').click (event) ->
    $('#delete-modal').modal('show')

  $('#cancel-delete-file').click (event) ->
    $('#delete-modal').modal('hide')

  $('.task-checkbox').click (event) ->
    $('#file_file_name').val($(event.target).attr('file_name'))
    $('#file_line_number').val($(event.target).attr('line_number'))
    $('#file_is_completed').val($(event.target).checked)
    $('form[data-remote]').submit();


  $('#edit-button').click (event) ->
    if $('#edit-button').html() == 'Save'
      contents = window.editor.getSession().getValue();
      $('#todo_file_contents').val(contents)
      # post the form
      $('form[data-remote]').submit();
      $('#edit-button').html('Edit')
      $('#read-only-contents').text(contents)
      $('#read-only-contents').show()
      $('#ace-editor').hide()
    else
      width = $('#main-body').width()
      $('#read-only-contents').hide()
      $('#ace-editor').width(width-50);
      $('#ace-editor').height(470);
      initAce()
      $('#edit-button').html('Save')

    #$('.timebox').click (event) ->
    #window.location =  $(event.target).attr('href')

