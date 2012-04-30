# This migration comes from unsubscribe (originally 20120430015655)
class CreateUnsubscribeUnsubscribers < ActiveRecord::Migration
  def change
    create_table :unsubscribe_unsubscribers do |t|
      t.string :email

      t.timestamps
    end
  end
end
