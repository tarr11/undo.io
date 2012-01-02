class TaskFileRevision < ActiveRecord::Base
  belongs_to :todo_file
  belongs_to :user

end
