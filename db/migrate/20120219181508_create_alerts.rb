class CreateAlerts < ActiveRecord::Migration
  def change
    create_table :alerts do |t|
      t.references :user
      t.text :message
      t.boolean :was_read

      t.timestamps
    end
    add_index :alerts, :user_id
  end
end
