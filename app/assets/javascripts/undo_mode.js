/**
 * Created by JetBrains RubyMine.
 * User: dougt
 * Date: 1/28/12
 * Time: 12:45 PM
 * To change this template use File | Settings | File Templates.
 */
CodeMirror.defineMode("undo", function(config, parserConfig) {
  return {
    token: function(stream, state) {

      var httpRegex = /\b(ftp|http|https):\/\/([^\s]+)/;
      var wwwRegex = /\bwww\.([^\s]+)/




      if (stream.match(httpRegex, true, true))
      {
          return "undo-link";
      }

        if (stream.match(wwwRegex, true, true))
        {
            return "undo-link";
        }

      var ch = stream.next();
      //stream.skipToEnd();
      if (ch == "!") return "undo-task";

    }
  };
});

CodeMirror.defineMIME("text/x-undo", "undo");