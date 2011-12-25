class CreateDropboxWrappers < ActiveRecord::Migration
  def change
    create_table :dropbox_wrappers do |t|

      t.timestamps
    end
  end
end
