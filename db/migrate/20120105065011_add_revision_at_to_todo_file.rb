class AddRevisionAtToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :revision_at, :datetime
  end
end
