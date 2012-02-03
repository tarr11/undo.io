checkAutoSave = ->
  contents = window.myCodeMirror.getValue()
  if contents != window.lastContents
    $('#edit-button').click()
    window.lastContents = contents

initCodeMirror = () ->
  textArea = document.getElementById('editor')
  window.myCodeMirror = CodeMirror.fromTextArea textArea,
    mode: "undo",
    lineWrapping: true,
    onCursorActivity : (event) ->
      token = event.getTokenAt(event.getCursor())
      if (token.string != "" && token.className != null)
        $('#status').html(token.string)
      else
        $('#status').html("")


  window.lastContents = window.myCodeMirror.getValue()
  setInterval checkAutoSave, 1000
  window.myCodeMirror.focus()

  setInterval getNewRightRail, 5000


$ ->
  initCodeMirror()
