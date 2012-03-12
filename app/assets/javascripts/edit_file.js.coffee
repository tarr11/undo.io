window.convertToSlug = (text) ->
  text.toLowerCase()
  .replace(/[^\w ]+/g,'')
  .replace(/[ ]+/g,'-')

checkAutoSave = ->
  contents = window.myCodeMirror.getValue()
  if contents != window.lastContents
    $('#edit-button').click()
    window.lastContents = contents

initCodeMirror = () ->
  textArea = document.getElementById('editor')
  if textArea == null
    return
  window.foldFunc = CodeMirror.newFoldFunction(CodeMirror.indentRangeFinder)

  collapseSection = (cm) ->
      window.foldFunc cm, cm.getCursor().line

  window.collapseAll = (cm) ->
    lineCount = cm.lineCount()
    for lineNum in [0..lineCount - 1]
      lineHandle = cm.getLineHandle(lineNum)
      if lineHandle.indentation() == 0
        window.foldFunc cm, lineNum

  window.saveDocument = (cm) ->
    window.saveNew()

  window.myCodeMirror = CodeMirror.fromTextArea textArea,
    mode: "undo",
    lineWrapping: true,
    gutter: false,
    extraKeys: {
        "Ctrl-Q": collapseSection,
        "Ctrl-M": window.collapseAll,
        "Alt-S": window.saveDocument,
        "Alt-H": window.navigateHome
        },
    onGutterClick: (cm, line, event) ->
      myCodeMirror.setCursor(line, 0)
      window.foldFunc(cm, line, event)

    onCursorActivity : (event) ->
      token = event.getTokenAt(event.getCursor())
      if (token.string != "" && token.className != null)
        $('#status').html(token.string)
      else
        $('#status').html("")
    ,
    onChange : (cm, event) ->
      if event.text[0] == "@"
        previousChar = cm.getRange({ch:event.from.ch-1, line:event.from.line}, {ch:event.from.ch, line:event.from.line})
        if previousChar == " " || previousChar == ""
          CodeMirror.simpleHint cm, CodeMirror.javascriptHint

      if event.text[0] == "/"
        CodeMirror.simpleHint cm, CodeMirror.javascriptHint


    #onHighlightComplete : (event) ->
     # $('.cm-undo-task').each (index) ->
        # just need to get the line from each item??



  window.lastContents = window.myCodeMirror.getValue()
  setInterval checkAutoSave, 1000
  window.myCodeMirror.focus()


$ ->
  initCodeMirror()
