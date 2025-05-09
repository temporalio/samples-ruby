require "temporal_client"
require "workflows/shopping_cart_workflow"

module API
  module ShoppingCarts
    # API controller for cart entries.
    class EntriesController < ApplicationController
      # Create a cart entry. This will also lazily create the workflow if not running. Expects user_id, sku, and
      # quantity params.
      def create
        # We expect a user ID on the path and a sku + quantity as JSON body. We are going to use update-with-start to
        # lazily create the cart if it is not already created.
        render json: TemporalClient.instance.execute_update_with_start_workflow(
          Workflows::ShoppingCartWorkflow.add_cart_entry,
          params[:sku], params[:quantity],
          start_workflow_operation: Temporalio::Client::WithStartWorkflowOperation.new(
            Workflows::ShoppingCartWorkflow,
            id: "shopping-cart-#{params[:user_id]}", task_queue: TemporalClient.task_queue,
            id_conflict_policy: Temporalio::WorkflowIDConflictPolicy::USE_EXISTING
          )
        )
      end

      # Delete a cart entry. Expects user_id and entry_id params.
      def destroy
        TemporalClient.instance.workflow_handle("shopping-cart-#{params[:user_id]}").execute_update(
          Workflows::ShoppingCartWorkflow.remove_cart_entry, params[:entry_id].to_i
        )
      end
    end
  end
end
