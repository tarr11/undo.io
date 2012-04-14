$ ->
  window.suggestionCodeMirror = CodeMirror.fromTextArea document.getElementById('suggestion-text-editor'),
    autoClearEmptyLines: true

  $('.toggle-suggestion').each ->
    suggestion_id = $(this).attr("suggestion-id")
    suggest_element = $('#suggestion-' + suggestion_id)
    replacement_content = suggest_element.attr('replacement-content')
    original_content = suggest_element.attr('original-content')
    content = '<div>original</div><div>' + original_content + '</div><div>Replacement</div>' + replacement_content + '</div>'
    title = suggest_element.attr('username')
    $(this).popover 
      'title' : title,
      'content' : content,
      html : true

  $('#save-suggestion').click ->
    $("suggestion-form")
      .data('type', 'json')
      .bind('ajax:complete', ->
        $('.suggestion-editor').hide())
      .bind('ajax:success', (event, data, status, xhr) ->
        window.location.href = data.location)
      .bind('ajax:error', (xhr, status, error) ->
        alert error)
    

