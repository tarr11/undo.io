class CreateTodoFiles < ActiveRecord::Migration
  def change
    create_table :todo_files do |t|
      t.string :FileName
      t.text :Contents
      t.integer :user_id

      t.timestamps
    end
  end
end
