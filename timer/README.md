# Timer

Use a timer (`Temporalio::Workflow.sleep`) to implement a monthly subscription. Also, handle workflow cancellation.

To run, first see [README.md](../README.md) for prerequisites. Then, in another terminal, start the Ruby worker
from this directory:

    bundle exec ruby worker.rb

Then in another terminal, start the workflow from this directory:

    bundle exec ruby starter.rb

The worker terminal will show logs from running the workflow. The workflow will sleep for 30 days then charge the
user, repeating until cancelled. To cancel the workflow, use the Temporal CLI:

    temporal workflow cancel --workflow-id timer-sample-workflow-id

There is also a [test](../test/timer/subscription_workflow_test.rb) that demonstrates time-skipping to test the
timer behavior without waiting.
