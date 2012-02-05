# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

getNewRightRail = ->
  $.ajax $('#page-path').text() + "?rail=true",
    type: 'GET'
    dataType: 'html'
    success: (data, textStatus, jqXHR) ->
        if window.lastdata != data
          window.lastdata = data
          $('#right-rail-feed').hide()
          $('#right-rail-feed').html(data)
          $('#right-rail-feed').fadeIn('slow')



$ ->

#  $('#read-only-contents').delegate ".cm-undo-link", "mouseup", (event) ->



  $('#read-only-contents').keyup (event) ->
    if event.which == 33
      cursor = window.myCodeMirror.getCursor()
      if cursor.line == 0
        $('html, body').animate({ scrollTop: 0 }, 'slow');

  $('#read-only-contents').mouseup (event) ->
    if (!event.shiftKey)
      return
    if $.trim($('#status').text()) != ""
      url = $('#status').text()
      if url.indexOf("#") == 0
        url = '?tag=' + url
      else if url.indexOf("@") == 0
        url = '?person=' + url
      else if url.indexOf('http') != 0
        url = 'http://' + url

      window.open url, '_blank'

  $('#save-new').click (event) ->
     event.preventDefault()
     contents = window.myCodeMirror.getValue()
     $('#savecontents').val(contents)
     path = $('#current-path').val()
     title = contents.split('\n')[0]
     slug = convertToSlug(title)
     if slug == ''
       slug = 'new-file'

     $('#filename').val(path + "/" + slug + '.txt')
     $('#save-modal').modal('show')
     $('#filename').focus()

  $('#confirm-save-file').click (event) ->
      $("#save-new-form")
           .data('type', 'json')
           .bind('ajax:complete', ->
              $('#save-modal').modal('hide'))
           .bind('ajax:success', (event, data, status, xhr) ->
               window.location.href = data.location)
           .bind('ajax:error', (xhr, status, error) ->
             alert error)
      $("#save-new-form").submit()


  $('#delete-button').click (event) ->
    $('#delete-modal').modal({
      keyboard: true,
      show : true
    })

  $('#publish-button').click (event) ->
    $('#publish-modal').modal({
      keyboard: true,
      show : true
    })

  $('#unpublish-button').click (event) ->
    $('#unpublish-modal').modal({
      keyboard: true,
      show : true
    })

  $('#share-button').click (event) ->
    $('#share-modal').modal({
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

  $('#copy-button').click (event) ->
    $('#copy-modal').modal
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
      contents = window.myCodeMirror.getValue()
      $('#savecontents').val(contents)
      $('#filename').val($('#current-path').val())
      # post the form
      #$("#loading").fadeIn(1000)

      $("#update-form")
          .data('type', 'json')
          .bind('ajax:complete', ->
           # $("#loading").fadeOut(2000)
          )
          .bind('ajax:success', (event, data, status, xhr) ->
               window.setTimeout getNewRightRail, 1000
#              $("#read-only-contents").html(data)
#              $('#edit-button').html('Edit')
#              $('#read-only-contents').show()
#              $('#ace-editor').hide()
          )
          .bind('ajax:error', (xhr, status, error) ->
          )
      $('#update-form').submit()


    #$('.timebox').click (event) ->
    #window.location =  $(event.target).attr('href')

