# Activity Heartbeating and Cancellation

This sample demonstrates activity heartbeating and proper cancellation handling. The activity reports progress via heartbeats, which allows it to resume from the last reported progress if it fails and is retried. The sample also demonstrates how to properly handle cancellation in activities.

To run, first see [README.md](../README.md) for prerequisites. Then, in another terminal, start the Ruby worker
from this directory:

    bundle exec ruby worker.rb

Finally in another terminal, execute the workflow from this directory:

    bundle exec ruby starter.rb

The workflow will start the activity that simulates work by tracking progress from 1 to 100. After 15 seconds, the client will cancel the workflow, which will cancel the activity. The activity will detect the cancellation, log it, and raise a cancellation error.

## What to look for

This sample showcases several important concepts:

1. **Activity Heartbeating**: The activity reports its progress using `context.heartbeat(progress)`. If the activity fails and is retried, it will resume from the last reported progress rather than starting over.

2. **Heartbeat Timeout**: The workflow sets a heartbeat timeout of 3 seconds for the activity, which means the server will consider the activity failed if it doesn't receive a heartbeat for more than 3 seconds.

3. **Cancellation Handling**: The activity checks for cancellation after each progress increment using `context.cancellation.canceled?`. When cancelled, it properly raises a `Temporalio::Error::CanceledError`.

4. **Cancellation Type**: The workflow uses `cancellation_type: :wait_cancellation_completed` to ensure the workflow doesn't proceed until the activity has acknowledged and processed the cancellation. 