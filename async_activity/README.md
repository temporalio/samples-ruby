# Activity Simple

This sample shows calling a couple of simple activities from a simple workflow.

To run, first see [README.md](../README.md) for prerequisites. Then, in another terminal, start the Ruby worker
from this directory:

    bundle exec ruby worker.rb

Finally in another terminal, use the Ruby client to the workflow from this directory:

    bundle exec ruby starter.rb

The Ruby code will invoke the workflow which will execute two activities and return. The output of the final command
should be:

```
Executing workflow
Workflow result: some-db-value from table some-db-table <appended-value>
```

There is also a [test](../test/activity_simple/my_workflow_test.rb) that demonstrates mocking an activity during the
test.