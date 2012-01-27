class AddDiffToTaskFileRevision < ActiveRecord::Migration
  def change
    add_column :task_file_revisions, :diff, :text
  end
end
