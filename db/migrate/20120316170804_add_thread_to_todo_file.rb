class AddThreadToTodoFile < ActiveRecord::Migration
  def change
    add_column :todo_files, :thread_source_id, :integer

    add_column :todo_files, :reply_number, :integer

  end
end
