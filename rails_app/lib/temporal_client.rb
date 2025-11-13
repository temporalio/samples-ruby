require "temporalio/client"
require "temporalio/env_config"

module TemporalClient
  def self.instance
    return @instance if @instance

    # Load config and apply defaults
    args, kwargs = Temporalio::EnvConfig::ClientConfig.load_client_connect_options
    args = ["localhost:7233", "default"] if args.empty?

    @instance = Temporalio::Client.connect(*args, **kwargs, logger: Rails.logger)
  end

  def self.instance=(instance)
    raise "Client already set" if @instance
    @instance = instance
  end

  def self.task_queue?
    !@task_queue.nil?
  end

  def self.task_queue
    @task_queue ||= "shopping-cart-task-queue"
  end

  def self.task_queue=(task_queue)
    raise "Task queue already set" if @task_queue && task_queue
    @task_queue = task_queue
  end
end
