# Message Passing Protobuf

This sample has a simple workflow that accepts signals, queries, and updates.

To run, first see [README.md](../README.md) for prerequisites. Then, in another terminal, start the Ruby worker
from this directory:

    bundle exec ruby worker.rb

Finally in another terminal, use the Ruby client to the workflow from this directory:

    bundle exec ruby starter.rb

The Ruby code will invoke the workflow which will execute two activities and return. The output of the final command
should be:

```
Starting workflow
Supported languages: ["chinese", "english"]
Language changed: english -> chinese
Language changed: chinese -> arabic
Workflow result: مرحبا بالعالم
```

There are also [tests](../test/message_passing_protobuf/greeting_workflow_test.rb).