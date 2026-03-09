class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.text :body, null: false
      t.string :author, null: false
      t.integer :source_id, null: false
      t.string :url, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :quotes, :source_id, unique: true
    add_index :quotes, :used_at
  end
end
