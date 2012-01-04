class TodoFile < ActiveRecord::Base

  belongs_to :user
#  has_many :todo_lines
  has_many :task_file_revisions

  def self.pushChangesFromText(user, filename, text)

    newFile = TodoFile.saveFile(user, filename, text)
    #TodoFile.pushChanges(user, newFile)

  end

  def self.deleteFile(user, filename)
    file = user.todo_files.find_by_filename(filename)
    file.destroy
  end

=begin
 =begin

 def save


    # also save revisions
    revision = self.task_file_revisions.new
    revision.filename = self.filename
    revision.contents = self.contents
    revision.user_id = self.user_id
    revision.save

  end

end
=end

  def self.saveFile(user, filename, file)

    # save the curent file
    todofile = user.todo_files.find_or_initialize_by_filename(filename)
    todofile.contents = file
    todofile.save

    # also save revisions
    revision = todofile.task_file_revisions.new
    revision.filename = filename
    revision.contents = file
    revision.user_id = user.id
    revision.save

   return todofile
  end

  def getChanges(startDate, endDate)
      revs = self.task_file_revisions#.where(['created_at between ? and ?',startDate, endDate]).map {|a| a}
      firstversion = revs.first

      if (firstversion.nil?)
          return []
      end

      # prev = first rev before the start
      prevRev = revs.select{|a| a.created_at < startDate }
                    .sort_by{|a| a.created_at}
                    .reverse
                    .first

      nextRev = revs.select{|a| a.created_at < endDate}
                    .sort_by{|a| a.created_at}
                    .reverse
                    .first

      if (self.id == 29)
        puts self.id
      end

      if (prevRev.nil?)
        prevContents = ""
      elsif (firstversion.id == prevRev.id)
        prevContents = ""
      else
        prevContents = prevRev.contents
      end

      if (nextRev.nil?)
        nextContents = ""
      else
        nextContents = nextRev.contents
      end

      prevContents = encodeUtf8(prevContents)
      nextContents = encodeUtf8(nextContents)
      diff = Diffy::Diff.new(prevContents, nextContents)


      if diff.select{|line| line.match('^[+-]')}.length > 0
         [{
             :file => self,
            :diff => diff
         }]

      else
        []
      end

  end

  def encodeUtf8(untrusted_string)
    require ("iconv")
    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    valid_string = ic.iconv(untrusted_string + ' ')[0..-2]

  end

  def tasks
    if (self.notes.nil?)
      return []
    end

    tempTasks = []
    reader = StringIO.new(self.notes.strip)
     while (line = reader.gets)
       # only lines that start with to do chars are considered todos
       if (line.lstrip.downcase.start_with?("*","+","todo"))
         task = Task.new
         task.contents = line.strip
         tempTasks.push task
       end
     end
     return tempTasks
  end
  def summary
    if (self.notes.nil?)
      return [""]
    end
    reader = StringIO.new(self.contents)
    return [reader.gets]
  end

  def name
    self.filename
  end

  def shortName
    self.filename.split("/").last
  end
  def latestNotes
    if (self.contents.nil?)
      return [""]
    end

    reader = StringIO.new(self.contents)
    last = Array.new
    while (line = reader.gets)
      # only lines that start with to do chars are considered todos
      if (!line.empty?)
        last.push line
      end
    end
    return last.last(3)

  end

  def self.importFile(filename, user)
    # import this file using File
    file = File.open(filename, 'r')
   end


  def self.compareFiles(base, compare)

    if (compare == nil)
      puts "compare=nil"
      return base.todo_lines.all
    end
  
   baselines = base.todo_lines.select do |line|
     line
  end

   comparelines = compare.todo_lines.select do |line|
     line
    end


    # find deleted lines - in old, but not new
    return baselines.select do |baseline|
     comparelines.all? do |compareline|
     #  puts baseline.line + ":" +  compareline.line

       baseline.line != compareline.line        
      
     end
    end    

  end

=begin
  def self.pushChanges(user, newFile)

    #   newFile = TodoFile.importFile(newFileName, user)
    oldFile = user.todo_files.where(["filename=? and id <> ?", newFile.filename,newFile.id]).order("created_at DESC").first

    if (!oldFile.nil?)
      puts "Deleted"

      TodoFile.App
      deleted = TodoFile.compareFiles(oldFile, newFile)
      deletedGuids = deleted.map do |line|
        line.guid
      end

      user.tasks.where([ "client_id in (?)", deletedGuids ]).delete_all
      deleted.map do |line|
        puts line.line
      end

    end

    puts "Inserted"
    inserted = TodoFile.compareFiles(newFile, oldFile)

    inserted.each do |line|
      newTask = user.tasks.new  
      newTask.task = line.line
      newTask.client_id = line.guid
      newTask.save
      puts line.line 
    end
  end

  def self.pushChangesFromTwoFiles(user, oldFile, newFile)
    
    deleted = TodoFile.compareFiles(oldFile, newFile)
    inserted = TodoFile.compareFiles(newFile, oldFile)

    deletedGuids = deleted.map do |line|
      line.guid
    end

    user.tasks.where([ "client_id in (?)", deletedGuids ]).delete_all

    inserted.each do |line|
      newTask = user.tasks.new  
      newTask.task = line.line
      newTask.client_id = line.guid
      newTask.save
    end
=end


end
