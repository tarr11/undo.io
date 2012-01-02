class CreateTaskFileRevisions < ActiveRecord::Migration
  def change
    create_table :task_file_revisions do |t|
      t.integer :todo_file_id
      t.text :contents
      t.string :filename

      t.timestamps
    end
  end
end
