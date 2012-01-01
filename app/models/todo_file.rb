class TodoFile < ActiveRecord::Base

  belongs_to :user
  has_many :todo_lines

  def self.pushChangesFromText(user, filename, text)

    newFile = TodoFile.saveFile(user, filename, text)
    TodoFile.pushChanges(user, newFile)

  end


  def self.saveFile(user, filename, file)

    todofile = user.todo_files.new
    todofile.filename = filename
    todofile.notes = file
    todofile.save

    reader = StringIO.new(file.strip)
    while (line = reader.gets)
      # only lines that start with to do chars are considered todos
      if (line.lstrip.downcase.start_with?("*","+","todo"))
        item = todofile.todo_lines.new
        item.line = line.strip
        item.guid = UUIDTools::UUID.timestamp_create.to_s
        item.save
      end
    end
    return todofile


  end


  def tasks
    self.todo_lines

  end
  def summary
    reader = StringIO.new(self.notes)
    return [reader.gets]
  end

  def name
    self.filename
  end

  def latestNotes
    reader = StringIO.new(self.notes)
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

  end

end
