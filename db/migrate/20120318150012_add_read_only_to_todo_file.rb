class AddReadOnlyToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :is_read_only, :boolean

  end
end
