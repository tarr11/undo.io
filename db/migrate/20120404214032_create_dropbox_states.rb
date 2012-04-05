class CreateDropboxStates < ActiveRecord::Migration
  def change
    create_table :dropbox_states do |t|
      t.integer :user_id
      t.string :cursor

      t.timestamps
    end
  end
end
