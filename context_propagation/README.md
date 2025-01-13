# Context Propagation

This sample shows how a thread/fiber local can be propagated through workflows and activities using an interceptor.

To run, first see [README.md](../README.md) for prerequisites. Then, in another terminal, start the Ruby worker
from this directory:

    bundle exec ruby worker.rb

Finally in another terminal, use the Ruby client to the workflow from this directory:

    bundle exec ruby starter.rb

The Ruby code will invoke the workflow which will execute an activity and return. Note the log output from the worker
that contains logs on which user is calling the workflow/activity, information which we set as thread local on the
client and was automatically propagated through to the workflow and activity.