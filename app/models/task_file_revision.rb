class TaskFileRevision < ActiveRecord::Base

  serialize :diff
  belongs_to :todo_file
  belongs_to :user
end
