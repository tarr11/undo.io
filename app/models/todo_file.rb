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


  def self.compareFiles(oldFile, newFile)

    # find deleted lines - in old, but not new
    return oldFile.todo_lines.find_all do |oldline|
      !newFile.todo_lines.any? do |newline|
        newline.line == oldline.line
      end
    end    

  end

  def self.pushChanges(user, oldFile, newFile)
    
    deleted = TodoFile.compareFiles(oldFile, newFile)
    inserted = TodoFile.compareFiles(newFile, oldFile)

    #deleted.all.each do |line|
    

  end

end
