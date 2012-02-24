class AddCurrentRevisionToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :current_task_file_revision_id, :integer
  end
end
