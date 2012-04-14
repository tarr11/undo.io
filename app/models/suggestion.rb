class Suggestion < ActiveRecord::Base
  belongs_to :user
  belongs_to :task_file_revision
  belongs_to :todo_file

  attr_accessible :content_length, :start_pos, :user_id, :original_content, :replacement_content, :todo_file_id, :line_number, :line_column
  validates_presence_of :user_id, :start_pos, :content_length, :task_file_revision_id, :todo_file_id, :line_number,:line_column
end
