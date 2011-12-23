class TodoFile < ActiveRecord::Base

  belongs_to :user
  has_many :todo_lines
end
