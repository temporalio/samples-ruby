# Temporal Ruby SDK Samples

This is the set of Ruby samples for the [Ruby SDK](https://github.com/temporalio/sdk-ruby).

## Usage

Prerequisites:

* Ruby 3.2+
* Local Temporal server running (can [install CLI](https://docs.temporal.io/cli#install) then
  [run a dev server](https://docs.temporal.io/cli#start-dev-server))
* `bundle install` run in the root

## Samples

<!-- Keep this list in alphabetical order -->
* [activity_heartbeating](activity_heartbeating) - Demonstrate activity heartbeating and proper cancellation handling.
* [activity_simple](activity_simple) - Simple workflow that calls two activities.
* [activity_worker](activity_worker) - Use Ruby activities from a workflow in another language.
* [client_mtls](client_mtls) - Demonstrates how to use mutual TLS (mTLS) authentication with the Temporal Ruby SDK.
* [coinbase_ruby](coinbase_ruby) - Demonstrate interoperability with the
  [Coinbase Ruby SDK](https://github.com/coinbase/temporal-ruby).
* [context_propagation](context_propagation) - Use interceptors to propagate thread/fiber local data from clients
  through workflows/activities.
* [dsl](dsl) - Demonstrates having a workflow interpret/invoke arbitrary steps defined in a DSL.
* [eager_wf_start](eager_wf_start) - Demonstrates Eager Workflow Start to reduce latency for workflows that start with a local activity.
* [encryption](encryption) - Demonstrates how to make a codec for end-to-end encryption.
* [env_config](env_config) - Load client configuration from TOML files with programmatic overrides.
* [message_passing_simple](message_passing_simple) - Simple workflow that accepts signals, queries, and updates.
* [polling/infrequent](polling/infrequent) - Implement an infrequent polling mechanism using Temporal's automatic Activity Retry feature.
* [rails_app](rails_app) - Basic Rails API application using Temporal workflows and activities.
* [saga](saga) - Using undo/compensation using a very simplistic Saga pattern.
* [sorbet_generic](sorbet_generic) - Proof of concept of how to do _advanced_ Sorbet typing with the SDK.
* [worker_specific_task_queues](worker_specific_task_queues) - Use a unique Task Queue for each Worker to run a sequence of Activities on the same Worker.
* [worker_versioning](worker_versioning) - Use the Worker Versioning feature to more easily version your workflows & other code.

## Development

To check format and test this repository, run:

    bundle exec rake