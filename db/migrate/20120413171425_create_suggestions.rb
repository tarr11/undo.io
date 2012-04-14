class CreateSuggestions < ActiveRecord::Migration
  def change
    create_table :suggestions do |t|
      t.integer :user_id, :null => false
      t.integer :todo_file_id, :null => false
      t.integer :task_file_revision_id, :null => false
      t.integer :start_pos, :null => false
      t.integer :content_length, :null => false
      t.text :original_content
      t.text :replacement_content

      t.timestamps
    end
  end
end
