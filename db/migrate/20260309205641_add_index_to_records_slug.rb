class AddIndexToRecordsSlug < ActiveRecord::Migration[8.1]
  def change
    add_index :records, :slug, unique: true
  end
end
