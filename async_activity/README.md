# Async Activity

This sample shows calling async activities from a simple workflow.

To run, first see [README.md](../README.md) for prerequisites. Then, in another terminal, start the Ruby worker
from this directory:

    bundle exec ruby worker.rb

Finally in another terminal, use the Ruby client to the workflow from this directory:

```temporal workflow start --type MyWorkflow --task-queue apps --workflow-id foo```

All activities should be scheduled.