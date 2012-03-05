class TaskFolderController < ApplicationController
  before_filter :authenticate_user!
  include TaskFolderHelper
  require 'diff_match_patch'

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
      if @todo_file.save!

        format.html { redirect_to :controller=>'task_folder', :action=>'folder_view', :username=>current_user.username, :path=> @todo_file.filename, notice: 'File was successfully created.' }
        format.json { render json: @todo_file, status: :created}
      else
        format.html { render action: "new" }
        format.json { render json: @todo_file.errors, status: :unprocessable_entity }
      end
    end

  end

  def reply
    get_header_data
    current_user.file(@file.filename).reply()
    respond_to do |format|
      format.html {redirect_to :controller => "task_folder", :action=>"folder_view", :path=> @file.filename, :only_path=>true, :username =>@file.user.username }
    end
  end

  def accept
    get_header_data
    @file.accept get_file_from_path(params[:compare_file])
    @file.save!
    respond_to do |format|
      format.html {redirect_to :controller => "task_folder", :action=>"folder_view", :path=> @file.filename, :only_path=>true, :username =>@file.user.username }
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
    if @todo_file.save!
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

  def delete
    get_header_data
    path = @file.path
    if @file.user_id == current_user.id
      @file.destroy()
    end
    respond_to do |format|
      format.html {redirect_to :controller => "task_folder", :action=>"folder_view", :path=> path, :only_path=>true, :username =>current_user.username}
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
    elsif params[:method] == "reply"
      reply
    elsif params[:method] == "accept"
      accept
    else
      create_or_update
    end

  end

  def new_file

    @header = "New Note"
    @file = TodoFile.new
    @file_user = current_user
    @file.user = current_user
    @is_new_file = true
    @owned_by_user  = true
    @slides= []
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
      if @file.save!
        DropboxNavigator.delay(:queue=>'dropbox').move_file oldName, @file
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
    users_shared = []
    unless @file.nil?

      people = params[:shared_user_list].split(',')
      people.each do |person|
        user = User.find_by_username(person)
        unless user.nil?
          @file.share_with(user)
          users_shared.push user.username
        end

      end
      make_public = (params[:make_public] == "y")
      if make_public
        unless @file.is_public?
          @file.make_public()
          make_public = true
        end
      else
        if @file.is_public?
          @file.make_private()
          make_private = true
        end
      end
      flash[:shared_note] = {
          :make_public => make_public,
          :make_private => make_private,
          :users_shared => users_shared
      }

      respond_to do |format|
        format.html { redirect_to :controller=>'task_folder', :action=>'folder_view', :path=> @file.filename, :username=>@file.user.username}
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

       @new_file = @file.copy(current_user,params[:copy_filename], params[:revision_uuid])
        if @new_file.save!

          respond_to do |format|
            flash[:notice] = "File was copied"
            format.html { redirect_to :controller=>'task_folder', :action=>'folder_view', :path=> @new_file.filename, :username=>@new_file.user.username}
          end
        else
          @errors = new_file.errors
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


  def tokenize_diff (diff)

    # convert this diff into html
    token = nil#{:token_type => :new_line, :tab_count => 0}
    left_padding = ""
    diff.each do |diff|

      token = {:token_type => :action_start, :diff_type => diff.action}
      yield token

      diff.changes.split("\n").each_with_index do |line,index|
        if index > 0 || (index == 0 && diff.changes.strip.blank?)
          token = {:token_type => :line_break}
          yield token
          todo_line = TodoLine.new
          todo_line.text = line
          token = {:token_type => :new_line, :tab_count => todo_line.tab_count}
          yield token
          left_padding = ""
        end

        unless line.blank?
          token = {:token_type => :text, :text => line }
          yield token
        else
          if diff.action == :insert
            left_padding += line
          end
        end

      end

      token = {:token_type => :action_end}
      yield token

    end
    token = {:token_type => :line_break}
    yield token


  end


  def patch_up(file)
    # patches each file sequentially

    result = file.contents
    file.new_replies.each do |patch_file|
      result = merge(patch_file.copied_revision.contents, patch_file.contents, result)
    end

    return result
  end

  def get_diff_html(left_file_contents, right_file_contents, current_file_contents)
#
    # find the change
    dmp = DiffMatchPatch.new
    dmp.patch_deleteThreshold=0.1
    patches = dmp.patch_make(left_file_contents, right_file_contents)


    # push the change into current version
    begin
      merge_results = dmp.patch_apply(patches, current_file_contents)
    rescue Exception
      @merge_error = true
      return nil
    end

    merged_contents = merge_results.shift
    if merge_results.include?(false)
      @merge_error = true
      return nil
    end

    diff = dmp.diff_main(current_file_contents, merged_contents)
    dmp.diff_cleanupSemantic(diff)

    # now compare the current version to my version
    mapped_diff = diff.map { |a|
      OpenStruct.new(
          :action=>a.first,
          :changes=>a.second
      )
    }


    html = []
    html.push "<div>"
    diff_type = nil
    tokenize_diff(mapped_diff) do |token|
      if token[:token_type] == :action_start
          html.push '<span class="' + token[:diff_type].to_s + '">'
          diff_type = token[:diff_type]
      elsif token[:token_type] == :action_end
        html.push '</span>'
        diff_type = nil
      elsif token[:token_type] == :line_break
        unless diff_type.nil?
          html.push "</span>"
        end
        html.push '</div>'
      elsif token[:token_type] == :new_line
        html.push '<div style="margin-left:' + token[:tab_count].to_s + 'em;">'
        unless diff_type.nil?
          html.push '<span class="' + diff_type.to_s + '">'
        end
      elsif token[:token_type] == :text
        html.push token[:text]
      end

    end

    return html

  end

  def note_view

    get_related_people
    get_related_tags
    get_related_events
    get_related_tasks
    get_slideshow
    get_replies
    get_tagged
    get_same_folder
    get_shared_with

    if @file.user.id == current_user.id
      @owned_by_user = true
    else
      @owned_by_user = false
    end

    @show_reply_button = false
    @show_edit_buttons = false
    if params[:compare].nil? && @file.is_copied?
        @show_reply_button = true
    end

    if params[:compare].nil?
      @show_edit_buttons = true
    end

    unless params[:combined].nil?
      @combined = true
      new_file = patch_up(@file)
      @compare_files = @file.new_replies
      @diff_html =  get_diff_html(@file.contents, new_file, @file.contents)
    end

    unless params[:compare].nil?
      @compare_file = get_file_from_path(params[:compare])
      unless @compare_file.user_id == current_user.id || @compare_file.is_public  || @compare_file.shared_with_users.include?(current_user)
        raise ActionController::RoutingError.new('Not Found')
      end

      file_contents = @file.contents
      compare_file_contents = @compare_file.contents

      # one of these is copied from the other
      if @compare_file.copied_from_id == @file.id
        if @compare_file.copied_revision.nil?
          @merge_error = true
        else
          @diff_html= get_diff_html(@compare_file.copied_revision.contents, @compare_file.contents, @file.contents)
        end
      elsif @file.copied_from_id == @compare_file.id
        if @file.copied_revision.nil?
          @merge_error = true
        else
          @diff_html= get_diff_html(@file.copied_revision.contents, @compare_file.contents,  @file.contents)
        end
      else
        # nothing for now
      end

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
