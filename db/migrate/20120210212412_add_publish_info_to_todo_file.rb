class AddPublishInfoToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :summary, :string
    add_column :todo_files, :published_at, :timestamp
    add_column :task_file_revisions, :summary, :datetime
    add_column :task_file_revisions, :published_at, :datetime

  end

end
