class AddUserIdToTaskFileRevision < ActiveRecord::Migration
  def change
    add_column :task_file_revisions, :user_id, :integer
  end
end
