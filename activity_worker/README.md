# Activity Worker

This sample shows a Go workflow calling Ruby activity.

To run, first see [README.md](../README.md) for prerequisites. Then, with [Go](https://go.dev/) installed, run the
following from the [go-workflow] directory in a separate terminal to start the Go workflow worker:

    go run .

Then in another terminal, start the Ruby activity worker from this directory:

    bundle exec ruby activity_worker.rb

Finally in another terminal, use the Ruby client to the workflow from this directory:

    bundle exec ruby starter.rb

The Ruby code will invoke the Go workflow which will execute the Ruby activity and return. The output of the final
command should be:

```
Workflow result: Hello, SomeUser!
```