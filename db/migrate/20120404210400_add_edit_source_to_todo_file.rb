class AddEditSourceToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :edit_source, :string

  end
end
