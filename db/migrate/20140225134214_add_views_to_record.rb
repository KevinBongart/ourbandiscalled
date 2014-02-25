class AddViewsToRecord < ActiveRecord::Migration
  def change
    add_column :records, :views, :integer, default: 0
  end
end
