require "temporalio/activity"
require_relative "models"
require_relative "shopping_cart_workflow"

module Workflows
  # Activities used by the shopping cart workflow.
  module ShoppingCartActivities
    # Fetch products for the given skus.
    class FetchProducts < Temporalio::Activity::Definition
      class Input
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveModelJSONSupport

        # @!attribute skus
        #   @return [Array<String>]
        attribute :skus
      end

      # @param input [Input]
      # @return [Array<Models::DatabaseProduct>]
      def execute(input)
        # Fetch and convert to Temporal-safe model
        Product.where(sku: input.skus).map do |prod|
          Models::DatabaseProduct.from_record(prod)
        end
      end
    end

    # Apply payment for a given amount and payment ID.
    class ApplyPayment < Temporalio::Activity::Definition
      class Input
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveModelJSONSupport

        attribute :amount, :decimal
        attribute :payment_id, :string
      end

      # @param input [Input]
      # @return [String] Payment capture ID.
      def execute(input)
        Temporalio::Activity::Context.current.logger.info(
          "Applying payment of #{input.amount} to payment ID #{input.payment_id}"
        )
        # In this sample there is no actual payment application, so return a fake capture ID
        "fake-payment-capture-id"
      end
    end

    # Persist a completed order in the database.
    class PersistCompletedOrder < Temporalio::Activity::Definition
      class Input
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveModelJSONSupport

        # @!attribute cart
        #   @return [Models::ShoppingCart]
        attribute :cart
        attribute :cart_workflow_run_id, :string
        attribute :payment_id, :string
        attribute :payment_capture_id, :string
      end

      # @param input [Input]
      # @return [String] Completed order ID.
      def execute(input)
        order = Order.new(
          cart_workflow_run_id: input.cart_workflow_run_id,
          payment_id: input.payment_id,
          payment_capture_id: input.payment_capture_id,
        )
        input.cart.entries.each do |entry|
          order.order_products << OrderProduct.new(
            product_id: entry.product.id,
            quantity: entry.quantity,
            price: entry.product.price
          )
        end
        order.save!
        order.id
      end
    end
  end
end
