class AddColumnLiteratureIdToAccesses < ActiveRecord::Migration
  def change
    add_column :accesses, :literature_id, :integer
  end
end
