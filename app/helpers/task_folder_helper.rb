module TaskFolderHelper

    def render_line(line)

      div = '<div style="'

      if line.tab_count > 0
        div += "margin-left:" + line.tab_count.to_s + "em;"
      end
      if line.line_type == :outline_header
        div += "font-weight:bold;"
      elsif line.line_type == :document_title
        div += "font-size:1.5em;"
      end
      div += '">'

      if line.text.blank?
        div += "&nbsp;"
      else
        div += anchorize_line(line.text.strip)
      end

      div += "</div>"

      return div
    end

    def anchorize_line(line)
      if line.match(%r{http://}).nil?
        return line
      end

      linked = line.gsub( %r{http://[^\s<]+} ) do |url|
        if url[/(?:png|jpe?g|gif|svg)$/]
          "<img src='#{url}' />"
        else
         "<a href='#{url}'>#{url}</a>"
        end
      end

      return linked.to_s

    end

    def snippet(thought, wordcount)
      thought.split[0..(wordcount-1)].join(" ") + (thought.split.size > wordcount ? "..." : "")
    end

    def get_path_parts(isFile, path)
      parts = path.split('/')

      if (parts.length == 0)
        parts = [""]
      end

      if (isFile)
        parts.pop
      end

      path_parts = []
      incremental_part = "/"
      parts.each do |part|
          incremental_part +=  part + "/"
          path_parts.push ({
            :path => incremental_part,
            :name => part
          })
      end

      return path_parts

    end
end
