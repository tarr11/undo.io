initCodeMirror = () ->
  textArea = document.getElementById('editor')
  myCodeMirror = CodeMirror.fromTextArea textArea
  myCodeMirror.focus()


$ ->
  initCodeMirror()
