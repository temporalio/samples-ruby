# Temporal Ruby SDK Samples

This is the set of Ruby samples for the [Ruby SDK](https://github.com/temporalio/sdk-ruby).

⚠️ UNDER ACTIVE DEVELOPMENT

The Ruby SDK is under active development and has not released a stable version yet. APIs may change in incompatible ways
until the SDK is marked stable.

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
* [coinbase_ruby](coinbase_ruby) - Demonstrate interoperability with the
  [Coinbase Ruby SDK](https://github.com/coinbase/temporal-ruby).
* [context_propagation](context_propagation) - Use interceptors to propagate thread/fiber local data from clients
  through workflows/activities.
* [message_passing_simple](message_passing_simple) - Simple workflow that accepts signals, queries, and updates.
* [sorbet_generic](sorbet_generic) - Proof of concept of how to do _advanced_ Sorbet typing with the SDK.
* [worker_specific_task_queues](worker_specific_task_queues) - Use a unique Task Queue for each Worker to run a sequence of Activities on the same Worker.

## Development

To check format and test this repository, run:

    bundle exec rake