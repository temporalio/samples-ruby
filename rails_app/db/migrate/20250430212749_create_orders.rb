class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.string :cart_workflow_run_id
      t.string :payment_id
      t.string :payment_capture_id

      t.timestamps
    end
    add_index :orders, :cart_workflow_run_id, unique: true
  end
end
