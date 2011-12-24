class TodoFile < ActiveRecord::Base

  belongs_to :user
  has_many :todo_lines


  def self.importFile(filename, user)
    # import this file using File
    file = File.open(filename, 'r')

    todofile = user.todo_files.new
    todofile.FileName = filename
    todofile.save

    while (line = file.gets)
      item = todofile.todo_lines.new
      item.line = line
      item.guid = UUIDTools::UUID.timestamp_create.to_s
      item.save
    end
    return todofile

  end


  def self.compareFiles(base, compare)

    if (compare == nil)
      puts "compare=nil"
      return base.todo_lines.all
    end

    # find deleted lines - in old, but not new
    return base.todo_lines.find_all do |baseline|
     !compare.todo_lines.any? do |compareline|
        baseline.line == compareline.line
      end
    end    

  end

  def self.pushChanges(user, newFileName)
 
    newFile = TodoFile.importFile(newFileName, user)
    oldFile = user.todo_files.where(["filename=? and id <> ?", newFileName,newFile.id]).order("created_at DESC").first

    puts "OLD"

    oldFile.todo_lines.each do |line|
      puts line.line
    end

    puts "NEW"

    newFile.todo_lines.each do |line|
      puts line.line
    end

  
    
    if (!oldFile.nil?)
        puts "Deleted"
    
        deleted = TodoFile.compareFiles(oldFile, newFile)
        puts deleted.length
        deletedGuids = deleted.map do |line|
          line.guid
        end
      
      user.tasks.where([ "client_id in (?)", deletedGuids ]).delete_all
      puts deleted.map do |line|
       line.line
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
