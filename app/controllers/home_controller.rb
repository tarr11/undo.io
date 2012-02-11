class HomeController < ApplicationController
   before_filter :authenticate_user!, :except => :index
   include Notes::TaskFolderHelper
   include Notes

  def shared_view
    results = current_user.files_shared_with_user
    changed_files = []
    results.each do |result|
      changed_files.push (
              {
             :file => result,
             :diff => result.diff,
             :revision_at => result.revision_at,
             :changedLines => result.formatted_lines.map{|a| a.text}.first(3)
          }
      )

    end
    @header = "Shared to " + current_user.username
    respond_to do |format|
        format.html { render 'task_folder/home_view', :layout => 'application' }
    end

  end

  def boxed_view

    results = TodoFile.search do
       keywords params[:q] ||= ""
       with(:is_public, true)
     end
     changed_files = TaskFolder.process_search_results(results, "/")
     changed_files = changed_files.select{|a| a[:file].is_public}
    @changed_files_by_folder = changed_files
      .group_by {|note| get_sub_folder(note[:file].path,"/") }
    @header = "Public Notes"
    @wildcard_user_name = true
    respond_to do |format|
        format.html { render 'task_folder/boxed_view', :layout => 'task_folder'}
    end

  end

  def feed_view
    results = TodoFile.search do
       keywords ""
       with(:is_public, true)
     end
     changed_files = TaskFolder.process_search_results(results, "/")
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

  def index

    if user_signed_in?

      get_header_data

      if params[:view] == "shared"
        shared_view
      else
        boxed_view
      end
    else
      respond_to do |format|
        format.html # index.html.erb
      end

    end


  end

end
