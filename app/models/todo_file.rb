class TodoFile < ActiveRecord::Base

  belongs_to :user
  has_many :todo_lines


  def importFile(filename, user)
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
  end
end
