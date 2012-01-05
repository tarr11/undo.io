class AddDropboxRevisionToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :dropbox_revision, :string
  end
end
