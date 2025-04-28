# Coinbase Ruby

This sample shows a workflow, activity, and client from [Coinbase Ruby SDK](https://github.com/coinbase/temporal-ruby)
able to interoperate with a workflow, activity, and client from Temporal Ruby SDK. Specifically this sample contains an
activity in both SDKs, a workflow in both SDKs each calling both activities, a worker in both SDKs running in the same
process, and a starter with clients from each SDK each invoking both workflows.

⚠️ NOTE - this requires disabling the loading of protos from the Coinbase Ruby SDK. As of this writing,
https://github.com/coinbase/temporal-ruby/pull/335 is not merged, so the Gemfile depends on the branch at
https://github.com/cretz/coinbase-temporal-ruby/tree/disable-proto-load-option for now.

To run, first see [README.md](../README.md) for prerequisites. Then, in another terminal, start the Ruby worker
from this directory:

    bundle exec ruby worker.rb

Finally in another terminal, use the Ruby client to run the workflow from this directory:

    bundle exec ruby starter.rb

The Ruby code will invoke 4 workflows. The output of the final command should be:

```
Coinbase SDK workflow result from Temporal SDK client: ["Hello from Coinbase Ruby SDK, user1!", "Hello from Temporal Ruby SDK, user1!"]
Temporal SDK workflow result from Temporal SDK client: ["Hello from Coinbase Ruby SDK, user2!", "Hello from Temporal Ruby SDK, user2!"]
Coinbase SDK workflow result from Coinbase SDK client: ["Hello from Coinbase Ruby SDK, user3!", "Hello from Temporal Ruby SDK, user3!"]
Temporal SDK workflow result from Coinbase SDK client: ["Hello from Coinbase Ruby SDK, user4!", "Hello from Temporal Ruby SDK, user4!"]
```