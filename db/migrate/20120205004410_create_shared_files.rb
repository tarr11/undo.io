class CreateSharedFiles < ActiveRecord::Migration
  def change
    create_table :shared_files do |t|
      t.integer :todo_file_id
      t.integer :user_id

      t.timestamps
    end
  end
end
