class AddShowSharedMessageToUser < ActiveRecord::Migration
  def change
    add_column :users, :show_shared_message, :boolean
  end
end
