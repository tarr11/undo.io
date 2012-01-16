module TaskFolderHelper

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
