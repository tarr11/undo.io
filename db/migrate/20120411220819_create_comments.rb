class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.integer :user_id
      t.integer :todo_file_id
      t.integer :task_file_revision_id
      t.integer :start_pos
      t.integer :content_length
      t.text :replacement_content

      t.timestamps
    end
  end
end
