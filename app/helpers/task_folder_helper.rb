module TaskFolderHelper
  require 'ostruct'

  def get_file_from_path(path)
    TaskFolder.get_file_from_path(path)
  end

  def get_file_from_path_escaped(path)
    path = CGI::unescape(path)
    TaskFolder.get_file_from_path(path)
  end

  def get_public_checkbox_checked
    if @file.is_public?
      return "CHECKED"
    end

  end

  def get_shared_user_list

    if @file.reply_to.nil?
      return ""
    end
    users = []
    user = @file.reply_to.user
    if user.is_registered?
      users.push user.username
    else
      users.push user.unverified_email
    end
    return users.join(",")
  end

  def render_line(line, line_number)

      div = '<div line-number="' + line_number.to_s + '" style="'

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

      if path.nil?
        return []
      end
      parts = path.split('/')

      if (parts.length == 0)
        parts = [""]
      end

      if (isFile)
        parts.pop
      end

      path_parts = []

      incremental_part = ""
      parts.each do |part|
          if part.blank? 
            incremental_part += "" 
          else
            incremental_part += ("/" + part)
          end
          path_parts.push ({
            :path => incremental_part,
            :name => part
          })
      end

      return path_parts

    end

  def get_folder_name(folder_item)
    header_name = folder_item.first.nil? ? folder_item.second.first.task_folder.shortName: folder_item.first
    if header_name.blank?
        header_name = "/"
    end
    return header_name

  end

  def get_folder_username (folder_item)
    if @wildcard_user_name
        user_name = "public"
    else
        user_name = folder_item.second.first.user.username
    end
    return user_name

  end
  def get_sub_folder(path, current_folder)
    nextPath = path.gsub(/^#{current_folder}/,"")
    parts = nextPath.split("/").reject{|c| c.empty?}
    return parts.first
  end


  def get_changed_files_by_date files
    return files
          .group_by {|note| note.revision_at.strftime "%A, %B %e, %Y" }
          .sort_by {|date| [Date.strptime(date.first, "%A, %B %e, %Y")]}
          .reverse
  end

  def user_owns_file file, current_user
    return false if current_user.nil?
    return file.user.id == current_user.id
  end

  def is_copied_to_reply(file)
    return false if current_user.nil?
    file.copied_to.any?{|a| a.user_id == current_user.id}
  end

  def is_copied_from_reply(file)
    return false if current_user.nil?
    return !file.copied_from.nil?  && file.user.id != current_user.id && file.copied_from.user_id == current_user.id
  end
  def get_changed_files_by_folder files, path

    grouped_files = files
    .group_by {|note| get_sub_folder(note.path, path)}
    .sort_by {|folder_item| folder_item.second.map{|a| a.revision_at}.max}
    .reverse

    return grouped_files

  end


    def get_views
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

      @note_views = [

          OpenStruct.new(
              :id => nil,
              :name => "My Notes",
              :querystring => nil
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
          ),
          OpenStruct.new(
              :id => "slides",
              :name => "Slides",
              :querystring => "slides"
          )
        ]

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

        path = "/"
        get_views
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
	
            if @taskfolder.files.length == 0 && path != "/"
                raise ActionController::RoutingError.new('Not Found')
            end

            if !owned_by_user?(@taskfolder)
              @taskfolder.show_public_only()
            end

            @header = @taskfolder.shortName
            if @taskfolder.shortName.blank?
              if !owned_by_user?(@taskfolder)
                @header = (@file_user.display_name ||= @file_user.username) + "'s Public Notes"
              else
                @header = "My Notes"

              end
            end

        else
          @taskfolder = @file.task_folder
          @header = @file.shortName
          @user_who_wrote_this = @file.user_who_wrote_this

        end


        unless params[:shared].nil?
          @taskfolder.show_shared_only();
          if current_user.alerts.length > 0
            current_user.alerts.destroy_all
          end
        end
        check_for_shared_notes

        if !params[:person].nil?
          @header += " (" + params[:person] + ")x"
        end

        if @taskfolder.nil?
           raise 'No Folder'
        end if

        @path_parts = get_path_parts(!@file.nil?, path)
        @only_path = true
        @folders = @taskfolder.task_folders
        @files = @taskfolder.files
        @files_alpha_sorted = @taskfolder.todo_files_immediate.sort_by{|a| a.shortName.downcase}.to_a
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
          if !current_user.nil?  && @file.user_id != current_user.id
            # check if there's a user copy
            @user_copy = current_user.todo_files.find_by_copied_from_id(@file.id)
            if @user_copy.nil? && !@file.copied_from.nil?
              if @file.copied_from.user_id == current_user.id
                @user_copy = @file.copied_from
              end

            end
          end
        else
          @folder_path = @taskfolder.path
        end
    end


    def check_for_shared_notes
      if user_signed_in?
        if current_user.alerts.length > 0
          @has_new_shared_notes = true
        end
      end

    end

    def team_active_class
      
    end

    def inbox_active_class
      return "" if current_user.nil?
      return (params[:username] == current_user.username && params[:shared] == "y" ? "active" : nil)
    end
    def my_notes_active_class
      return "" if current_user.nil?
      return ((!@is_public && params[:username].nil?  || (params[:username] == current_user.username && params[:shared] == nil)) ? "active" : nil)
    end

    def public_notes_active_class
      return "" if current_user.nil?
      return ((params[:username] != current_user.username && @is_public) ? "active" : nil)
    end
    def user_path user
      return "" if current_user.nil?
      url_for :controller=>"task_folder", :action => "folder_view", :username=>user.user_folder_name, :path => "/"
    end

    def inbox_path
      return "" if current_user.nil?
      return url_for(:controller=>"task_folder", :action => "folder_view", :username=>current_user.username, :path => "/", :shared=>"y")
    end

    def task_folder_local_path folder
      url_for :controller=>"task_folder", :action => "folder_view", :username=>folder.user.user_folder_name, :path => folder.path
    end

    def file_local_path file
      url_for :controller=>"task_folder", :action => "folder_view", :username=>file.user.user_folder_name, :path => file.filename, :only_path=>true
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



    def get_related_tasks
      @tasks_grouped = []

      return [] if current_user.nil?

      task_list = @file.to_enum(:get_tasks).to_a

      @task_count = task_list.length
      @tasks = task_list.group_by{|a| a.parent}

      # roll up everything is nil
      temp_groups = @tasks
      while(true)
        temp_groups.select{|a| a.nil?}.each{|a| @tasks_grouped.push(a)}
        temp_groups = temp_groups.select{|a| !a.nil?}.group_by{|a| (a.first.parent)}
        if temp_groups.length == 0
          break
        end
      end

      @tasks_grouped = @tasks_grouped.reverse



    end

    def get_slideshow

      slideshow = Slideshow.new(@file)

      @slides = slideshow.slides
      #@slides = @file.formatted_lines.select{|a| a.parent.nil? && !a.text.blank?}
      #.map {|a|
      #    Slide.new(a)
      #}


    end

    def get_replies
      @replies = []
      @file.replies
        .each{ |a|
          activity = FileActivity.new
          activity.activity_type = :replies
          activity.file = a
          activity.user = a.user_who_wrote_this
          activity.summary= a.summary
          activity.published_at = a.revision_at||=DateTime.now
          @replies.push(activity)
      }
      @replies = @replies.sort_by{|a| a.published_at}.reverse

    end

    def get_suggestions
      @suggestions = @file.suggestions.sort_by{|a| a.created_at}.reverse
    end

  def owned_by_user?(file_or_folder)
    return false if current_user.nil?
    return file_or_folder.user_id == current_user.id
  end
   def get_shared_with
     @shared_with = @file.sent_to
   end
    def get_tagged
            # files with the same tags in any folder of mine
      @tagged = []
      return [] if current_user.nil?

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

        matching_tags = note.tags.select{|tag| these_tags.include?(tag)}
        if matching_tags.length == 0
          next
        end

        activity = FileActivity.new
        activity.activity_type = :same_tag
        activity.file = note.file
        activity.summary= matching_tags
        activity.tags = matching_tags
        activity.published_at = note.file.revision_at
        @tagged.push(activity)
      end
    end

    def get_same_folder
      @same_folder_notes = []
      return [] if current_user.nil?

      # copies that have been published
      # files in the same folder
      current_user.task_folder(@file.task_folder.path).todo_files_immediate.each do |file|
          if file.filename != @file.filename
            activity = FileActivity.new
            activity.activity_type = :same_folder
            activity.file = file
            activity.summary= ""
            activity.published_at = file.revision_at
            @same_folder_notes.push(activity)
          end
      end
      #
      @same_folder_notes = @same_folder_notes.sort_by{|a| a.published_at}.reverse
      # files that link to this file directly (either publicly or privately)


    end

    def get_related_events

      @events = @file.slideshow.to_enum(:get_events).to_a

    end

    def get_related_tags(user_requesting_access)

      @related_tags = @file.get_related_tag_notes(user_requesting_access)

    end

    def get_cards(user_requesting_access)
      cards = [] 

      tags = @related_tags.map do |key, group|
        {
          :key => key,
          :card_type => :tag,
          :files => group.map{|a| a.file}
        }
      end

      files = @file.get_linked_files(user_requesting_access).map do |file|
        {
          :key => file.shortName,
          :card_type => :file,
          :files =>[file] 
        }
      end

      cards.concat tags
      cards.concat files
      @cards = cards

    end

    def get_cards_with_snippets

      @cards.map do |card|
        
        {
          :key => card[:key],
          :card_type => card[:card_type],
          :snippet_id => 'snippet_' + card[:key],
          :snippet => render_to_string(:partial => 'task_folder/snippet', :locals => {:key=>card[:key], :group=>card[:files],:show_avatar=>false,:show_public_path=>false,:note_class=>"note-box-3x5"})
        }
      end

    end

    def get_related_people
      people = []
      # get a list of people, and all the notes that they are in

      return [] if current_user.nil?
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


    def get_formatted_lines_for_viewer
      suggestioned_content = TodoFile.apply_suggestions(@file.contents, @file.suggestions)
      TodoFile.formatted_lines  suggestioned_content 
    end

end
