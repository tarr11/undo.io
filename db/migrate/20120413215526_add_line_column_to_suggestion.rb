class AddLineColumnToSuggestion < ActiveRecord::Migration
  def change
    add_column :suggestions, :line_column, :integer

  end
end
