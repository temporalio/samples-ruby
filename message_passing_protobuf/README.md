# Message Passing Protobuf

This sample has a simple workflow that accepts signals, queries, and updates.

This uses [buf](https://buf.build/) to generate the Ruby protobufs and relies on the
Protobuf Payload Converter that ships with this SDK.

When you install `buf` you can regenerate the proto files by simply:

    buf generate

> Note that we are swapping out the Protobuf Data Converter to force the `binary` one because
this [fix](https://github.com/temporalio/sdk-ruby/pull/347) for `json` protobuf support has not been released yet.
> This can be removed when that fix lands.


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