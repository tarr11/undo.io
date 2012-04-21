class TaskFileRevision < ActiveRecord::Base

  serialize :diff
  belongs_to :todo_file
  belongs_to :user
  validates_presence_of :revision_at, :filename, :user_id,:revision_uuid, :edit_source

  has_many :suggestions
end
