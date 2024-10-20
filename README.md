# Temporal Ruby SDK Samples

This is the set of Ruby samples for the [Ruby SDK](https://github.com/temporalio/sdk-ruby).

⚠️ UNDER ACTIVE DEVELOPMENT

The Ruby SDK is under active development and has not released a stable version yet. APIs may change in incompatible ways
until the SDK is marked stable.

## Usage

Prerequisites:

* Ruby 3.1+
* Local Temporal server running (can [install CLI](https://docs.temporal.io/cli#install) then
  [run a dev server](https://docs.temporal.io/cli#start-dev-server))
* `bundle install` run in the root

## Samples

<!-- Keep this list in alphabetical order -->
* [activity_worker](activity_worker) - Use Ruby activities from a workflow in another language.

## Development

To check format and test this repository, run:

    bundle exec rake