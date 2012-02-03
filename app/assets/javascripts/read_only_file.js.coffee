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



  window.myCodeMirror.focus()


$ ->
  initCodeMirror()
