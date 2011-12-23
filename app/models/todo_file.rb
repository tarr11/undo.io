class TodoFile < ActiveRecord::Base

  belongs_to :user
  has_many :todo_lines


  def importFile(filename, user)
    # import this file using File
    file = File.open(filename, 'r')

    todofile = user.todo_files.new
    todofile.filename = filename
    todofile.save

  end
end
