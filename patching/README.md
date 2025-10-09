# Patching

This sample shows how to safely update a workflow in stages using `Temporalio::Workflow.patch` and `Temporalio::Workflow.deprecate_patch`.

To run, first see [README.md](../README.md) for prerequisites. Then follow the stages below.

## Stage 1

To simulate our initial workflow, start a worker in another terminal

```bash
  bundle exec ruby worker.rb initial
```

Now start a workflow:

```bash
  bundle exec ruby starter.rb start initial-id
```

This will output `Started workflow with id initial-id`.

Now query the workflow:

```bash
  bundle exec ruby starter.rb query initial-id
```

This will output `Query result for id initial-id: pre-patch`

## Stage 2

This stage is for needing to run old and new workflows at the same time.
To simulate our patched workflow, stop the worker from before and start it again with the patched workflow:

```bash
  bundle exec ruby worker.rb patched
```

Now let's start another workflow with this patched code:

```bash
  bundle exec ruby starter.rb start patched-id
```

This will output `Started workflow with id patched-id-workflow-id`.

Now query the old workflow that's still running:

```bash
  bundle exec starter.rb query initial-id
```

This will output "Query result for id initial-id: pre-patch" since it is pre-patch.

But if we execute a query against the new code:

```bash
  bundle exec starter.rb query patched-id
```

We get "Query result for id patched-id: post-patch".

This is how old workflow code can take old paths and new workflow code can take new paths.

## Stage 3

Once we know that all workflows that started with the initial code from "Stage 1" are no longer running,
we don't need the patch so we can deprecate it.
To use the patch deprecated workflow, stop the worker from before and start it again with:

```bash
  bundle exec ruby worker.rb deprecated
```

Querying the initial workflow should error now.

```bash
  bundle exec ruby starter.rb query initial-id
```

Throws an error: `[TMPRL1100] Nondeterminism error: Activity type of scheduled event 'PrePatch' does not match activity type of activity command 'PostPatch'`

All workflows in "Stage 2" and any new workflows can be queried.

Now let's start another workflow with this patch deprecated code:

```bash
  bundle exec ruby starter.rb start deprecated-id
```

This will output `Started workflow with id deprecated-id`.
Now query the patched workflow from "Stage 2"

```bash
  bundle exec ruby starter.rb query patched-id
```

This will output "Query result for id patched-id: post-patch".

And if we execute a query against the latest workflow:

```bash
  bundle exec ruby starter.rb query deprecated-id
```

As expected, this will output "Query result for id deprecated-id: post-patch".

## Stage 4

Once we know we don't even have any workflows running on "Stage 2" or before (i.e. the workflow with the patch with both code paths), we can just remove the patch deprecation altogether.
To use the patch complete workflow, stop the workflow from before and start it again with:

```bash
  bundle exec ruby worker.rb complete
```

All workflows in "Stage 3" and any new workflows will work.
Now let's start another workflow with this patch complete code:

```bash
  bundle exec ruby starter.rb start complete-id
```

Now query the patch deprecated workflow that's still running:

```bash
  bundle exec ruby starter.rb query deprecated-id
```

This will output "Query result for id deprecated-id: post-patch".

And if we execute a query against the latest workflow:

```bash
  bundle exec ruby starter.rb query completed-id
```

As expected, this will output "Query result for id complete-id: post-patch".

Following these stages, we have successfully altered our workflow code.

