class AddViewedFileToSharedFile < ActiveRecord::Migration
  def change
    add_column :shared_files, :viewed_file, :boolean
  end
end
