class TaskFolderController < ApplicationController
  def show

    allFiles = current_user.todo_files
        .select do |file|
          file.tasks.length > 0
        end

    rows = allFiles.map do |file|
      file.tasks.map do |line|
        {
          :todofile => file ,
          :task => line
        }
      end
    end

    @files = rows.first(2)

    path = "/"
    if (!path.nil?)
         path = params[:path]
    end

    taskfolder = current_user.task_folder(path)
    @topfolders = taskfolder.task_folders.push(taskfolder)
    @topfolders.sort_by!{|a| a.path.downcase}

    @cols = @topfolders.length - 1
    @rows = 0

    @matrix = Hash.new
    @topfolders.each_with_index do |folder, col|
      folder.all.each_with_index do |item, row|
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
