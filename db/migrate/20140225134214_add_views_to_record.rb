class AddViewsToRecord < ActiveRecord::Migration[4.2]
  def change
    add_column :records, :views, :integer, default: 0
  end
end
