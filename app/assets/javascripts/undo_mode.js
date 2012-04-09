CodeMirror.newFoldFunction = function(rangeFinder, markText) {
  var folded = [];
  if (markText == null) markText = '<div style="position: absolute; left: 2px; color:#600">&#x25bc;</div>%N%';

  function isFolded(cm, n) {
    for (var i = 0; i < folded.length; ++i) {
      var start = cm.lineInfo(folded[i].start);
      if (!start) folded.splice(i--, 1);
      else if (start.line == n) return {pos: i, region: folded[i]};
    }
  }

  function expand(cm, region) {
    cm.clearMarker(region.start);
    for (var i = 0; i < region.hidden.length; ++i)
      cm.showLine(region.hidden[i]);
  }

  return function(cm, line) {
    cm.operation(function() {
      var known = isFolded(cm, line);
      if (known) {
        folded.splice(known.pos, 1);
        expand(cm, known.region);
      } else {
        var end = rangeFinder(cm, line);
        if (end == null) return;
        var hidden = [];
        for (var i = line + 1; i < end; ++i) {
          var handle = cm.hideLine(i);
          if (handle) hidden.push(handle);
        }
        var first = cm.setMarker(line, markText);
        var region = {start: first, hidden: hidden};
        cm.onDeleteLine(first, function() { expand(cm, region); });
        folded.push(region);
      }
    });
  };
};


CodeMirror.isBlank = function(str)
{
    return (!str || /^\s*$/.test(str));
}

CodeMirror.indentRangeFinder = function(cm, line) {
  var handle = cm.getLineHandle(line);

  // count how many spaces start the line

  // look at each line until we find a line with that number of spaces
  // if the second line has same or less spaces return immediately
  var spaceCount = handle.indentation(cm.tabSize);

  var count = 1, lastLine = cm.lineCount(), end;
  var indentTo = null;
  for (var i = lastLine - 1; i > line ; --i) {
    var curLineHandle = cm.getLineHandle(i);
    var lineSpaceCount = curLineHandle.indentation(cm.tabSize);

    if (CodeMirror.isBlank(curLineHandle.text))
    {
        continue;
    }

    if (lineSpaceCount <= spaceCount )
    {
        indentTo = null;
    }
    else
    {
        if (indentTo == null)
        {
            indentTo = i;
        }
    }
  }

  if (indentTo == null)
  {
      return;
  }
  return indentTo + 1;
};



CodeMirror.defineMode("undo", function(config, parserConfig) {
    function ret(style, tp) {type = tp; return style;}

    return {
    token: function(stream, state) {

      var httpRegex = /^\b(ftp|http|https):\/\/([^\s]+)/;
      var wwwRegex = /^\b(www\.([^\s]+))\b/
      var tagRegex = /^(#[\w]+)\b/
      var peopleRegex = /^@[\w]+\b/
      var taskRegex = /^!/
      var completedtaskRegex = /^x[\s]*!.*/
      var dateRegex = /^(0?[1-9]|1[012])[- /.](0?[1-9]|[12][0-9]|3[01])[- /.](19|20)\d\d/
      var emailRegex = /^[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i


        var nextChar = '';
        while (!stream.eol())
        {
            if (stream.eatSpace())
            {
                return null;
            }

            if (nextChar != null && !nextChar.match(/\w/))
            {
                if (stream.match(taskRegex))
                {
                    return "undo-task";
                }

                if (stream.match(peopleRegex))
                {
                    return "undo-people";
                }
            }

            if (stream.match(emailRegex))
            {
                return "undo-email";
            }

            if (stream.match(completedtaskRegex))
            {
                return "undo-task-completed";
            }

            if (stream.match(dateRegex))
            {
                return "undo-date";
            }

            if (stream.match(wwwRegex))
            {
                return "undo-link";
            }

            if (stream.match(httpRegex))
            {
                 return "undo-link";
            }

            if (stream.match(tagRegex))
            {
                return "undo-tag";
            }


            nextChar = stream.next()

         }

//
//      if (stream.match(wwwRegex, true, true))
//      {
//           return ret("undo-link","foo");
//      }

        //stream.skipToEnd();
//          var ch = stream.next();
//          if (ch == "!") return "undo-task";

    }
  };
});

//CodeMirror.defineMIME("text/x-undo", "undo");

CodeMirror.runMode = function(string, modespec, callback) {
  var mode = CodeMirror.getMode({indentUnit: 2}, modespec);
  var isNode = callback.nodeType == 1;
  if (isNode) {
    var node = callback, accum = [];
    callback = function(string, style) {
      if (string == "\n")
        accum.push("<br>");
      else if (style)
        accum.push("<span class=\"cm-" + CodeMirror.htmlEscape(style) + "\">" + CodeMirror.htmlEscape(string) + "</span>");
      else
        accum.push(CodeMirror.htmlEscape(string));
    }
  }
  var lines = CodeMirror.splitLines(string), state = CodeMirror.startState(mode);
  for (var i = 0, e = lines.length; i < e; ++i) {
    if (i) callback("\n");
    var stream = new CodeMirror.StringStream(lines[i]);
    while (!stream.eol()) {
      var style = mode.token(stream, state);
      callback(stream.current(), style, i, stream.start);
      stream.start = stream.pos;
    }
  }
  if (isNode)
    node.innerHTML = accum.join("");
};
