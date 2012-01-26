require 'ostruct'
module Notes::TaskFolderHelper

    def render_line(line)

      div = '<div style="'

      if line.tab_count > 0
        div += "margin-left:" + line.tab_count.to_s + "em;"
      end
      #if line.line_type == :outline_header
      #  div += "font-weight:bold;"
      #elsif line.line_type == :document_title
      #  div += "font-weight:bold;"
      #end
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
        #if url[/(?:png|jpe?g|gif|svg)$/]
        #  "<img src='#{url}' />"
        #else
         "<a href='#{url}'>#{url}</a>"
        #end
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
    def get_header_data
        @views = [
          OpenStruct.new(
              :id => :notes,
              :name => "Notes",
              :action => "folder_view"
          ),
          OpenStruct.new(
              :id => :tasks,
              :name => "Tasks",
              :action => "task_view"
          ),
          OpenStruct.new(
              :id => :people,
              :name => "People",
              :action => "person_view"
          ),
          OpenStruct.new(
              :id => :events,
              :name => "Events",
              :action => "event_view"
          ),
          OpenStruct.new(
              :id => :topics,
              :name => "Topics",
              :action => "topic_view"
          )
        ]

        path = "/"
        if (!params[:path].empty?)
             path = params[:path]
        end

        # if a file exists, then show it
        if (path != "/")
          @file = current_user.file(path)
        end

        if @file.nil?
          @taskfolder = current_user.task_folder(path)

          @header = @taskfolder.shortName
          if @header.blank?
            @header = "Start"
          end

        else
          @taskfolder = @file.task_folder
          @header = @file.shortName
        end
        if !params[:person].nil?
          @header += " (" + params[:person] + ")"
        end

        if @taskfolder.nil?
           raise 'No Folder'
        end if

        @path_parts = get_path_parts(!@file.nil?, path)
        @only_path = true
        @folders = @taskfolder.task_folders
        @files = @taskfolder.todo_files
        @dataUrlBase = url_for(:controller => "task_folder", :action=>"folder_view", :path=>@taskfolder.path, :trailing_slash => true, :only_path =>true)
        @hashPageId = params[:path].sub("/","_")

        person_notes = []
        @taskfolder.get_person_notes do |note|
          person_notes.push (note)
        end

        people = []
        person_notes.each {|a|
          a.people.each {|person|
            people.push (person.downcase)
          }
        }

        @people = people.uniq

    end

    def sample_tasks
       foo = OpenStruct.new(:foo=>"bar")
       sample_tasks = tasks_by_date = [
         {
             :date_item => "January 13, 2012",
             :tasks => [
               {
                   :title => "Buy Groceries",
                   :file => OpenStruct.new(:path => "/foo",:revision_at => DateTime.now - 1.hour),
                   :lines => ["Milk","Eggs"]
               },
               {
                   :title => "Pay Bills",
                   :file => OpenStruct.new(:path => "/foo",:revision_at => DateTime.now - 1.hour),
                    :lines => ["Electricity Bill"]
               }
             ]

         },
         {
             :date_item => "January 11, 2012",
             :tasks => [
               {
                   :title => "Ski lessons",
                   :file => OpenStruct.new(:path => "/foo",:revision_at => DateTime.now - 1.week),
                    :lines => ["Eli and Lilah"]
               }
             ]

         }

       ]

     end

end
