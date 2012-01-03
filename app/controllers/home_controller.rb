require 'matrix'
class HomeController < ApplicationController
   before_filter :authenticate_user! 
  def index

    topfolders = current_user.task_folder.task_folders

    @topfolders = current_user.task_folder.task_folders.push(current_user.task_folder)
    @topfolders.sort_by!{|a| a.path.downcase}

    @cols = @topfolders.length - 1
    @rows = 0

    @matrix = Hash.new
    @topfolders.each_with_index do |folder, col|
      folder.all.each_with_index do |item, row|
        if (col == 0)
          next
        end
        @matrix[[col, row]] = item
        if row > @rows
          @rows = row
        end
      end
    end

    # to get the # of rows, we have to find th


    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @files}
    end
 
  
  
  end

end
