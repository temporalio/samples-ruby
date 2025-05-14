require "temporal_client"

class ApplicationController < ActionController::API
  # Custom Temporal RPC error handler
  rescue_from Temporalio::Error::RPCError, with: :render_rpc_error
  rescue_from Temporalio::Error::WorkflowUpdateFailedError, with: :render_update_error

  private

  def render_rpc_error(exception)
    # Not found to 404, otherwise re-raise
    if exception.code == Temporalio::Error::RPCError::Code::NOT_FOUND
      # We assume this is only for "Cart"s for this sample, but general code may not want to assume that
      render json: { error: "Cart not found" }, status: :not_found
    else
      raise exception
    end
  end

  def render_update_error(exception)
    if exception.cause.is_a?(Temporalio::Error::ApplicationError)
      render json: { error: exception.cause.message }, status: :bad_request
    else
      raise exception
    end
  end
end
