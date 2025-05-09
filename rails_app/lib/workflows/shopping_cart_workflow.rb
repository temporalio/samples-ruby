require "temporalio/workflow"
require_relative "models"
require_relative "shopping_cart_workflow"

module Workflows
  # Workflow representing a shopping cart.
  class ShoppingCartWorkflow < Temporalio::Workflow::Definition
    # Expose `@cart` and `@completed_order` as queries.
    workflow_query_attr_reader :cart, :completed_order

    def initialize
      @cart = Models::ShoppingCart.new
    end

    # Primary method for the workflow.
    #
    # @return [Models::CompletedOrder]
    def execute
      # Wait for order to be present (i.e. checkout) and return it. Cancel can cancel this cart.
      Temporalio::Workflow.wait_condition { completed_order }
    ensure
      # Go ahead and mark the cart complete no matter how completed (may have already been marked complete by update)
      cart.complete = true
    end

    # Add a cart entry.
    #
    # @param sku [String]
    # @param quantity [Integer]
    # @return [Models::ShoppingCartEntry]
    workflow_update
    def add_cart_entry(sku, quantity)
      # Get product from DB
      # NOTE: A proper shopping cart may not store the price in the workflow since it can become stale
      product = Temporalio::Workflow.execute_activity(
        ShoppingCartActivities::FetchProducts,
        ShoppingCartActivities::FetchProducts::Input.new(skus: [ sku ]),
        start_to_close_timeout: 15
      ).first
      raise Temporalio::Error::ApplicationError, "Product not found" unless product

      # Fail here if checked out. This is safe because nothing waits after this.
      raise Temporalio::Error::ApplicationError, "Already checked out" if @checked_out

      # Add entry to cart and return it
      Models::ShoppingCartEntry.new(
        id: @entry_counter = (@entry_counter ||= 0) + 1,
        product:,
        quantity:
      ).tap { |e| cart.entries << e }
    end

    # Remove a cart entry.
    #
    # @param entry_id [Integer]
    workflow_update
    def remove_cart_entry(entry_id)
      # Fail here if checked out. This is safe because nothing waits after this.
      raise Temporalio::Error::ApplicationError, "Already checked out" if @checked_out

      # Remove or fail
      cart.entries.reject! { |e| e.id == entry_id } or raise Temporalio::Error::ApplicationError, "Not found"
      nil
    end

    # Checkout the cart.
    #
    # @param payment_id [String]
    # @return [Models::CompletedOrder]
    workflow_update
    def checkout(payment_id)
      # Mark checked out so other interactions cannot occur (we will unmark it if we fail)
      @checked_out = true

      raise Temporalio::Error::ApplicationError, "No entries" unless cart.entries
      raise Temporalio::Error::ApplicationError, "Invalid payment ID" unless payment_id

      # Apply payment
      payment_capture_id = Temporalio::Workflow.execute_activity(
        ShoppingCartActivities::ApplyPayment,
        ShoppingCartActivities::ApplyPayment::Input.new(amount: current_total, payment_id:),
        start_to_close_timeout: 15
      )

      # Complete order (and set/return it)
      id = Temporalio::Workflow.execute_activity(
        ShoppingCartActivities::PersistCompletedOrder,
        ShoppingCartActivities::PersistCompletedOrder::Input.new(
          cart:,
          cart_workflow_run_id: Temporalio::Workflow.info.run_id,
          payment_id:,
          payment_capture_id:,
        ),
        start_to_close_timeout: 15
      )
      cart.complete = true
      @completed_order = Models::CompletedOrder.new(id:, cart:, payment_id:, payment_capture_id:)
    rescue
      # If there was a failure, say we are not checked out
      @checked_out = false
      raise
    end

    # Get the current total.
    #
    # @return [BigDecimal]
    workflow_query
    def current_total
      cart.entries.sum { |e| e.product.price * e.quantity }
    end
  end
end
