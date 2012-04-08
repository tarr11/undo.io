class CreateTeamProductRequests < ActiveRecord::Migration
  def change
    create_table :team_product_requests do |t|
      t.string :email
      t.text :feedback

      t.timestamps
    end
  end
end
