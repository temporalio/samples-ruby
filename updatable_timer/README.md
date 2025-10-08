# Updatable Timer Sample

Demonstrates a helper class which relies on `Temporalio::Workflow.wait_condition` to implement a blocking sleep that can be updated at any moment.

To run, first see [README.md](../README.md) for prerequisites. Then, in another terminal, start the Ruby worker from this directory:

```bash
  bundle exec ruby worker.rb
```

Then in another terminal, use the Ruby client to the workflow from this directory:

```bash
  bundle exec ruby starter.rb
```

The Ruby code will invoke the workflow which will create a timer that will resolve in a day.

Finally in a third terminal, run the updater to change the timer to 10 seconds from now:

```bash
  bundle exec ruby wake_up_timer_updater.rb
```

There is also a [test](../test/updatable_timer/updatable_timer_workflow_test.rb) that demonstrates querying the wake up time.
