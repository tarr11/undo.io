class AddDropboxRevisionToTaskFileRevision < ActiveRecord::Migration
  def change
    add_column :task_file_revisions, :dropbox_revision, :string
  end
end
