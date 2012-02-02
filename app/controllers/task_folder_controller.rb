class TaskFolderController < ApplicationController
  before_filter :authenticate_user!
  respond_to_mobile_requests :skip_xhr_requests => false
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

  def make_public
    current_user.file(params[:file_name]).make_public()
    respond_to do |format|
      format.html { head :ok }
      format.json { head :ok }
      format.js
    end

  end

  def make_private
    current_user.file(params[:file_name]).make_private()
    respond_to do |format|
      format.html { head :ok }
      format.json { head :ok }
      format.js
    end

  end

  def new_file

    c
    @file = TodoFile.new
    @is_new_file = true
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
          format.html { redirect_to :controller=>'task_folder', :action=>'folder_view', :path=> @file.filename, notice: 'File was moved.' }
        end
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
    get_header_data

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
    get_header_data
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




  end

  def topic_view
    get_header_data

  end

   def folder_view

    get_header_data

    if @file.nil?
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
    else

      get_related_people
      get_related_tags


      respond_to do |format|
        format.html { render '_note_view', :layout => 'application'}
      end

    end




  end



end
