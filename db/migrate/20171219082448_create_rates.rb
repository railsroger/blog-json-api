class CreateRates < ActiveRecord::Migration[5.1]
  def change
    create_table :rates do |t|
      t.integer :post_id
      t.decimal :rate, precision: 3, scale: 2
      t.integer :rate_count

      t.timestamps
    end
  end
end
