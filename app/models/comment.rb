class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :task_file_revision
  belongs_to :todo_file

  attr_accessible :content_length, :start_pos, :user_id, :replacement_content, :todo_file_id
  validates_presence_of :user_id, :start_pos, :content_length, :task_file_revision_id, :todo_file_id


end
