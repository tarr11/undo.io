class SharedFile < ActiveRecord::Base

  belongs_to :user
  belongs_to :todo_file

end
