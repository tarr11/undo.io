class HomeController < ApplicationController
   before_filter :authenticate_user!, :except => :index
   respond_to_mobile_requests :skip_xhr_requests => false
   include Notes::TaskFolderHelper
   include Notes


  def index

    get_header_data
    if user_signed_in?

      changed_files = @taskfolder.search_for_changes("test")

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
        format.mobile
      end

    end


  end

end
