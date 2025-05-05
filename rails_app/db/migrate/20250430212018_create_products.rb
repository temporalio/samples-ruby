class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :sku
      t.string :name
      t.decimal :price

      t.timestamps
    end
    add_index :products, :sku, unique: true
  end
end
