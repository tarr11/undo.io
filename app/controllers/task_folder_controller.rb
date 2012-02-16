class TaskFolderController < ApplicationController
  before_filter :authenticate_user!
  include Notes::TaskFolderHelper
  include Notes
  def mark_task_completed
    current_user.file(params[:file_name]).mark_task_status(params[:line_number].to_i, params[:is_completed] == "true")
    respond_to do |format|
      format.html { head :ok }
      format.json { head :ok }
      format.js
    end
  end

  def home_view

   @public_files = TodoFile.find_by_is_public(true, :order=>"REVISION_AT desc")
    respond_to do |format|
       format.html {render 'home_view', :layout => 'task_folder'}
    end

  end

  def create
    @todo_file = current_user.todo_files.new(:filename => params[:filename], :contents => params[:save_new_contents], :is_public => false)
    @todo_file.revision_at = DateTime.now.utc

    if !@todo_file.filename.starts_with?("/")
      @todo_file.filename = "/" + @todo_file.filename
    end

    respond_to do |format|
      if @todo_file.save
        DropboxNavigator.delay.UpdateFileInDropbox(@todo_file)
        format.html { redirect_to :controller=>'task_folder', :action=>'folder_view', :username=>current_user.username, :path=> @todo_file.filename, notice: 'File was successfully created.' }
        format.json { render json: @todo_file, status: :created}
      else
        format.html { render action: "new" }
        format.json { render json: @todo_file.errors, status: :unprocessable_entity }
      end
    end

  end

  def publish
    get_header_data
    current_user.file(@file.filename).make_public()
    respond_to do |format|
      format.html {redirect_to :controller => "task_folder", :action=>"folder_view", :path=> @file.filename, :only_path=>true, :username =>@file.user.username }
    end

  end

  def unpublish
    get_header_data
    current_user.file(@file.filename).make_private()
    respond_to do |format|
      format.html {redirect_to :controller => "task_folder", :action=>"folder_view", :path=> @file.filename, :only_path=>true, :username =>@file.user.username }
    end

  end

  def create_or_update
    filename = params[:filename]
    @todo_file = current_user.todo_files.find_by_filename(filename)
    if @todo_file.nil?
      @todo_file = current_user.todo_files.new(:filename => params[:filename], :contents => params[:savecontents], :is_public => false)
      @todo_file.revision_at = DateTime.now.utc
      if !@todo_file.filename.starts_with?("/")
        @todo_file.filename = "/" + @todo_file.filename
      end
    else
      @todo_file.contents = params[:savecontents]
    end
    if @todo_file.save
      DropboxNavigator.delay.UpdateFileInDropbox(@todo_file)
      respond_to do |format|
        format.json  { render json: {"location" => url_for(:controller => "task_folder", :action=>"folder_view", :path=> @todo_file.filename, :only_path=>true, :username =>@todo_file.user.username)}}
      end
    else
      respond_to do |format|
        format.html { render action: "new" }
        format.json { render json: @todo_file.errors, status: :unprocessable_entity }
      end
    end

  end

  def update

    if params[:method] == "publish"
      publish
    elsif params[:method] == "unpublish"
      unpublish
    elsif params[:method] == "move"
      move
    elsif params[:method] == "copy"
      copy
    elsif params[:method] == "share"
      share
    else
      create_or_update
    end

  end

  def new_file

    @file = TodoFile.new
    @file_user = current_user
    @file.user = current_user
    @is_new_file = true
    @owned_by_user  = true
    respond_to do |format|
      format.html { render '_note_view', :layout => 'application'}
    end

  end

  def move
    get_header_data
    # if this is a file. move it
    unless @file.nil?
      oldName = @file.filename
      @file.filename = params[:filename]
      if @file.save
        DropboxNavigator.delay.move_file oldName, @file
        respond_to do |format|
          format.html { redirect_to :controller=>'task_folder', :action=>'folder_view', :path=> @file.filename, :username=>@file.user.username, notice: 'File was moved.' }
        end
      end
    end

    unless @taskfolder.nil?
      oldName = @taskfolder.path
      # find all files in this path, and change their names
      # TODO: deal with overwriting
      end
  end

  def share
    get_header_data
    # if this is a file. move it
    unless @file.nil?

      people = @file.get_people
      people.each do |person|
        user = User.find_by_username(person)
        unless user.nil?
          user.shared_files.create! :todo_file => @file
          #shared_file = @file.shared_with_users.create(:user => user)
          #shared_file.save
        end

      end
      respond_to do |format|
        format.html { redirect_to :controller=>'task_folder', :action=>'folder_view', :path=> @file.filename, :username=>@file.user.username, notice: 'File was shared.' }
      end

    end

    unless @taskfolder.nil?
      oldName = @taskfolder.path
      # find all files in this path, and change their names
      # TODO: deal with overwriting


      end

  end

  def copy
      get_header_data
      # if this is a file. move it
      unless @file.nil?

        @new_file= current_user.todo_files.new
        @new_file.filename = params[:copy_filename]
        @new_file.contents = @file.contents
        @new_file.user = current_user
        @new_file.revision_at = DateTime.now
        @new_file.is_public = false
        @new_file.copied_from_id = @file.id

        if @new_file.save!
          DropboxNavigator.delay.UpdateFileInDropbox(@new_file)
          respond_to do |format|
            format.html { redirect_to :controller=>'task_folder', :action=>'folder_view', :path=> @new_file.filename, :username=>@new_file.user.username, notice: 'File was copied.' }
          end
        else
          @errors = @new_file.errors
          folder_view
        end
      end

      unless @taskfolder.nil?
        oldName = @taskfolder.path
        # find all files in this path, and change their names
        # TODO: deal with overwriting


        end
    end


  def task_file_view

  end

  def task_view

    tasks = []
    if !@file.nil?
      @file.get_tasks{|a| tasks.push (a)}
      if !params[:line_number].nil?
        @task = tasks.find{|a| a.line_number == params[:line_number].to_i}
        @show_list_view = false
        @header = "Task:" + @task.title
        #@path_parts.push ({
        #    :path => "",
        #    :name => "Line " + @task.line_number.to_s
        #    })
      else
        @show_list_view = true
      end
    else
      @taskfolder.get_tasks{|a| tasks.push (a)}
      @show_list_view = true
    end


    @tasks_by_date = tasks
      .select {|task| !task.completed}
      .group_by {|task| task.file.revision_at.strftime "%A, %B %e, %Y" }
            .sort_by {|date| [Date.strptime(date.first, "%A, %B %e, %Y")]}
            .reverse

    respond_to do |format|
      format.html {render 'task_folder/task_view'}
    end


  end

  def person_view
    get_header_data
    lines = []
    if !@file.nil?
      @file.get_person_notes do |line|
        lines.push line
      end
    else
      @taskfolder.get_person_notes do |line|
        lines.push line
      end
    end

    if !params[:person].nil?
      lines = lines.select{|a| a.people.include?(params[:person])}
    end

    @notes_by_date = lines
      .group_by {|line| line.file.revision_at.strftime "%A, %B %e, %Y" }
            .sort_by {|date| [Date.strptime(date.first, "%A, %B %e, %Y")]}
            .reverse

  end

  def event_view
    lines = []
      if !@file.nil?
        @file.get_event_notes do |line|
          lines.push line
        end
      else
        @taskfolder.get_event_notes do |line|
          lines.push line
        end
      end

      #if !params[:person].nil?
      #  lines = lines.select{|a| a.people.include?(params[:person])}
      #end

      @notes_by_date = lines
        .select {|line| line.event.start_at > Date.today}
        .group_by {|line| line.event.start_at.strftime "%A, %B %e, %Y" }
              .sort_by {|date| [Date.strptime(date.first, "%A, %B %e, %Y")]}


    respond_to do |format|
      format.html {render 'task_folder/event_view'}
    end

  end

  def topic_view
    get_header_data

  end

  def note_feed
    get_header_data
  end


  def folder_view

    get_header_data
    if params[:view] == "tasks"
      task_view
    elsif params[:view] == "events"
      event_view
    elsif params[:view] == "feed"
      feed_view
    else
      if @file.nil?
        board_view
      else
        note_view
      end
    end
  end

  def board_view

    start_date= Date.today - 100.years
    end_date = DateTime.now.utc
    if (params[:q].nil?)
      changed_files = @taskfolder.get_file_changes(start_date, end_date)
    else
      changed_files = @taskfolder.search_for_changes(params[:q])
    end
    @changed_files_by_folder = changed_files
      .group_by {|note| get_sub_folder(note[:file].path,@taskfolder.path)}
      .sort_by {|folder_item| folder_item.second.map{|a| a[:file].revision_at}.max}
      .reverse
    respond_to do |format|
        format.html { render 'task_folder/boxed_view', :layout => 'task_folder', :wildcard_user_name=>false}
    end
  end

  def feed_view
    if current_user.username != params[:username]
      respond_to do |format|
        format.html { render 'public_folder_view', :layout=>'application'}
      end
      return
    end
    start_date= Date.today - 100.years
    end_date = DateTime.now.utc

    if (start_date.nil?)
      start_date = Time.zone.now.beginning_of_day - 1.week
    end

    if (end_date.nil?)
      end_date = Time.zone.now
    end

    unless (params[:q].nil?)
      changed_files = @taskfolder.search_for_changes(params[:q])
    else
      changed_files = @taskfolder.get_file_changes(start_date, end_date)
    end


    @changed_files_by_date = changed_files
      .group_by {|note| note[:file].revision_at.strftime "%A, %B %e, %Y" }
      .sort_by {|date| [Date.strptime(date.first, "%A, %B %e, %Y")]}
      .reverse

    @tasks = []

    respond_to do |format|
      format.html # index.html.erb
      format.mobile
    end

  end


  def note_view

    get_related_people
    get_related_tags
    get_related_events
    get_related_tasks
    get_slideshow
    get_notestream

    if @file.user.id == current_user.id
      @owned_by_user = true
    else
      @owned_by_user = false
    end

    unless params[:compare].nil?
      parts = params[:compare].split('/')
      parts = parts.reverse
      parts.pop
      compare_user_name = parts.last
      parts.pop
      parts = parts.reverse
      compare_file_name = "/" + parts.join("/")
      compare_user = User.find_by_username(compare_user_name)
      logger.info compare_file_name
      @compare_file = compare_user.file(compare_file_name)
      unless @compare_file .is_public
        raise ActionController::RoutingError.new('Not Found')
      end
      #
      arrayA = @file.contents.split("\n")
      arrayB = @compare_file .contents.split("\n")
      @diff = TodoFile.getLcsDiff2(arrayA, arrayB)

    end

    #@note_activities = []

    if params[:rail] == "true"
      respond_to do |format|
          format.html { render '_right_rail', :layout => false}
       end
    else
      respond_to do |format|
         format.html { render '_note_view', :layout => 'application'}
      end

    end




  end



end
