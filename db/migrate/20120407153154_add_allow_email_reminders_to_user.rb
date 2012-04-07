class AddAllowEmailRemindersToUser < ActiveRecord::Migration
  def change
    add_column :users, :allow_email_reminders, :boolean

  end
end
