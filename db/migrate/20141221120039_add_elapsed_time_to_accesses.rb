class AddElapsedTimeToAccesses < ActiveRecord::Migration
  def change
    add_column :accesses, :elapsed_time, :decimal
  end
end
