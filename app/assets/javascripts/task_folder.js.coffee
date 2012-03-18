# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.checkNewRightRail = false
window.saveNew = ->
  contents = window.myCodeMirror.getValue()
  $('#savecontents').val(contents)
  path = $('#current-path').val()
  title = contents.split('\n')[0]
  slug = convertToSlug(title)
  if slug == ''
    slug = 'new-file'

  $('#filename').val(path + "/" + slug)
  $('#save-modal').modal('show')

window.navigateHome = ->
  window.location.href = "/"

getNewRightRail = ->
  if window.checkNewRightRail
    window.checkNewRightRail = false
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
  $('.note-container').masonry
    itemSelector : '.note-box'

  $("a[rel=popover]")
      .popover
        html:true
      .click (e) ->
        e.preventDefault()

  $('#right-rail').delegate '.task-checkbox-in-file', 'click', (event) ->
    completedtaskRegex = /^([\s]*)x([\s]*!)/

    line_num = $(event.target).attr("line-number")

    line = window.myCodeMirror.getLine(line_num-2)
    if event.target.checked
      line = 'x' + line
    else
      line = line.replace(completedtaskRegex,"$1$2")

    window.myCodeMirror.setLine(line_num-2, line)



  $('#read-only-contents').keyup (event) ->
    if event.which == 33
      cursor = window.myCodeMirror.getCursor()
      if cursor.line == 0
        $('html, body').animate({ scrollTop: 0 }, 'slow');

  $('#read-only-contents').mouseup (event) ->
    # todo - put line number in status col so we can edit the appropriate line

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
    window.saveNew()
    event.preventDefault()

  $('#save-modal').on 'shown', (event) ->
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
      #$("#save-new-form").submit()

  $('.slide-link').click (event) ->
    $('html, body').animate({ scrollTop: 0 }, 0);
    $('.slideshow').show()
    $('.slideshow-foreground').center()
    $('.slideshow').focus()
    slide_to_show = '#slide' + $(event.target).attr('slide-index')
    window.location.hash = slide_to_show
    $(slide_to_show).show()
    return false


  $('.next-button').click (event) ->
    $('.slideshow').nextSlide('next')

  $('.prev-button').click (event) ->
    $('.slideshow').nextSlide('prev')

  $('BODY').keydown (event) ->
    # hack to deal wit hshowing slide on load not retaining focus for .slideshow
    if !$('.slideshow').is(':visible')
      return

    if event.keyCode == 27
      $('.slideshow').hide()
      window.location.hash = ''

    if event.keyCode == 37
      $('.slideshow').nextSlide('prev')

    if event.keyCode == 39
      $('.slideshow').nextSlide('next')



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

  $('#reply-button').click (event) ->
    $('#reply-form').submit()

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

  $('#share-modal').on 'shown', (event) ->
      $('#shared_user_list').focus()

  $('.cancel').click (event) ->
    $('.modal').modal('hide')

  $('#cancel-delete-file').click (event) ->
    $('#delete-modal').modal('hide')

  $('#accept-button').click (event) ->
    $('#accept-modal').modal
      keyboard: true,
      show : true

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

  $('#collapse-button').click (event) ->
    window.collapseAll(window.myCodeMirror)

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
            window.checkNewRightRail = true
          )
          .bind('ajax:error', (xhr, status, error) ->
          )
      $('#update-form').submit()

  slide_selector = '.slide-link' + window.location.hash + "-link";
  if $(slide_selector).length > 0
    $(slide_selector).click()
    window.focus()

    #$('.timebox').click (event) ->
    #window.location =  $(event.target).attr('href')

