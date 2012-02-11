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

    def get_sub_folder(path, current_folder)
      nextPath = path.gsub(/^#{current_folder}/,"")
      parts = nextPath.split("/").reject{|c| c.empty?}
      return parts.first
    end

    def get_header_data


        @is_home_page = false
        if params[:username].nil?
          username = current_user.username
          #home page
          @is_home_page = true

        else
          username = params[:username]
        end

        @file_user = User.find_by_username(username)

        if @is_home_page
          @folders = []
          @files = []
          @people = []
          return
        end

        @views = [

          OpenStruct.new(
              :id => nil,
              :name => "Board",
              :querystring => nil
          ),
            OpenStruct.new(
              :id => "feed",
              :name => "Feed",
              :querystring => "feed"
          ),
          OpenStruct.new(
              :id => "tasks",
              :name => "Tasks",
              :querystring => "tasks"
          ),
          OpenStruct.new(
              :id => "events",
              :name => "Events",
              :querystring => "events"
          )
        ]

        path = "/"
        if (!params[:path].nil? && !params[:path].empty?)
             path = params[:path]
        end

        # if a file exists, then show it
        if (path != "/")
          @file = @file_user.file(path)
          unless @file.nil?
            unless @file.is_public
              unless @file.user_id == current_user.id
                unless @file.shared_with_users.include?(current_user)
                  raise ActionController::RoutingError.new('Not Found')
                end
              end
            end
          end
        end

        if @file.nil?
          @taskfolder = @file_user.task_folder(path)
          if @taskfolder.todo_files_recursive.length == 0
              raise ActionController::RoutingError.new('Not Found')
          end

          if @file_user.id != current_user.id
            raise ActionController::RoutingError.new('Not Found')
          end


          @header = @taskfolder.shortName
          if @taskfolder.shortName.blank?
            @header = "My Notes"
          end

        else
          @taskfolder = @file.task_folder
          @header = @file.shortName
        end

        if !params[:person].nil?
          @header += " (" + params[:person] + ")x"
        end


        if @taskfolder.nil?
           raise 'No Folder'
        end if

        @path_parts = get_path_parts(!@file.nil?, path)
        @only_path = true
        @folders = @taskfolder.task_folders
        @files = @taskfolder.todo_files
        @dataUrlBase = url_for(:controller => "task_folder", :action=>"folder_view", :path=>@taskfolder.path, :trailing_slash => true, :only_path =>true, :username=>username)
        @hashPageId = path.sub("/","_")

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
        @path = path
        unless @file.nil?
          @folder_path = @file.path
        else
          @folder_path = @taskfolder.path
        end
    end


    def user_path user
      url_for :controller=>"task_folder", :action => "folder_view", :username=>user.username, :path => "/"
    end

    def file_local_path file
      url_for :controller=>"task_folder", :action => "folder_view", :username=>file.user.username, :path => file.filename
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

    def get_related_tags
      tags = []
      # get a list of people, and all the notes that they are in

      these_tags = []
      @file.get_tag_notes do |note|
        note.tags.each do |tag|
          these_tags.push tag
        end
      end

      these_tags = these_tags.uniq

      current_user.task_folder("/").get_tag_notes do |note|
        if note.file.filename == @file.filename
          next
        end

        note.tags.each do |tag|
          unless these_tags.include?(tag)
            next
          end

          tags.push ({
            :tag=> tag,
            :file => note.file
          })
        end
      end

      tags = tags.uniq{|a| [a[:tag], a[:file]]}

      @these_tags = these_tags
      @related_tags = tags.group_by {|group| group[:tag]}
        .map {|key, group|
          OpenStruct.new(:name=> key,
            :files=>group.map { |b|
              OpenStruct.new(:file=>b[:file])
            }
          )
      }

      #@related_tags = tags

    end

    def get_related_people
      people = []
      # get a list of people, and all the notes that they are in

      these_peeps = []
      @file.get_person_notes do |note|
        note.people.each do |person|
          these_peeps.push person
        end
      end

      these_peeps = these_peeps.uniq

      current_user.task_folder("/").get_person_notes do |note|
        if note.file.filename == @file.filename
          next
        end

        note.people.each do |person|
          unless these_peeps.include?(person)
            next
          end

          people.push ({
            :person => person,
            :file => note.file
          })
        end
      end

      @people = people.group_by {|group| group[:person]}
        .map {|key, group|
          OpenStruct.new(:name=> key,
            :files=>group.map { |b|
              OpenStruct.new(:file=>b[:file])
            }
          )
      }

    end

    def show

       allFiles = current_user.todo_files
           .select do |file|
             file.tasks.length > 0
           end

       rows = allFiles.map do |file|
         file.tasks.map do |line|
           {
             :todofile => file ,
             :task => line
           }
         end
       end

       @files = rows.first(2)

       path = "/"
       if (!params[:path].empty?)
            path = params[:path]
       end

       @taskfolder = current_user.task_folder(path)
       @topfolders = @taskfolder.task_folders.push(@taskfolder)
       @topfolders.sort_by!{|a| a.path.downcase}

       range = params[:range]

       @startDate = params[:start] ||= Date.today - 100.years
       @endDate = params[:end] ||= DateTime.now.utc

       #case range
       #
       #  when "hour"
       #    @startDate = DateTime.now.utc - 1.hour
       #    @endDate = DateTime.now.utc
       #  when "today"
       #    @startDate = Date.today
       #    @endDate = DateTime.now.utc
       #  when "yesterday"
       #    @startDate = Date.yesterday
       #    @endDate = Date.today
       #  when "3days"
       #    @startDate = Date.today- 3.days
       #    @endDate = DateTime.now.utc
       #  when "week"
       #    @startDate = Date.today - 7.days
       #    @endDate = DateTime.now.utc
       #  when "month"
       #    @startDate = Date.today - 1.month
       #    @endDate = DateTime.now.utc
       #  else
       #    @startDate = Date.today - 100.years
       #    @endDate = DateTime.now.utc
       #end



       changedNotes = []

       @rows = 0
       @matrix = Hash.new
       @changes = Hash.new
       @topfolders.each_with_index do |folder, col|
         folder.all.each_with_index do |item, row|
           # don't show any folders in the first column, since they are already in the row'
   #        if (folder.name == path && item.class.to_s == "TaskFolder")
   #            next
   #        end

           changes = item.getChanges(@startDate , @endDate)
           if (changes.length > 0)
             note =
             {
               :changes => changes,
               :folder => folder,
               :item => item
             }

             changedNotes.push note
           end
         end
       end

       @count = changedNotes.length

       sortedColumnItems = []
       datesortedNotes = changedNotes.group_by {|note| note[:file].revised_at.strftime "%m/%d/%Y" }
         .each do |date, notes|
            sortedColumnItems.push(
             {
               :date => date,
               :count =>notes.count
             }
            )
       end

       @columnItems = sortedColumnItems
         .sort_by{|a| [ (a[:folder].name == "/" ? 2 : 1), a[:count]] }
         .reverse

       #@columnItems =  changedNotes.uniq{|a| a[:folder].name}

       # summary rows, these are the
       @columnItems.each_with_index do |folder, col |

         changes = folder[:folder].getChanges(@startDate, @endDate)
         #@matrix[[col,0]] = {
         #    :changes => changes,
         #    :folder =>folder,
         #    :item => folder[:folder]
         #}
       end

       @columnItems.each_with_index do |folder, col |
           rows = changedNotes.select{ |note|
             note[:folder] == folder[:folder]
           }

           rows.each_with_index do |item, row|
               realrow = row
               @matrix[[col,realrow ]] = item
               if (realrow > @rows)
                 @rows = realrow
               end
           end

       end

       @ranges = [
           {
                :name => "Today",
                :range => "today"
            },
            {
               :name => "Yesterday",
               :range => "yesterday"
           },
            {
               :name => "Last 3 Days",
               :range => "3days"
           },
            {
               :name => "Last 7 Days",
               :range => "3days"
           },
            {
               :name => "Last Month",
               :range => "month"
           },
            {
               :name => "All",
               :range => "all"
           },



       ]

       sample_timeline = [
           {
               :revision_date => DateTime.now,
               :start_date =>DateTime.now,
               :end_date=>Date.today,
                :label => "Now",
               :width => 100
           },
           {
               :revision_date => Date.today,
               :label => "Today",
               :width => 100,
               :start_date =>DateTime.now,
               :end_date=>Date.today
           },
           {
               :revision_date => Date.yesterday,
               :label => "Yesterday",
               :width=> 300,
               :start_date =>DateTime.now,
               :end_date=>Date.today
           },
           {
               :revision_date => Date.today - 7.days,
               :label => "Last Week",
               :width=> 400             ,
               :start_date =>DateTime.now,
               :end_date=>Date.today
           },
           {
               :revision_date => Date.today - 1.year,
               :label => "Last year",
               :width=> 1000             ,
               :start_date =>DateTime.now,
               :end_date=>Date.today
           }


       ]


       diffs = []

       changedNotes.each do |note|
         note[:changes].each do |change|
           change[:diff].each do |line|
             if (!change[:revision_at].nil?)
               diffs.push ({
                   :line => line,
                   :revision_at => change[:revision_at]
               })
             end

           end
         end
       end

       segments = 4

       diffs = diffs.sort_by{|a| a[:revision_at]}
       startDiff = diffs.first[:revision_at].to_datetime
       endDiff = diffs.last[:revision_at].to_datetime


       totalDays = (endDiff - startDiff).to_i
       #totalDays = startDiff.to_s + " " + endDiff.to_s

       segment_days = totalDays / segments.to_f

       recs_per_segment = (diffs.length / segments).to_i

       datemarkers = []
       # record count normalized
       #(0.upto(segments-1)).each do |index|
       #  startDate = diffs[recs_per_segment*index][:revision_at]
       #  endIndex = recs_per_segment*(index+1)
       #  if (diffs.length > endIndex)
       #    endDate = diffs[endIndex][:revision_at]
       #  else
       #    endDate = diffs[diffs.length - 1][:revision_at]
       #  end
       #  datemarkers.push( { :start_date => startDate, :end_date => endDate })
       #end

       # date normalized
       (0.upto(segments-1)).each do |index|
          endDate= endDiff - ( ((index)*segment_days).to_f ).days
          startDate = endDate - segment_days.days
          datemarkers.push( { :start_date => startDate, :end_date => endDate })
         if (startDate <= startDiff)
           break
         end
        end


       @timeline = []

       #datemarkers = datemarkers.reverse
       datemarkers.each do |marker|

         # percent total is the # of records between start and enddate
         count = diffs.select{|a| (a[:revision_at] >= marker[:start_date]) && (a[:revision_at] <= marker[:end_date])}.length



         percentTotal = [(count.to_f / diffs.length.to_f),0.05].max

           @timeline.push({
               :start_date =>marker[:start_date],
               :end_date=>marker[:end_date],
               :percentTotal => percentTotal,
               :count => count,
               :text => diffs.select{|a| a[:revision_at] >= startDiff && a[:revision_at] <= endDiff}.length,
               :endDiff => endDiff,
               :startDiff => startDiff
           })

       end


       #datemarkers.each do |marker|
       #
       #  days = (marker[:end_date].to_datetime - marker[:start_date].to_datetime).to_f
       #  percentTotal = (days / totalDays).to_f
       #
       #    @timeline.push({
       #        :start_date =>marker[:start_date],
       #        :end_date=>marker[:end_date],
       #        :percentTotal => percentTotal,
       #    })
       #
       #end


       #@timelineChanges = diffs
       #@timeline = sample_timeline

       if (params[:path] != "/")

         path = params[:path].split("/")
         path.pop
         if (path.length <= 1)
           @uplevel = "/"
         else
           @uplevel = path.join("/")
         end
       end

       @cols = @columnItems.length

       respond_to do |format|
         format.html # index.html.erb
         format.json { render json: @files}
       end


     end



end
