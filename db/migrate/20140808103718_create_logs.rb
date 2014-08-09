class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :userid
      t.string :interfaceid
      t.text :query
      t.integer :rank
      t.string :relevance

      t.timestamps
    end
  end
end
