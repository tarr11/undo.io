window.convertToSlug = (text) ->
  text.toLowerCase()
  .replace(/[^\w ]+/g,'')
  .replace(/[ ]+/g,'-')

$('.right-rail-container').masonry
  itemSelector : '.note-box-3x5'

checkAutoSave = ->
  contents = window.myCodeMirror.getValue()
  if contents != window.lastContents
    $('#edit-button').click()
    window.lastContents = contents
	window.checkNewRightRail = true
	
populateTopics = (topics) ->
  remove_unreferenced_topics topics
  render_topic topic for topic in topics
  $('.right-rail-container').masonry  
    itemSelector : '.note-box-3x5'

remove_unreferenced_topics = (topics) ->
  topic_ids = (snippet.snippet_id for snippet in topics)
  to_remove = []
  $('.note-box').each ->
    if not (this.id in topic_ids)
      to_remove.push this 

  $('.right-rail-container').masonry('remove', $(note_box)) for note_box in to_remove
  $(note_box).remove() for note_box in to_remove
  $('.right-rail-container').masonry  
    itemSelector : '.note-box-3x5'

render_topic = (topic) ->
  snippet = $(topic.snippet)
  if $('#' + topic.snippet_id).length == 0
    $('.right-rail-container').prepend snippet
    $('.right-rail-container').masonry 'appended', snippet

getNewRightRail = ->
  if window.checkNewRightRail
    window.checkNewRightRail = false
    if $('#card-view').length > 0
      $.ajax $('#page-path').text() + "?cards=true",
        type: 'GET'
        dataType: 'json'
        success: (data, textStatus, jqXHR) ->
          populateTopics data
    else if $('#task-view').length > 0
      $.ajax $('#page-path').text() + "?part=tasks",
        type: 'GET'
        success: (data, textStatus, jqXHR) ->
          $('#task-view').html(data)
    else if $('#event-view').length > 0
      $.ajax $('#page-path').text() + "?part=events",
        type: 'GET'
        success: (data, textStatus, jqXHR) ->
          $('#event-view').html(data)
    else if $('#slide-view').length > 0
      $.ajax $('#page-path').text() + "?part=slides",
        type: 'GET'
        success: (data, textStatus, jqXHR) ->
          $('#slide-view').html(data)

initCodeMirror = () ->
  window.checkNewRightRail = false
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

  autocomplete = (editor, results) ->
    cur = editor.getCursor()
    token = editor.getTokenAt(cur)
    
    regex_string = ".*"
    for index in [0..(token.string.length - 1)]
      regex_string = regex_string + token.string[index] + ".*"
      
    regex = new RegExp(regex_string)
    matches = (tag for tag in results when tag.match regex )
    "list" : matches,
    "from" :
        "line": cur.line,
        "ch": token.start,
    "to" :
        "line": cur.line,
        "ch": token.end

  window.get_user_files = (editor) ->
    autocomplete editor, window.user_files

  window.get_user_tags = (editor) ->
    cur = editor.getCursor()
    token = editor.getTokenAt(cur)
    
    regex_string = ".*"
    for index in [0..(token.string.length - 1)]
      regex_string = regex_string + token.string[index] + ".*"
      
    regex = new RegExp(regex_string)
    matches = (tag for tag in window.user_tags when tag.match regex )
    "list" : matches,
    "from" :
        "line": cur.line,
        "ch": token.start,
    "to" :
        "line": cur.line,
        "ch": token.end

  window.myCodeMirror = CodeMirror.fromTextArea textArea,
    mode: "undo",
    lineWrapping: true,
    gutter: false,
    autoClearEmptyLines: true,
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
      if event.text[0] == "#"
        CodeMirror.simpleHint cm, window.get_user_tags
          
      if event.text[0] == "/"
        CodeMirror.simpleHint cm, window.get_user_files
      #if event.text[0] == "@"
       # previousChar = cm.getRange({ch:event.from.ch-1, line:event.from.line}, {ch:event.from.ch, line:event.from.line})
       # if previousChar == " " || previousChar == ""
       #   CodeMirror.simpleHint cm, CodeMirror.javascriptHint

      #if event.text[0] == "/"
       # CodeMirror.simpleHint cm, CodeMirror.javascriptHint


    #onHighlightComplete : (event) ->
     # $('.cm-undo-task').each (index) ->
        # just need to get the line from each item??


  window.lastContents = window.myCodeMirror.getValue()
  window.myCodeMirror.refresh()
  setInterval checkAutoSave, 1000
  setInterval getNewRightRail, 1000
  window.myCodeMirror.focus()


$ ->
  initCodeMirror()
  $.ajax $('#page-path').text() + "?tags=true",
      type: 'GET'
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        window.user_tags = data 

  $.ajax $('#page-path').text() + "?files=true",
      type: 'GET'
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        window.user_files = data 
