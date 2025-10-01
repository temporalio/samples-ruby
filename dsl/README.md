# DSL

This sample demonstrates having a workflow interpret/invoke arbitrary steps defined in a DSL. It is similar to the DSL
samples in [TypeScript](https://github.com/temporalio/samples-typescript/tree/main/dsl-interpreter), in
[Go](https://github.com/temporalio/samples-go/tree/main/dsl), and in
[Python](https://github.com/temporalio/samples-python/tree/main/dsl).

To run, first see [README.md](../README.md) for prerequisites. Then, in another terminal, start the Ruby worker
from this directory:

    bundle exec ruby worker.rb

Now, in another terminal, run the following from this directory to execute a workflow of steps defined in
[workflow1.yaml](workflow1.yaml):

    bundle exec ruby starter.rb workflow1.yaml

This will run the workflow and show the final variables that the workflow returns. Looking in the worker terminal, each
step executed will be visible.

Similarly we can do the same for the more advanced [workflow2.yaml](workflow2.yaml) file:

    bundle exec ruby starter.rb workflow2.yaml

This sample gives a guide of how one can write a workflow to interpret arbitrary steps from a user-provided DSL. Many
DSL models are more advanced and are more specific to conform to business logic needs.