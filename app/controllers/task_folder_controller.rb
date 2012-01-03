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

    range = params[:range]


    case range

      when "hour"
        @startDate = DateTime.now.utc - 1.hour
        @endDate = DateTime.now.utc
      when "today"
        @startDate = DateTime.now.utc - 1.day
        @endDate = DateTime.now.utc
      when "yesterday"
        @startDate = Date.yesterday
        @endDate = Date.today
      when "3days"
        @startDate = Date.today- 3.days
        @endDate = DateTime.now.utc
      when "week"
        @startDate = Date.today - 7.days
        @endDate = DateTime.now.utc
      when "month"
        @startDate = Date.today - 1.month
        @endDate = DateTime.now.utc
      else
        @startDate = Date.today - 100.years
        @endDate = DateTime.now.utc
    end



    changedNotes = []

    @rows = 0
    @matrix = Hash.new
    @changes = Hash.new
    @topfolders.each_with_index do |folder, col|
      folder.all.each_with_index do |item, row|
        changes = item.getChanges(@startDate , @endDate)
        if (changes.length > 0)
          note =
          {
            :changes => changes,
            :folder => folder,
            :item => item
          }

          changedNotes.push note
        end
      end
    end

    @count = changedNotes.length

    @columnItems =  changedNotes.uniq{|a| a[:folder].name}
    @columnItems.each_with_index do |folder, col |
        rows = changedNotes.select{ |note|
          note[:folder] == folder[:folder]
        }

        rows.each_with_index do |item, row|
            if (col == 0 )
              # no folders in the first col
              if (item[:item].class.to_s == "TaskFolder")
                next
              end
            end
            @matrix[[col,row]] = item
            if (row > @rows)
              @rows = row
            end
        end

    end

    @cols = @columnItems.length

    # only get files that have changed
#    @matrix = @matrix.select { |index|

##      @matrix[index].getChanges(startDate, endDate).length > 0
#    }

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @files}
    end


  end

end
