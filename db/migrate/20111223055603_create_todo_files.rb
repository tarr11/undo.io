class CreateTodoFiles < ActiveRecord::Migration
  def change
    create_table :todo_files do |t|
      t.string :filename
      t.text :contents
      t.integer :user_id

      t.timestamps
    end
  end
end
