class AddRevisionAtToTaskFileRevision < ActiveRecord::Migration
  def change
    add_column :task_file_revisions, :revision_at, :datetime
  end
end
