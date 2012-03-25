class AddFileUuidToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :file_uuid, :string
    add_index "todo_files", ["file_uuid"], :name => "index_todo_files_on_file_uuid", :unique => true
  end
end
