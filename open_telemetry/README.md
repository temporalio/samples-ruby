# OpenTelemetry Sample

Demonstrates how to use OpenTelemetry tracing and metrics with the Ruby SDK

## How to Run

First, in another terminal start up a Grafana OpenTelemetry instance which will
collect telemetry and provide the Grafana UI for viewing the data.

```bash
  docker compose up
```

In another terminal, start the worker

```bash
  bundle exec ruby worker.rb
```

Finally start the workflow

```bash
  bundle exec ruby starter.rb
```

You should be able to see the result in the terminal.

To view the Grafana dashboard go to `http://localhost:3000`

You can find the trace by clicking on the "Explore" tab,
selecting "Tempo" as the data source, and switching the query type to "Search".

There will be a trace for `my-service` containing the workflow trace.
