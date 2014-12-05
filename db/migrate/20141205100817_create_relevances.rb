class CreateRelevances < ActiveRecord::Migration
  def change
    create_table :relevances do |t|
      t.references :session, index: true
      t.integer :rank
      t.string :relevance

      t.timestamps
    end
  end
end
