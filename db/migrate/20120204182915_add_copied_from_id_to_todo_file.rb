class AddCopiedFromIdToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :copied_from_id, :integer
  end
end
