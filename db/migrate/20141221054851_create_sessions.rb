class CreateSessions < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.references :query, index: true
      t.integer :start_num
      t.integer :end_num

      t.timestamps
    end
  end
end
