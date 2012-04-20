class TaskFolderController < ApplicationController
  include TaskFolderHelper

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
    @todo_file = current_user.todo_files.new(:filename => params[:filename], :contents => params[:save_new_contents], :is_public => false, :edit_source=>'web')

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
    reply = @file.get_copy_of_file(current_user)
    reply.save!
    respond_to do |format|
      format.html {redirect_to :controller => "task_folder", :action=>"folder_view", :path=> reply.filename, :only_path=>true, :username =>reply.user.username }
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

  def suggestion
    filename = params[:filename]
    revision = TaskFileRevision.find_by_revision_uuid(params[:revision_uuid])
    content_length = params[:original_content].length

    # to find the starting position, we want to seek to the line we are at on the file
    io = StringIO.new(revision.contents)
    line_number = params[:line_number].to_i

    start_pos = 0
    line = ""
    (0..line_number).each do |index|
      start_pos = io.pos
      line = io.gets
    end


    orig = StringIO.new(params[:original_content])
    first_line = orig.gets
    line_pos = line.index(first_line) 
    if line_pos.nil?
      final_pos = start_pos
      line_pos = 0
    else
      final_pos = start_pos + line_pos 
    end

    suggestion = revision.suggestions.new(:todo_file_id=>revision.todo_file_id, :user_id=>current_user.id, :start_pos => final_pos, :content_length=> content_length, :original_content=>params[:original_content], :replacement_content=>params[:replacement_content], :line_number => line_number, :line_column=>line_pos)
    if suggestion.save!
      respond_to do |format|
        format.json {head :ok} 
      end
    else
      respond_to do |format|
        format.json { render json: revision.errors, status: :unprocessable_entity}
      end
    end
  end

  def create_or_update
    filename = params[:filename]
    @todo_file = current_user.todo_files.find_by_filename(filename)
    if @todo_file.nil?
      @todo_file = current_user.todo_files.new(:filename => params[:filename], :contents => params[:savecontents], :is_public => false, :edit_source => 'web')
      @todo_file.revision_at = DateTime.now.utc
      if !@todo_file.filename.starts_with?("/")
        @todo_file.filename = "/" + @todo_file.filename
      end
    else
      @todo_file.contents = params[:savecontents]
    end
    if @todo_file.save!
      create_google_analytics_event('Note','Create','',1)
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
    elsif params[:method] == "suggestion"
      suggestion
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
    @user_who_wrote_this = current_user 
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
      if @file.move(params[:filename]) 
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
  end

  def share

    get_header_data
    # if this is a file. move it
    users_shared = []
    unless @file.nil?
      people = params[:shared_user_list].split(',')
      people.each do |person|
        unless person.nil?
          file = @file.share_with_person(person)
          unless file.nil?
            users_shared.push file.user.user_folder_name
          end
        end
      end
      create_google_analytics_event('Note','Share','',people.length)

      make_public = (params[:make_public] == "y")
      if make_public
        unless @file.is_public?
          @file.make_public()
          make_public = true
          create_google_analytics_event('Note','Publish','',1)
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
      @file.get_events do |line|
        lines.push line
      end
    else
      @taskfolder.get_events do |line|
        lines.push line
      end
    end

    #if !params[:person].nil?
    #  lines = lines.select{|a| a.people.include?(params[:person])}
    #end

    @notes_by_date = lines
    .select {|line| line.start_at > Date.today}
    .group_by {|line| line.start_at.strftime "%A, %B %e, %Y" }
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
    if @file.nil?
      if params[:view] == "tasks"
        task_view
      elsif params[:view] == "events"
        event_view
      elsif params[:view] == "feed"
        feed_view
      else
        board_view
      end
    else
      note_view
    end

  end

  def board_view

    start_date= Date.today - 100.years
    end_date = DateTime.now.utc
    if (params[:q].nil?)
      files = @taskfolder.files
    else
      files = @taskfolder.search_for_changes(current_user, params[:q])
    end
    @changed_files_by_folder  = get_changed_files_by_folder(files, @taskfolder.path)
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
      changed_files = @taskfolder.search_for_changes(current_user, params[:q])
    else
      changed_files = @taskfolder.files
    end
    @changed_files_by_date = get_changed_files_by_date(changed_files)

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

  def get_diff_html(left_file, right_file)
    #
    file_comparer = FileComparer.new(left_file, right_file)

    if file_comparer.merge_error?
      @merge_error = true
      return nil
    end

    html = []
    html.push "<div>"
    diff_type = nil
    file_comparer.tokenize do |token|
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
    get_suggestions
    get_tagged
    get_same_folder
    get_shared_with
    get_cards

    if !current_user.nil? && @file.user.id == current_user.id
      @owned_by_user = true
    else
      @owned_by_user = false
    end

    @show_reply_button = false
    @show_edit_buttons = false
    if params[:compare].nil? && @file.is_copied?
      @show_reply_button = true
    end

    if @file.is_read_only?
      @show_copy_button = true
    end

    if !@show_copy_button && params[:compare].nil?
      @show_edit_buttons = true
    end


    unless params[:compare].nil?
      @compare_file = get_file_from_path_escaped(params[:compare])
      unless (!current_user.nil? && @compare_file.user_id == current_user.id) || @compare_file.is_public  || @compare_file.shared_with_users.include?(current_user)
        raise ActionController::RoutingError.new('Not Found')
      end
      @diff_html = get_diff_html(@file,@compare_file)
    end
 

    if params[:rail] == "true"
      respond_to do |format|
        format.html { render '_right_rail', :layout => false}
      end
    elsif params[:files] == "true"
      request.format = :json
      files = current_user.task_folder("/").files.map { |a| file_local_path(a)}
      respond_to do |format|
        format.json {render :json=> files}
      end
    elsif params[:tags] == "true"
      request.format = :json
      all_tags = current_user.task_folder("/").to_enum(:get_tag_notes).to_a.map{|a| a.tags}.flatten.uniq.sort_by{|a| a}.map{|a| "#" + a}
      respond_to do |format|
        format.json {render :json=> all_tags}
      end
    elsif params[:part] == "tasks"
      respond_to do |format|
        format.html { render '_task_group', :locals=>{:group=>@tasks_grouped, :level=>0},:layout=>false}
      end
    elsif params[:cards] == "true"
      snippets = get_cards_with_snippets
      request.format = :json
      respond_to do |format|
        format.json {render :json=> snippets}
      end
    else
      respond_to do |format|
        format.html { render '_note_view', :layout => 'application'}
      end

    end




  end


end

