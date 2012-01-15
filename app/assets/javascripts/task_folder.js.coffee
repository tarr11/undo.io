# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
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
      #$('#ace-editor').height(470);

      $('#ace-editor').show()
      if typeof window.editor  == "undefined"
        window.editor = ace.edit("ace-editor")
#      window.editor.setTheme("ace/theme/textmate");
      $('#edit-button').html('Save')

    #$('.timebox').click (event) ->
    #window.location =  $(event.target).attr('href')
