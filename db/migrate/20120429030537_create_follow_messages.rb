class CreateFollowMessages < ActiveRecord::Migration
  def change
    create_table :follow_messages do |t|
      t.integer :user_id
      t.integer :follow_user_id

      t.timestamps
    end
  end
end
