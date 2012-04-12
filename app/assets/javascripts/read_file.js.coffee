$ ->
  window.commentCodeMirror = CodeMirror.fromTextArea document.getElementById('comment-text-editor')
  $('.toggle-comment').each ->
    content = $(this).siblings('.comment-parent').html()
    title = $(this).siblings('.comment-parent').attr('username')
    $(this).popover 
      'title' : title,
      'content' : content,
      html : true

  $('#save-comment').click ->
    $("comment-form")
      .data('type', 'json')
      .bind('ajax:complete', ->
        $('.comment-editor').hide())
      .bind('ajax:success', (event, data, status, xhr) ->
        window.location.href = data.location)
      .bind('ajax:error', (xhr, status, error) ->
        alert error)
    
  $('.toggle-comment').hover (event) ->


  $('article').mouseup (event) ->
    return
    sel = rangy.getSelection()
    $('.comment-editor').css
      'top':event.pageY,
      'left':event.pageX
    window.commentCodeMirror.setValue sel.toString()
    $('#original_content').val(sel.toString())
    $('#line_number').val($(sel.anchorNode.parentNode).attr("line-number"))
    $('.comment-editor').show()
    window.commentCodeMirror.refresh()
