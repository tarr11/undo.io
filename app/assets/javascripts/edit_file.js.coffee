initCodeMirror = () ->
  textArea = document.getElementById('editor')
  window.myCodeMirror = CodeMirror.fromTextArea textArea,
    mode: "undo"

  window.myCodeMirror.focus()


$ ->
  initCodeMirror()
