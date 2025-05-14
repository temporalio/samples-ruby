require "temporal_client"
require "workflows/shopping_cart_workflow"

module API
  # API controller for shopping carts.
  class ShoppingCartsController < ApplicationController
    # Describe the cart. Expects user_id param, and optional include_completed param.
    def show
      # We expect a user ID on the path
      cart = TemporalClient.instance.workflow_handle("shopping-cart-#{params[:user_id]}").query(
        Workflows::ShoppingCartWorkflow.cart
      )
      # If cart completed, do not render unless include_completed is 1
      if cart.complete && params[:include_completed] != "1"
        render json: { error: "Cart not found" }, status: :not_found
        return
      end
      render json: cart
    end

    # Cancel the cart. Canceled in background. Expects a user_id param.
    def cancel
      # Issue a cancel and only say it's "accepted"
      TemporalClient.instance.workflow_handle("shopping-cart-#{params[:user_id]}").cancel
      head :accepted
    end

    # Checkout the cart. Expects user_id and payment_id params.
    def checkout
      # Perform checkout and return the completed order
      render json: TemporalClient.instance.workflow_handle("shopping-cart-#{params[:user_id]}").execute_update(
        Workflows::ShoppingCartWorkflow.checkout,
        params[:payment_id]
      )
    end

    # Get the current cart total. Expects user_id param.
    def current_total
      # Just get the current total and return it
      render json: TemporalClient.instance.workflow_handle("shopping-cart-#{params[:user_id]}").query(
        Workflows::ShoppingCartWorkflow.current_total
      )
    end
  end
end
