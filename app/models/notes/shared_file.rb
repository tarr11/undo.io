class SharedFile < ActiveRecord::Base

  belongs_to :user
  belongs_to :todo_file
  validates_uniqueness_of :todo_file_id, :scope => :user_id
  validates_presence_of :user, :todo_file

end
