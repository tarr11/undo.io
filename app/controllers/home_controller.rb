require 'matrix'
class HomeController < ApplicationController
   before_filter :authenticate_user! 
  def index
    allFiles = current_user.todo_files
        .includes(:todo_lines)
        .select do |file|
          file.todo_lines.length > 0
        end

    rows = allFiles.map do |file|
      file.todo_lines.map do |line|
        {
          :todofile => file ,
          :task => line
        }
      end
    end

    @files = rows.first(2)

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
