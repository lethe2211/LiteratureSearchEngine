class CreateSessions < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.string :userid
      t.string :interfaceid
      t.string :query

      t.timestamps
    end
  end
end
