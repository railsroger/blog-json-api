class CreatePosts < ActiveRecord::Migration[5.1]
  def change
    create_table :posts do |t|
      t.integer :user_id
      t.string :title, null: false
      t.text :content, null: false
      t.inet :ip

      t.timestamps

      t.decimal :rate_value, precision: 3, scale: 2
      t.integer :rate_count
    end
  end
end
