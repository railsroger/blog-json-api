class AddIndexes < ActiveRecord::Migration[5.1]
  def change
    add_index(:posts, [:rate_value, :rate_count], order: { rate_value: :desc, rate_count: :desc})
    add_index(:rates, :post_id)
  end
end
