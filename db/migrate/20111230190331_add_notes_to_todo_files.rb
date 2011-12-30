class AddNotesToTodoFiles < ActiveRecord::Migration
  def change
    add_column :todo_files, :notes, :text
  end
end
