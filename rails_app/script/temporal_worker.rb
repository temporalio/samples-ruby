require "temporal_client"
require "temporalio/worker"
require "workflows/shopping_cart_activities.rb"
require "workflows/shopping_cart_workflow.rb"

# Create a simple worker then run until interrupt
worker = Temporalio::Worker.new(
  client: TemporalClient.instance,
  task_queue: TemporalClient.task_queue,
  activities: [
    Workflows::ShoppingCartActivities::FetchProducts,
    Workflows::ShoppingCartActivities::ApplyPayment,
    Workflows::ShoppingCartActivities::PersistCompletedOrder
  ],
  workflows: [ Workflows::ShoppingCartWorkflow ]
)
Rails.logger.info "Starting Temporal worker (ctrl+c to exit)"
worker.run(shutdown_signals: [ "SIGINT" ])
