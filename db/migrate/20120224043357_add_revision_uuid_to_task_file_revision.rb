class AddRevisionUuidToTaskFileRevision < ActiveRecord::Migration
  def change
    add_column :task_file_revisions, :revision_uuid, :uuid
  end
end
