class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :title
      t.string :url
      t.integer :cluster_id

      t.timestamps
    end
  end
end
