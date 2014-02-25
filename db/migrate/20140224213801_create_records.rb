class CreateRecords < ActiveRecord::Migration
  def change
    create_table :records do |t|
      t.string :band
      t.string :title
      t.string :cover

      t.timestamps
    end
  end
end
