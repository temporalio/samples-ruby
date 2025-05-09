require "test_helper"

module API
  class ShoppingCartsControllerTest < ActionDispatch::IntegrationTest
    test "missing cart 404's" do
      get "/api/shopping_carts/invalid-id"
      assert_response :not_found
      assert_match "application/json", response.content_type
      assert_equal "Cart not found", JSON.parse(response.body)["error"]
    end

    test "shopping cart full process" do
      with_worker_running do |worker|
        user_id = "user-#{SecureRandom.uuid}"
        scooter = Product.find_by!(name: "Scooter")
        tv = Product.find_by!(name: "TV")

        # Add 2 scooters
        post "/api/shopping_carts/#{user_id}/entries",
          params: { sku: scooter.sku, quantity: 2 },
          as: :json
        assert_response :success

        # Add 1 TV
        post "/api/shopping_carts/#{user_id}/entries",
          params: { sku: tv.sku, quantity: 1 },
          as: :json
        assert_response :success
        tv_response = JSON.parse(response.body)

        # Check total
        get "/api/shopping_carts/#{user_id}/current_total"
        assert_response :success
        assert_equal (scooter.price * 2) + tv.price, JSON.parse(response.body)

        # Remove just the TV and check total again
        delete "/api/shopping_carts/#{user_id}/entries/#{tv_response["id"]}"
        assert_response :success
        get "/api/shopping_carts/#{user_id}/current_total"
        assert_response :success
        assert_equal scooter.price * 2, JSON.parse(response.body)

        # Checkout
        post "/api/shopping_carts/#{user_id}/checkout",
          params: { payment_id: "fake-payment-id" },
          as: :json
        assert_response :success

        # Use Temporal client to get workflow and confirm completed
        assert_equal Temporalio::Api::Enums::V1::WorkflowExecutionStatus::WORKFLOW_EXECUTION_STATUS_COMPLETED,
          TemporalClient.instance.workflow_handle("shopping-cart-#{user_id}").describe.status

        # Confirm cart 404's unless you tell it to include completed
        get "/api/shopping_carts/#{user_id}"
        assert_response :not_found
        get "/api/shopping_carts/#{user_id}?include_completed=1"
        assert_response :success
        assert JSON.parse(response.body)["complete"]
      end
    end

    test "shopping cart with unknown sku" do
      with_worker_running do |worker|
        user_id = "user-#{SecureRandom.uuid}"

        # Add unknown sku
        post "/api/shopping_carts/#{user_id}/entries",
          params: { sku: "does-not-exist", quantity: 2 },
          as: :json
        assert_response :bad_request
        assert_equal "Product not found", JSON.parse(response.body)["error"]
      end
    end

    test "shopping cart cancel" do
      with_worker_running do |worker|
        user_id = "user-#{SecureRandom.uuid}"
        scooter = Product.find_by!(name: "Scooter")

        # Add a scooter
        post "/api/shopping_carts/#{user_id}/entries",
          params: { sku: scooter.sku, quantity: 1 },
          as: :json
        assert_response :success

        # Cancel the workflow and wait for it to show not found
        post "/api/shopping_carts/#{user_id}/cancel"
        assert_response :accepted

        # Try every 300ms to confirm cart gone
        10.times do |i|
          get "/api/shopping_carts/#{user_id}"
          assert_response :not_found
          break
        rescue Minitest::Assertion
          raise if i == 9
          sleep(0.3)
        end
      end
    end
  end
end
