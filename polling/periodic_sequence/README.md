# Periodic Polling of a Sequence of Activities

This sample demonstrates how to use a Child Workflow for periodic Activity polling.

This is a rare scenario where polling requires execution of a Sequence of Activities, or Activity arguments need to change between polling retries. For this case we use a Child Workflow to call polling activities a set number of times in a loop and then periodically call Continue-As-New.

## How to Run

To run, first see [README.md](../README.md) for prerequisites.

1. **Start the Worker:**

    Open a terminal and run the following command to start the worker process.
    The worker will listen for tasks on the `frequent-polling-sample` task queue.

    ```bash
      bundle exec ruby worker.rb
    ```

    You will see the worker log messages indicating it is calling the service.
    It will try several times, with a short delay between each attempt.

2. **Start the Workflow:**

    In a separate terminal, run this command to start the workflow.
    This script will start the workflow and wait for its completion,
    printing the final result.

    ```bash
      bundle exec ruby starter.rb
    ```

    After a few seconds, the service will succeed.
    You will see the final result printed in the starter's terminal,
    and the worker will log the successful completion.

