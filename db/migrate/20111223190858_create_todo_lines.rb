class CreateTodoLines < ActiveRecord::Migration
  def change
    create_table :todo_lines do |t|
      t.integer :user_id
      t.string :line
      t.string :guid
      t.integer :todo_file_id

      t.timestamps
    end
  end
end
