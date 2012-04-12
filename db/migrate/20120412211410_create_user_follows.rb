class CreateUserFollows < ActiveRecord::Migration
  def change
    create_table :user_follows do |t|
      t.integer :user_id
      t.integer :follow_user_id

      t.timestamps
    end
  end
end
