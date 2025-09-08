# Saga

This sample demonstrates undo/compensation using a very simplistic Saga pattern.

To run, first see [README.md](../README.md) for prerequisites. Then, in another terminal, start the Ruby worker
from this directory:

    bundle exec ruby worker.rb

Finally in another terminal, use the Ruby client to the workflow from this directory:

    bundle exec ruby starter.rb

By intention, this will fail with an exception and backtrace. The exception will be a
`Temporalio::Error::WorkflowFailedError` with a cause of `Temporalio::Error::ActivityError` that will have a
"Simulated failure" message.

Looking at the worker side, the following logs will be visible (adjusted for clarity):

```
INFO -- : Withdrawing 100 from acc1000. Reference ID: 1324
INFO -- : Depositing 100 into acc2000. Reference ID: 1324
INFO -- : Simulate failure to trigger compensation. Reference ID: 1324
WARN -- : Completing activity as failed
WARN -- : Simulated failure
<backtrace omitted>
INFO -- : Undoing deposit of 100 into acc2000. Reference ID: 1324
INFO -- : Undoing withdraw of 100 from acc1000. Reference ID: 1324
```

This shows a withdraw and deposit activity completing, but then an activity raised an error (by intention in this
sample), so we undo the deposit/withdraw in reverse before re-raising that error. These steps that were performed are
also visible in the UI.