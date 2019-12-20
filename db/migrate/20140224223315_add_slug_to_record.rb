class AddSlugToRecord < ActiveRecord::Migration[4.2]
  def change
    add_column :records, :slug, :string
  end
end
