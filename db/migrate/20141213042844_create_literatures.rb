class CreateLiteratures < ActiveRecord::Migration
  def change
    create_table :literatures do |t|
      t.string :title
      t.string :authors

      t.timestamps
    end
  end
end
