class HomeController < ApplicationController
   before_filter :authenticate_user!, :except => :index
   include Notes::TaskFolderHelper
   include Notes


  def index

    if user_signed_in?

      get_header_data

      results = TodoFile.search do
        keywords ""
        with(:is_public, true)
      end


      changed_files = TaskFolder.process_search_results(results, "/")

      changed_files = changed_files.select{|a| a[:file].is_public}
       @changed_files_by_date = changed_files
         .group_by {|note| note[:file].revision_at.strftime "%A, %B %e, %Y" }
         .sort_by {|date| [Date.strptime(date.first, "%A, %B %e, %Y")]}
         .reverse

      respond_to do |format|
          format.html { render 'task_folder/home_view', :layout => 'application' }
      end
    else
      respond_to do |format|
        format.html # index.html.erb
      end

    end


  end

end
