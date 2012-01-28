initAce = () ->
  $('#ace-editor').show()
  if typeof window.editor  == "undefined"
    window.editor = ace.edit("ace-editor")
    window.editor.getSession().setUseWrapMode(true);

initCodeMirror = () ->
  textArea = document.getElementById('editor')
  myCodeMirror = CodeMirror.fromTextArea(textArea)

$ ->
  initCodeMirror()
  $('#save-button').click (event) ->
    event.preventDefault()
    contents = window.editor.getSession().getValue();
    $('#todo_file_contents').val(contents)
    path = $('#current-path').val()
    title = contents.split('\n')[0]
    slug = convertToSlug(title)
    if slug == ''
      slug = 'new-file'

    $('#filename').val(path + "/" + slug + '.txt')
    $('#save-modal').modal('show')
    $('#filename').focus()

  $('#confirm-save-file').click (event) ->
     $('#todo_file_filename').val($('#filename').val())
     $('form').submit();


