class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :task
      t.integer :user_id
      t.integer :application_id

      t.timestamps
    end
  end
end
