class CreateAccesses < ActiveRecord::Migration
  def change
    create_table :accesses do |t|
      t.references :session, index: true
      t.string :access_type
      t.integer :rank

      t.timestamps
    end
  end
end
