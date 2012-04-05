class AddEditSourceToTaskFileRevision < ActiveRecord::Migration
  def change
    add_column :task_file_revisions, :edit_source, :string

  end
end
