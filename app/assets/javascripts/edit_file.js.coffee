checkAutoSave = ->
  contents = window.myCodeMirror.getValue()
  if contents != window.lastContents
    $('#edit-button').click()
    window.lastContents = contents

initCodeMirror = () ->
  textArea = document.getElementById('editor')
  window.foldFunc = CodeMirror.newFoldFunction(CodeMirror.indentRangeFinder)

  collapseSection = (cm) ->
      window.foldFunc cm, cm.getCursor().line

  window.collapseAll = (cm) ->
    lineCount = cm.lineCount()
    for lineNum in [0..lineCount - 1]
      lineHandle = cm.getLineHandle(lineNum)
      if lineHandle.indentation() == 0
        window.foldFunc cm, lineNum


  window.myCodeMirror = CodeMirror.fromTextArea textArea,
    mode: "undo",
    lineWrapping: true,
    gutter: true,
    extraKeys: {"Ctrl-Q": collapseSection, "Ctrl-M": window.collapseAll},
    onGutterClick: window.foldFunc,
    onCursorActivity : (event) ->
      token = event.getTokenAt(event.getCursor())
      if (token.string != "" && token.className != null)
        $('#status').html(token.string)
      else
        $('#status').html("")


  window.lastContents = window.myCodeMirror.getValue()
  setInterval checkAutoSave, 1000
  window.myCodeMirror.focus()


$ ->
  initCodeMirror()
