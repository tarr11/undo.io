class AddReplyToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :reply_to_id, :integer

  end
end
