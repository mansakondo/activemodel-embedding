class CreateMARCRecords < ActiveRecord::Migration[6.1]
  def change
    create_table :marc_records do |t|
      t.string :leader
      t.json :fields

      t.timestamps
    end
  end
end
