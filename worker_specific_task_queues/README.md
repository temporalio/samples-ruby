# Worker-Specific Task Queues

Use a unique Task Queue for each Worker in order to have certain Activities run on a specific Worker.

This is useful in scenarios where multiple Activities need to run in the same process or on the same host, for example to share memory or disk. This sample has a file processing Workflow, where one Activity downloads the file to disk and other Activities process it and clean it up.

This strategy is:

- Each Worker process runs two workers:
  - One worker listens on the shared `worker-specific-task-queues-sample` Task Queue.
  - Another worker listens on a uniquely generated Task Queue.
- Create a `GetUniqueTaskQueue` Activity that returns one of the uniquely generated Task Queues (that only one Worker is listening on—i.e. the **Worker-specific Task Queue**). It doesn't matter where this Activity is run, so it can be executed on the shared Task Queue. In this sample, the unique Task Queue is simply a UUID, but you can inject smart logic here to uniquely identify the Worker.
- The Workflow and the first Activity are run on the shared `worker-specific-task-queues-sample` Task Queue. The rest of the Activities that do the file processing are run on the Worker-specific Task Queue.

Activities have been artificially slowed with `sleep(3)` to simulate slow activities.

### Running this sample

1. Make sure Temporal Server is running locally (see [temporalio/docker-compose](https://github.com/temporalio/docker-compose))
2. Run the following to start the worker:
```
bundle exec ruby worker.rb
```

3. In another terminal, run the workflow:
```
bundle exec ruby run_workflow.rb
```

You should see output in the worker terminal showing the file being downloaded, processed, and cleaned up. 