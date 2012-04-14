class AddLineNumberToSuggestion < ActiveRecord::Migration
  def change
    add_column :suggestions, :line_number, :integer, :null => false

  end
end
