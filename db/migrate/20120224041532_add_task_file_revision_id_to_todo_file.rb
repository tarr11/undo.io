class AddTaskFileRevisionIdToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :copied_task_file_revision_id, :integer
  end
end
