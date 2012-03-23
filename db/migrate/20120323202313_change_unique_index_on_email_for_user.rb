class ChangeUniqueIndexOnEmailForUser < ActiveRecord::Migration
  def change
    if index_exists?(:users, :email)
      remove_index :users, :email
    end

    add_index "users", ["email"], :name => "index_users_on_email", :unique => false
  end
end
