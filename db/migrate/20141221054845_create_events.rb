class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.references :task, index: true
      t.string :event_type
      t.decimal :elapsed_time

      t.timestamps
    end
  end
end
