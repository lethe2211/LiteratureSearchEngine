class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :userid
      t.string :interfaceid

      t.timestamps
    end
  end
end
