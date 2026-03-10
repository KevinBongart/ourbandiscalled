class AddNotNullConstraintsToRecords < ActiveRecord::Migration[8.1]
  def change
    # Remove any broken records (missing required fields) before adding constraints
    reversible do |dir|
      dir.up do
        execute <<~SQL
          DELETE FROM records
          WHERE band IS NULL OR title IS NULL OR slug IS NULL
             OR cover IS NULL OR wikipedia_url IS NULL
             OR quotationspage_url IS NULL OR flickr_url IS NULL
        SQL
      end
    end

    change_column_null :records, :band,               false
    change_column_null :records, :title,              false
    change_column_null :records, :slug,               false
    change_column_null :records, :cover,              false
    change_column_null :records, :wikipedia_url,      false
    change_column_null :records, :quotationspage_url, false
    change_column_null :records, :flickr_url,         false
    change_column_null :records, :views,              false
  end
end
