# Standalone Activity

This sample demonstrates [Standalone Activities](https://docs.temporal.io/standalone-activity):
Activities executed directly from a Client, without a Workflow.

To run, first see [README.md](../README.md) for prerequisites. Standalone Activities require
Temporal CLI v1.7.0+ and Temporal Server v1.31.0+.

Start a Temporal dev server in one terminal:

    temporal server start-dev

In another terminal, start the Worker from this directory:

    bundle exec ruby worker.rb

The Worker registers `ComposeGreeting` and polls the `standalone-activity-sample` Task Queue.
No Workflows are required.

## Execute a Standalone Activity

Run an Activity from the Client and block until the result is returned:

    bundle exec ruby execute_activity.rb

Expected output:

    Activity result: Hello, World!

Or use the Temporal CLI:

    temporal activity execute \
      --type ComposeGreeting \
      --activity-id standalone-activity-id \
      --task-queue standalone-activity-sample \
      --start-to-close-timeout 10s \
      --input '"Hello"' \
      --input '"World"'

## Start a Standalone Activity without waiting

Start an Activity, get back an `ActivityHandle`, and fetch the result later:

    bundle exec ruby start_activity.rb

Or use the Temporal CLI:

    temporal activity start \
      --type ComposeGreeting \
      --activity-id standalone-activity-id \
      --task-queue standalone-activity-sample \
      --start-to-close-timeout 10s \
      --input '"Hello"' \
      --input '"World"'

## List Standalone Activities

List Standalone Activity Executions matching a [List Filter](https://docs.temporal.io/list-filter):

    bundle exec ruby list_activities.rb

Or use the Temporal CLI:

    temporal activity list --query "TaskQueue = 'standalone-activity-sample'"

## Count Standalone Activities

Count Standalone Activity Executions matching a List Filter:

    bundle exec ruby count_activities.rb

Or use the Temporal CLI:

    temporal activity count --query "TaskQueue = 'standalone-activity-sample'"
