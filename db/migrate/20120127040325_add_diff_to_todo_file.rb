class AddDiffToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :diff, :text
  end
end
