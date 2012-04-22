class HomeController < ApplicationController
 #  before_filter :authenticate_user!, :except => :index
   include TaskFolderHelper

  def shared_view
    results = current_user.files_shared_with_user
    changed_files = []
    results.each do |result|
      changed_files.push (
              {
             :file => result,
             :diff => result.diff,
             :revision_at => result.revision_at,
             :changedLines => result.formatted_lines.map{|a| a.text}
          }
      )

    end
    @header = "Shared to " + current_user.username
    respond_to do |format|
        format.html { render 'task_folder/home_view', :layout => 'application' }
    end

  end
  def please_confirm
    @header = "Please confirm"
  end

  def team
    @header = "Team Edition"
  end

  def board_view

    results = TodoFile.search do
       keywords params[:q] ||= ""
       with(:is_public, true)
       paginate :page => 1, :per_page => 100
       order_by(:revision_at, :desc)
    end

    path = params[:path]
    changed_files = []
    unless results.nil?
     changed_files = TaskFolder.process_search_results(current_user, results, "/")
     changed_files = changed_files.select{|a| a.is_public && (path.nil? || a.filename.start_with?(path))}
    end

    if changed_files.length == 0
        raise ActionController::RoutingError.new('Not Found')
    end

    @changed_files_by_folder = changed_files
      .group_by {|note| get_sub_folder(note.path,"/") }
    if path.blank? || path.nil? || path == "/"
      @header = "Public Notes"
    else
      @header = path.split("/").join(" ") + " notes"
      @header = @header.lstrip.capitalize
    end

    @wildcard_user_name = true
    @path_parts = get_path_parts(false, path)
    @is_public = true


    check_for_shared_notes
    respond_to do |format|
        format.html { render 'task_folder/boxed_view', :layout => 'layouts/public_folder', :locals=>{:show_avatar=>true, :show_public_path => true, :note_class=>"note-box-3x5"}}
    end

  end

  def feed_view
    results = TodoFile.search do
       keywords ""
       with(:is_public, true)
       paginate :page => 1, :per_page => 100
       order_by(:revision_at, :desc)
     end
     changed_files = TaskFolder.process_search_results(current_user, results, "/")
     changed_files = changed_files.select{|a| a[:file].is_public}
     @header = "Public Notes"
     @changed_files_by_date = changed_files
       .group_by {|note| note[:file].revision_at.strftime "%A, %B %e, %Y" }
       .sort_by {|date| [Date.strptime(date.first, "%A, %B %e, %Y")]}
       .reverse

      respond_to do |format|
          format.html { render 'task_folder/home_view', :layout => 'application' }
      end

  end

  def dashboard_view

    changed_files = current_user.todo_files.all(:order=> 'revision_at desc').first(3)

    @changed_files_by_folder = changed_files
          .group_by {|note| get_sub_folder(note.path,"/") }

    public_changed_files = TodoFile.where(:is_public => true).where("user_id <> ?", current_user.id).order('revision_at desc').first(3)
    @public_changed_files_by_folder = public_changed_files
          .group_by {|note| get_sub_folder(note.path,"/") }

    @notes_by_date = current_user.task_folder("/").to_enum(:get_events).to_a
    .select {|line| line.start_at > Date.today && line.start_at < (Date.today + 3.days)}
    .group_by {|line| line.start_at.strftime "%A, %B %e, %Y" }
    .sort_by {|date| [Date.strptime(date.first, "%A, %B %e, %Y")]}

    respond_to do |format|
      format.html {render 'task_folder/dashboard', :layout => 'application'}
    end
  end

  def public_view
    board_view
  end


  def index

    if user_signed_in?
      dashboard_view
    else
      respond_to do |format|
        @header = "Index cards for the web"
        format.html
      end

    end

  end

end
