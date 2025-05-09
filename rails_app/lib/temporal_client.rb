require "temporalio/client"

module TemporalClient
  def self.instance
    @instance ||=  Temporalio::Client.connect("localhost:7233", "default", logger: Rails.logger)
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
