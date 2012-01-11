class TaskFolder

  attr_accessor :user
  attr_accessor :path


  def initialize(user, path)
    @user = user
    @path = path
    if !@path.ends_with?("/")
      @path = @path + "/"
    end
  end

  def todo_files_recursive
    temppath = @path
    if !@path.starts_with?("/")
      temppath = "/" + @path
    end

    user.todo_files.find(:all, :conditions => ["filename LIKE ?", "#{temppath}%"]).sort_by{|a| a.path}

  end


  def todo_files

    # select all files that don't have a slash after the path
    # for now, we put a trailing slash to symbolize a directory ....

    temppath = @path
    if !@path.starts_with?("/")
      temppath = "/" + @path
    end
    depth = temppath.scan("/").length

    user.todo_files.find(:all, :conditions => ["filename LIKE ?", "#{temppath}%"])
    .select do |file|
      #true
      file.filename.scan("/").length == depth && !file.filename.ends_with?("/")
    end
  end

  def task_folders
    require 'uri'
    depth = @path.scan("/").length + 1

    # find all the files with one more slash
    # then strip everything after the last slash

    if user.nil?
      raise 'No user!'
    end

    user.todo_files.find(:all, :conditions => ["filename LIKE ?", "#{path}%"])
      .select {|file| file.filename.scan("/").length >= depth}
      .map{ |file| File.dirname(file.filename)}
      .map{ |path| path.split("/").first(depth).join("/") + "/"}
      .uniq
      .map {|path| TaskFolder.new @user, path}
  end

  def all
    folders = task_folders
    files = todo_files
    allstuff = Array.new
    allstuff.push folders
    allstuff.push files
    return allstuff.flatten

  end

  def summary
    return todo_files.map{ |file|
      file.filename
    }

  end

  def self.model_name
     @_model_name ||= ActiveModel::Name.new(self)
   end

  def latestNotes
    if todo_files.first.nil?
      []
    else
      todo_files.first.latestNotes
    end
  end

  def tasks
    todo_files.map { |file|
      file.tasks
    }.flatten
  end

  def name
    @path
  end

  def shortName
    if (@path == "/")
      ""
    else
      @path.split("/").last
    end

  end

  def get_file_changes(start_date, end_date)

    allChanges = []

    todo_files_recursive.each do |file|
      change = file.getChanges(start_date, end_date)
      if (!change.nil?)
        allChanges.push change
      end
    end

    return allChanges
  end

  def getChanges(startDate, endDate, allChanges = [])

    todo_files.each do |file|
      change = file.getChanges(startDate, endDate).first
      if (!change.nil?)
        allChanges.push change
      end
    end
    task_folders.each {|folder| folder.getChanges(startDate, endDate, allChanges)}
    allChanges

  end

end
