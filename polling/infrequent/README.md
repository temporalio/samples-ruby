# Infrequent Polling using Activity Retries

This sample demonstrates how to implement an infrequent polling mechanism using Temporal's automatic Activity Retry feature.

## Purpose

A common requirement for a workflow is to poll an external service until a process is complete. This polling often needs to happen at infrequent intervals (e.g., once a minute or once an hour).

Instead of implementing a `while` loop with a `sleep` call inside the workflow, which can lead to very long-running workflows with large histories, we can offload this logic to Temporal's built-in retry mechanism. This is the more robust and recommended pattern.

This sample shows a workflow that calls an activity. The activity simulates a service that is not immediately available by raising an exception. The workflow configures a `RetryPolicy` on the activity, telling the Temporal Cluster to automatically retry it after a set interval. The workflow itself remains simple and clean, only seeing the final successful result or a terminal failure.

## How to Run

1.  **Start the Worker:**

    Open a terminal and run the following command to start the worker process. The worker will listen for tasks on the `infrequent-activity-retry-task-queue`.

    ```bash
    ruby polling/infrequent/worker.rb
    ```

    You will see the worker log messages indicating it is attempting to run the activity. It will try several times, with a 10-second delay between each attempt.

2.  **Start the Workflow:**

    In a separate terminal, run this command to start the workflow. This script will start the workflow and wait for its completion, printing the final result.

    ```bash
    ruby polling/infrequent/starter.rb
    ```

After about 40 seconds (4 failed attempts with a 10s delay), the service will succeed. You will see the final result printed in the starter's terminal, and the worker will log the successful completion. 