class CreateSessions < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.references :task, index: true
      t.string :query

      t.timestamps
    end
  end
end
