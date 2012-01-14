class TaskFolderController < ApplicationController
  before_filter :authenticate_user!
  respond_to_mobile_requests :skip_xhr_requests => false

  def folder_view
#    session[:mobylette_override] = :force_mobile
    @ranges = [
        {
             :name => "Today",
             :start_date => Time.zone.now.beginning_of_day - 1.days,
             :end_date => Time.zone.now.beginning_of_day + 1.days
            } ,
            {
             :name => "Yesterday",
             :start_date => Time.zone.now.beginning_of_day - 2.days,
             :end_date => Time.zone.now.beginning_of_day
            }
    ]

    #(3..7).each do |index|
    #  date = Time.zone.now - index.days
    #  @ranges.push({
    #    :name => date.strftime("%A"),
    #    :start_date => date,
    #    :end_date => date + 1.days
    #  })
    #end

    @ranges.push({
         :name => "Last 3 days",
         :start_date => Time.zone.now.beginning_of_day - 3.days,
         :end_date => Time.zone.now.beginning_of_day
    })

    @ranges.push({
         :name => "Last week",
         :start_date => Time.zone.now.beginning_of_day - 1.week,
         :end_date => Time.zone.now.beginning_of_day
    })

    @ranges.push({
         :name => "Last month",
         :start_date => Time.zone.now.beginning_of_day - 1.month,
         :end_date => Time.zone.now.beginning_of_day
    })

    @ranges.push({
         :name => "All",
         :start_date => Time.zone.now.beginning_of_day - 100.years,
         :end_date => Time.zone.now.beginning_of_day
    })

    path = "/"
    if (!params[:path].empty?)
         path = params[:path]
    end

    # if a file exists, then show it
    @file = current_user.file(path)

    if @file.nil?
      @taskfolder = current_user.task_folder(path)

      @header = @taskfolder.shortName
      if @header.blank?
        @header = "Home"
      end
    else
      @taskfolder = @file.task_folder
      @header = @file.shortName
    end



    if @taskfolder.nil?
       raise 'No Folder'
    end if

    parts = path.split('/')

    if (parts.length == 0)
      parts = [""]
    end

    if (!@file.nil?)
      parts.pop
    end

    @path_parts = []
    incremental_part = "/"
    parts.each_with_index do |part|
        incremental_part +=  part + "/"
        @path_parts.push ({
          :path => incremental_part,
          :name => part
        })
    end

    if @file.nil?
      start_date= params[:start_date]
      end_date = params[:end_date]

      if (start_date.nil?)
        start_date=   Time.zone.now.beginning_of_day - 1.week
      end

      if (end_date.nil?)
        end_date = Time.zone.now
      end

      @changed_folders = @taskfolder.get_summary(start_date, end_date)
      @tasks = []
      @changed_folders.each do |folder|
        folder[:files].each do |file|
          file[:changes].each do |change|
            if (change.include?("#"))
              task = Task.new
              task.contents = change
              task.file = file[:file]
              @tasks.push task
            end
          end
        end
      end

    end

    @only_path = true
    @folders = @taskfolder.task_folders
    @files = @taskfolder.todo_files
    @dataUrlBase = url_for(:controller => "task_folder", :action=>"folder_view", :path=>@taskfolder.path, :trailing_slash => true, :only_path =>true)
    @hashPageId = params[:path].sub("/","_")

    respond_to do |format|
      format.html # index.html.erb
      format.mobile
    end

  end

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
    if (!params[:path].empty?)
         path = params[:path]
    end

    @taskfolder = current_user.task_folder(path)
    @topfolders = @taskfolder.task_folders.push(@taskfolder)
    @topfolders.sort_by!{|a| a.path.downcase}

    range = params[:range]

    @startDate = params[:start] ||= Date.today - 100.years
    @endDate = params[:end] ||= DateTime.now.utc

    #case range
    #
    #  when "hour"
    #    @startDate = DateTime.now.utc - 1.hour
    #    @endDate = DateTime.now.utc
    #  when "today"
    #    @startDate = Date.today
    #    @endDate = DateTime.now.utc
    #  when "yesterday"
    #    @startDate = Date.yesterday
    #    @endDate = Date.today
    #  when "3days"
    #    @startDate = Date.today- 3.days
    #    @endDate = DateTime.now.utc
    #  when "week"
    #    @startDate = Date.today - 7.days
    #    @endDate = DateTime.now.utc
    #  when "month"
    #    @startDate = Date.today - 1.month
    #    @endDate = DateTime.now.utc
    #  else
    #    @startDate = Date.today - 100.years
    #    @endDate = DateTime.now.utc
    #end



    changedNotes = []

    @rows = 0
    @matrix = Hash.new
    @changes = Hash.new
    @topfolders.each_with_index do |folder, col|
      folder.all.each_with_index do |item, row|
        # don't show any folders in the first column, since they are already in the row'
#        if (folder.name == path && item.class.to_s == "TaskFolder")
#            next
#        end

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

    sortedColumnItems = []
    changedNotes.group_by {|note| note[:folder].name}
      .each do |folderName, notes|
         sortedColumnItems.push(
          {
            :folder => notes.first[:folder],
            :count =>notes.count
          }
         )
    end

    @columnItems = sortedColumnItems
      .sort_by{|a| [ (a[:folder].name == "/" ? 2 : 1), a[:count]] }
      .reverse

    #@columnItems =  changedNotes.uniq{|a| a[:folder].name}

    # summary rows, these are the
    @columnItems.each_with_index do |folder, col |

      changes = folder[:folder].getChanges(@startDate, @endDate)
      #@matrix[[col,0]] = {
      #    :changes => changes,
      #    :folder =>folder,
      #    :item => folder[:folder]
      #}
    end

    @columnItems.each_with_index do |folder, col |
        rows = changedNotes.select{ |note|
          note[:folder] == folder[:folder]
        }

        rows.each_with_index do |item, row|
            realrow = row
            @matrix[[col,realrow ]] = item
            if (realrow > @rows)
              @rows = realrow
            end
        end

    end

    @ranges = [
        {
             :name => "Today",
             :range => "today"
         },
         {
            :name => "Yesterday",
            :range => "yesterday"
        },
         {
            :name => "Last 3 Days",
            :range => "3days"
        },
         {
            :name => "Last 7 Days",
            :range => "3days"
        },
         {
            :name => "Last Month",
            :range => "month"
        },
         {
            :name => "All",
            :range => "all"
        },



    ]

    sample_timeline = [
        {
            :revision_date => DateTime.now,
            :start_date =>DateTime.now,
            :end_date=>Date.today,
             :label => "Now",
            :width => 100
        },
        {
            :revision_date => Date.today,
            :label => "Today",
            :width => 100,
            :start_date =>DateTime.now,
            :end_date=>Date.today
        },
        {
            :revision_date => Date.yesterday,
            :label => "Yesterday",
            :width=> 300,
            :start_date =>DateTime.now,
            :end_date=>Date.today
        },
        {
            :revision_date => Date.today - 7.days,
            :label => "Last Week",
            :width=> 400             ,
            :start_date =>DateTime.now,
            :end_date=>Date.today
        },
        {
            :revision_date => Date.today - 1.year,
            :label => "Last year",
            :width=> 1000             ,
            :start_date =>DateTime.now,
            :end_date=>Date.today
        }


    ]


    diffs = []

    changedNotes.each do |note|
      note[:changes].each do |change|
        change[:diff].each do |line|
          if (!change[:revision_at].nil?)
            diffs.push ({
                :line => line,
                :revision_at => change[:revision_at]
            })
          end

        end
      end
    end

    segments = 4

    diffs = diffs.sort_by{|a| a[:revision_at]}
    startDiff = diffs.first[:revision_at].to_datetime
    endDiff = diffs.last[:revision_at].to_datetime


    totalDays = (endDiff - startDiff).to_i
    #totalDays = startDiff.to_s + " " + endDiff.to_s

    segment_days = totalDays / segments.to_f

    recs_per_segment = (diffs.length / segments).to_i

    datemarkers = []
    # record count normalized
    #(0.upto(segments-1)).each do |index|
    #  startDate = diffs[recs_per_segment*index][:revision_at]
    #  endIndex = recs_per_segment*(index+1)
    #  if (diffs.length > endIndex)
    #    endDate = diffs[endIndex][:revision_at]
    #  else
    #    endDate = diffs[diffs.length - 1][:revision_at]
    #  end
    #  datemarkers.push( { :start_date => startDate, :end_date => endDate })
    #end

    # date normalized
    (0.upto(segments-1)).each do |index|
       endDate= endDiff - ( ((index)*segment_days).to_f ).days
       startDate = endDate - segment_days.days
       datemarkers.push( { :start_date => startDate, :end_date => endDate })
      if (startDate <= startDiff)
        break
      end
     end


    @timeline = []

    #datemarkers = datemarkers.reverse
    datemarkers.each do |marker|

      # percent total is the # of records between start and enddate
      count = diffs.select{|a| (a[:revision_at] >= marker[:start_date]) && (a[:revision_at] <= marker[:end_date])}.length



      percentTotal = [(count.to_f / diffs.length.to_f),0.05].max

        @timeline.push({
            :start_date =>marker[:start_date],
            :end_date=>marker[:end_date],
            :percentTotal => percentTotal,
            :count => count,
            :text => diffs.select{|a| a[:revision_at] >= startDiff && a[:revision_at] <= endDiff}.length,
            :endDiff => endDiff,
            :startDiff => startDiff
        })

    end


    #datemarkers.each do |marker|
    #
    #  days = (marker[:end_date].to_datetime - marker[:start_date].to_datetime).to_f
    #  percentTotal = (days / totalDays).to_f
    #
    #    @timeline.push({
    #        :start_date =>marker[:start_date],
    #        :end_date=>marker[:end_date],
    #        :percentTotal => percentTotal,
    #    })
    #
    #end


    #@timelineChanges = diffs
    #@timeline = sample_timeline

    if (params[:path] != "/")

      path = params[:path].split("/")
      path.pop
      if (path.length <= 1)
        @uplevel = "/"
      else
        @uplevel = path.join("/")
      end
    end

    @cols = @columnItems.length

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @files}
    end


  end



end
