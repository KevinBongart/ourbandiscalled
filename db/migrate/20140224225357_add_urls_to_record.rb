class AddUrlsToRecord < ActiveRecord::Migration[4.2]
  def change
    add_column :records, :wikipedia_url, :string
    add_column :records, :quotationspage_url, :string
    add_column :records, :flickr_url, :string
  end
end
