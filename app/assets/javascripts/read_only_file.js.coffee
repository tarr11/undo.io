checkAutoSave = ->
  contents = window.myCodeMirror.getValue()
  if contents != window.lastContents
    $('#edit-button').click
    window.lastContents = contents


initCodeMirror = () ->
  textArea = document.getElementById('editor')
  window.myCodeMirror = CodeMirror.fromTextArea textArea,
    mode: "undo",
    lineWrapping: true,
    readOnly:"nocursor",
    onCursorActivity : (event) ->
      token = event.getTokenAt(event.getCursor())
      if (token.string != "" && token.className != null)
        $('#status').html(token.string)
      else
        $('#status').html("")

  setInterval checkAutoSave, 10000
  window.myCodeMirror.focus()


$ ->
  initCodeMirror()
