initCodeMirror = () ->
  textArea = document.getElementById('editor')
  window.myCodeMirror = CodeMirror.fromTextArea(textArea)

$ ->
  initCodeMirror()


