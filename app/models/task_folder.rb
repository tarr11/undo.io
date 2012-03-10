require 'uri'

class TaskFolder
  include TaskFolderHelper

  attr_accessor :user
  attr_accessor :path


  def initialize(user, path, *params)

    @user = user
    @path = path
    if !@path.ends_with?("/")
      @path = @path + "/"
    end
    @files = params.pop
  end

  def files
    ensure_files
    return @files
  end

  def ensure_files
    if @files.nil?
      @files = todo_files_recursive
    end
  end


  def show_shared_only
    @files = user.files_shared_with_user

  end

  def show_public_only
    @files = files.select{|a| a.is_public}
  end

  def get_event_notes

    self.files.each do |file|
       file.get_event_notes do |line|
          yield line
      end
    end
  end


  def get_person_notes
    self.files.each do |file|
       file.get_person_notes do |line|
          yield line
      end
    end

  end

  def get_tag_notes
    self.files.each do |file|
       file.get_tag_notes do |line|
          yield line
      end
    end

  end


  def todo_files

    # select all files that don't have a slash after the path
    # for now, we put a trailing slash to symbolize a directory ....

    temppath = @path
    if !@path.starts_with?("/")
      temppath = "/" + @path
    end
    depth = temppath.scan("/").length

    self.files.select{|a| a.filename.start_with?(@path)}
    .select do |file|
      #true
      file.filename.scan("/").length == depth && !file.filename.ends_with?("/")
    end
  end

  def get_tasks

    self.files.each do |file|
       file.get_tasks do |task|
          yield task
      end
    end


  end

  def task_folders
    depth = @path.scan("/").length + 1

    # find all the files with one more slash
    # then strip everything after the last slash

    if user.nil?
      raise 'No user!'
    end

    task_paths = self.files.select{|a| a.filename.start_with?(@path)}
      .select {|file| file.filename.scan("/").length >= depth}
      .map{ |file| File.dirname(file.filename)}
      .map{ |path| path.split("/").first(depth).join("/") + "/"}
      .uniq

    return task_paths.map { |path|
      TaskFolder.new(@user, path, self.files.select{|file| file.filename.start_with?(path)
      })}

  end

  def all
    folders = task_folders
    files = self.files
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

  def tasks
    self.files.map { |file|
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


  def self.process_search_results(results, path)
    allChanges = []
    # need this because helper method is busted in RSpec
    if results.hits.length == 0
      return allChanges
    end
    results.each_hit_with_result do |hit, result|

      if result.filename.starts_with?(path)

        addedLines = []

        hit.highlights(:contents).each do |highlight|
          highlight.format{|word| "<span class='highlight'>#{word}</span>"}.split("\n").each do |line|
            addedLines.push (line)
          end
        end

        if addedLines.length == 0
          result.contents.split("\n").first(3).each do |line|
            addedLines.push (line)
          end
        end


        result.changed_lines = addedLines
        allChanges.push result

      end

    end


    return allChanges

  end

  def search_for_changes(query)
    results = self.user.todo_files.search do
      keywords query, :highlight=>true
      with(:user_id, user.id)
    end

    changed_files = TaskFolder.process_search_results(results, self.path)

    return changed_files
#    allChanges = TaskFolder.process_search_results results, self.path

 #   return allChanges
  end


  def get_file_changes(start_date, end_date)

    return self.files.map{|a|
        {
            :file => a,
            :diff => [],
            :revision_at => a.revision_at,
            :changedLines => a.formatted_lines
         }
    }

    allChanges = []

    revisions = self.user.task_file_revisions.map{|a| a}

    self.files.each do |file|
      change = file.getChanges(start_date, end_date, revisions)
      if (!change.nil?)
        allChanges.push change
      end
    end

    return allChanges
  end



  def get_summary(start_date, end_date)
    changes = self.get_file_changes(start_date, end_date)
    changed_folders = []
    if !changes.nil?
      groupedPaths = changes.group_by{|a| a[:file].path}

      groupedPaths.each do |path, group|
        changed_folders.push(
            {
                :name => path,
                :files =>
                    group.map{ |change|
                        {
                            :file => change[:file],
                            :name => change[:file].shortName,
                            :number_of_lines => change[:changedLines].length,
                            :changes => change[:changedLines]
                        }
                    }
            }

        )
      end
    end
    return changed_folders

  end

  def getChanges(startDate, endDate, allChanges = [])

    self.files.each do |file|
      change = file.getChanges(startDate, endDate).first
      if (!change.nil?)
        allChanges.push change
      end
    end
    task_folders.each {|folder| folder.getChanges(startDate, endDate, allChanges)}
    allChanges

  end

  private
    def todo_files_recursive
      temppath = @path
      if !@path.starts_with?("/")
        temppath = "/" + @path
      end

      return TodoFile.all(:include=>[:user,:copied_to, :copied_from], :conditions => ["user_id = ? AND filename LIKE ?", "#{user.id}", "#{temppath}%"]).sort_by{|a| a.path}

    end


end
