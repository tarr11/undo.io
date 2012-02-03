/**
 * Created by JetBrains RubyMine.
 * User: dougt
 * Date: 1/28/12
 * Time: 12:45 PM
 * To change this template use File | Settings | File Templates.
 */
CodeMirror.defineMode("undo", function(config, parserConfig) {
    function ret(style, tp) {type = tp; return style;}

    return {
    token: function(stream, state) {

      var httpRegex = /^\b(ftp|http|https):\/\/([^\s]+)/;
      var wwwRegex = /^\b(www\.([^\s]+))\b/
      var tagRegex = /^(#[\w]+)\b/
      var peopleRegex = /^(@[\w]+)\b/
      var taskRegex = /^(![\w]+)\b/


        while (!stream.eol())
        {
            if (stream.sol())
            {
                if (stream.match(taskRegex))
                {
                    return "undo-task";
                }
            }
            if (stream.eatSpace())
            {
                return null;
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

            if (stream.match(peopleRegex))
            {
                return "undo-people";
            }

            stream.next()

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

CodeMirror.defineMIME("text/x-undo", "undo");

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