class AddIsPublicToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :is_public, :boolean
  end
end
