class AddSlugToRecord < ActiveRecord::Migration
  def change
    add_column :records, :slug, :string
  end
end
