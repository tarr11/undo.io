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
    $('#delete-modal').modal({
      keyboard: true,
      show : true
    })

  $('.cancel').click (event) ->
    $('#move-modal').modal('hide')


  $('#cancel-delete-file').click (event) ->
    $('#delete-modal').modal('hide')


  $('#move-button').click (event) ->
    $('#move-modal').modal
      keyboard: true,
      show : true


  $('.task-checkbox').click (event) ->
    $('#file_name').val($(event.target).attr('file_name'))
    $('#line_number').val($(event.target).attr('line_number'))
    $('#is_completed').val($(event.target).is(':checked'))
    $('form[data-remote]').submit();


  $('#complete-button').click (event) ->
    $('#file_name').val($(event.target).attr('file_name'))
    $('#line_number').val($(event.target).attr('line_number'))
    $('#is_completed').val('true')
    $('form[data-remote]').submit();
    $('#complete-button').html('Mark incomplete')


  $('#edit-button').click (event) ->
    if $('#edit-button').html() == 'Save'
      contents = window.editor.getSession().getValue();
      $('#todo_file_contents').val(contents)
      # post the form
      $("#loading").show()

      $("form[data-remote]")
          .data('type', 'html')
          .bind('ajax:complete', ->
            $("#loading").hide()
          )
          .bind('ajax:success', (event, data, status, xhr) ->
              $("#read-only-contents").html(data)
              $('#edit-button').html('Edit')
              $('#read-only-contents').show()
              $('#ace-editor').hide()
          )
          .bind('ajax:error', (xhr, status, error) ->
          )
      $('form[data-remote]').submit()

    else
      width = $('#main-body').width()
      $('#read-only-contents').hide()
      $('#ace-editor').width(width-50);
      $('#ace-editor').height(470);
      initAce()
      $('#edit-button').html('Save')

    #$('.timebox').click (event) ->
    #window.location =  $(event.target).attr('href')

