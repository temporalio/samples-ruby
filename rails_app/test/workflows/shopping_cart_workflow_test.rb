require "test_helper"

module Workflows
  class ShoppingCartWorkflowTest < ActiveSupport::TestCase
    test "simple shopping cart workflow order" do
      with_worker_running do |worker|
        # Start a cart workflow
        handle = TemporalClient.instance.start_workflow(
          ShoppingCartWorkflow,
          id: "wf-#{SecureRandom.uuid}",
          task_queue: worker.task_queue
        )
        # Confirm no total yet
        assert_equal 0, handle.query(ShoppingCartWorkflow.current_total)

        # Add 1 scooter and 2 TVs
        scooter = Product.find_by!(name: "Scooter")
        tv = Product.find_by!(name: "TV")
        handle.execute_update(ShoppingCartWorkflow.add_cart_entry, scooter.sku, 1)
        handle.execute_update(ShoppingCartWorkflow.add_cart_entry, tv.sku, 2)

        # Now check total
        expected_total = scooter.price + (2 * tv.price)
        assert_equal expected_total.to_s, handle.query(ShoppingCartWorkflow.current_total)

        # Checkout and confirm workflow completes with the same order
        payment_id = "mock-payment-id"
        completed_order = handle.execute_update(ShoppingCartWorkflow.checkout, payment_id)
        assert_equal completed_order.as_json, handle.result.as_json

        # Confirm the order is in the DB as expected
        db_order = Order.find(completed_order.id)
        assert_equal db_order.cart_workflow_run_id, handle.result_run_id
        assert_equal db_order.payment_id, completed_order.payment_id
        assert_equal db_order.payment_capture_id, completed_order.payment_capture_id
        assert_equal(
          completed_order.cart.entries.map do |e|
            { product_id: e.product.id, product_price: e.product.price, quantity: e.quantity }
          end,
          db_order.order_products.map do |p|
            { product_id: p.product_id, product_price: p.price, quantity: p.quantity }
          end
        )
      end
    end
  end
end
