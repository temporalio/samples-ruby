# AWS Lambda worker

This experimental sample hosts a Temporal worker inside each AWS Lambda invocation.
The event is ignored: invoking the function does **not** start a workflow. The worker
polls its Temporal task queue until its shutdown budget begins. Both workflows and
activities are supported. The separate starter runs a greeting workflow and prints
`Hello, Ruby!`.

## Prerequisites and ZIP packaging

See the root [README](../README.md) for general prerequisites. **This sample additionally
requires an unreleased Ruby SDK containing `temporalio/contrib/aws/lambda_worker`.**
The released SDK in the root bundle does not yet include this integration.
Do not expect `bundle install` alone to make the Lambda handler available.

AWS provides a managed Ruby runtime and supports
[ZIP deployment packages](https://docs.aws.amazon.com/lambda/latest/dg/ruby-package.html).
Docker is not required.

Obtain a platform-specific SDK gem built from the Lambda integration branch of
[sdk-ruby](https://github.com/temporalio/sdk-ruby). The gem must include its native
extension compiled for **Ruby 3.4** and the target **Linux** architecture. SDK native
cross-compilation belongs in that repository (including its `extra/aws_lambda/build_gem.rb`
helper), not in this application sample. Follow that SDK checkout's build instructions.
Do not use a macOS extension or an uncompiled source gem. Dependencies such as
`google-protobuf` also contain native code and must match the target environment.

Run the following on an **Amazon Linux 2023 machine with Ruby 3.4 and native build tools
(GCC and Make)**, matching the
function's architecture (`arm64` for an `aarch64-linux` SDK gem, or `x86_64` for an
`x86_64-linux` gem). This can be a build machine or CI runner; no container is needed.
From the samples repository root, use a **new, empty** staging directory so old
dependencies or configuration cannot leak into the archive:

```bash
mkdir aws_lambda/package
cp aws_lambda/lambda_function.rb aws_lambda/greeting_workflow.rb \
  aws_lambda/greeting_activity.rb aws_lambda/package/
gem install /path/to/temporalio-VERSION-aarch64-linux.gem \
  --install-dir "$PWD/aws_lambda/package/vendor/bundle/ruby/3.4.0" --no-document
(cd aws_lambda/package && zip -r ../lambda-worker.zip \
  lambda_function.rb greeting_workflow.rb greeting_activity.rb vendor)
```

The Lambda runtime finds bundled gems under `vendor/bundle/ruby/3.4.0`.
The handler source must be at the archive root, not inside a `package/` directory.
The archive contains only the three application files and their gems; do not add
credentials, local environment files, or sensitive TOML files. The package directory
and ZIP are Git-ignored. Check native libraries and archive size against the
[AWS packaging requirements](https://docs.aws.amazon.com/lambda/latest/dg/ruby-package.html)
before deployment.

## Configure and deploy

Configure these environment variables on the function:

| Variable | Value |
| --- | --- |
| `TEMPORAL_ADDRESS` | Temporal endpoint, e.g. `localhost:7233` locally or your namespace's Cloud endpoint |
| `TEMPORAL_NAMESPACE` | Temporal namespace |
| `TEMPORAL_API_KEY` | If required; supply using your deployment's secret management, never source or the ZIP |
| `TEMPORAL_TASK_QUEUE` | Task queue for this worker |
| `TEMPORAL_DEPLOYMENT_NAME` | Required worker deployment name |
| `TEMPORAL_WORKER_BUILD_ID` | Required immutable code version, e.g. a commit SHA |

Standard envconfig TLS, mTLS, and profiles are supported. For file configuration, set
`TEMPORAL_CONFIG_FILE` to a readable TOML path. Without an explicit path, the handler looks
for `temporal.toml` in `LAMBDA_TASK_ROOT` (or the current directory outside Lambda).
Provision sensitive files at runtime, not via the ZIP. Environment and connection
configuration are read on **each invocation**; the deployment version is fixed when the
handler is loaded. See the [env_config sample](../env_config) for TOML examples.

Create a ZIP-based Lambda function using the managed **Ruby 3.4** runtime, select the
matching architecture, upload `aws_lambda/lambda-worker.zip`, and set its handler to
`lambda_function.lambda_handler`. Grant its execution role CloudWatch logging access and ensure
network access to the Temporal endpoint. Choose a timeout that leaves enough time for
useful work as well as the adapter's shutdown buffer, and size memory for your workload.
This sample does not create resources or deploy anything automatically.

Configure your Temporal Cloud serverless worker integration to invoke this function for
its deployment version and task queue. Invocation provisioning is separate from the SDK
adapter: it does not configure AWS or Temporal Cloud. For a manual smoke test, invoke the
function with `{}` while starting a workflow in another terminal.

## Start a workflow

The worker deployment must register before a workflow explicitly pinned to that version
can start. With a worker invocation running, run the starter using the same connection,
task queue, deployment name, and build ID. Install the unreleased SDK for your **host**
platform and run outside the released root bundle:

```bash
ruby aws_lambda/starter.rb
```

Set the connection, task queue, and deployment variables in your shell first, plus any
envconfig TLS/profile variables or `TEMPORAL_CONFIG_FILE` needed for TOML.
A macOS development machine needs a macOS SDK gem, not the Linux deployment gem.
The starter uses the same TOML lookup as
the handler. It prints `Hello, Ruby!`; subsequent invocations can resume a workflow after
an earlier worker has stopped.

## Lifecycle and limits

- A fresh client and worker are created per invocation; no live worker or workflow cache
  survives it. Application registrations, executors, and the process-level SDK runtime
  can be shared on warm starts.
- Deployment name and build ID are mandatory. The adapter always enables worker
  versioning, sets invocation-specific identity, and disables eager activity execution.
  The default is `PINNED`: keep old Lambda versions invocable until their pinned
  workflows complete or are migrated. To opt into `AUTO_UPGRADE`, explicitly pass
  `default_versioning_behavior: Temporalio::VersioningBehavior::AUTO_UPGRADE` to
  `LambdaWorker::Options.new` in `lambda_function.rb`. Only do this when workflow
  updates remain replay compatible.
- The adapter supplies Lambda-tuned worker defaults. Consult the SDK's
  `LambdaWorker::Options` documentation for configuration, including `worker_options`
  and `shutdown_buffer`, rather than relying on a separate list of defaults here.
  Ruby does not support Nexus workers yet.
- Setup counts against the work budget. The buffer covers worker drain, cleanup, and
  telemetry hooks. Shutdown cancels activities after their grace period, but **cannot
  forcibly terminate arbitrary user code**. Activities must honor cancellation (see
  [activity_heartbeating](../activity_heartbeating)). Hooks receive the remaining budget
  in seconds and must return within it. There is no guarantee arbitrary application
  code finishes before AWS's hard timeout.
- Workers do not return just because their queue is idle. Do not rely on Lambda's
  background execution after returning a response. Do not configure concurrent
  invocations on a single handler instance.

## Optional telemetry

CloudWatch receives normal Ruby logging. Set `TEMPORAL_LAMBDA_TELEMETRY=1` to enable
the application's optional configuration in [`telemetry.rb`](telemetry.rb). This
initializes a reusable tracing provider/exporter and a Core metrics runtime when the
handler is loaded, not on each invocation. The base Lambda adapter has no OpenTelemetry
dependency.

To package this option, run these additional commands on the same Linux build machine
after preparing the base package:

```bash
cp aws_lambda/telemetry.rb aws_lambda/otel-collector-config.yaml aws_lambda/package/
gem install opentelemetry-sdk opentelemetry-exporter-otlp \
  --install-dir "$PWD/aws_lambda/package/vendor/bundle/ruby/3.4.0" --no-document
(cd aws_lambda/package && zip -r ../lambda-worker.zip \
  telemetry.rb otel-collector-config.yaml vendor)
```

Attach an [ADOT Collector Lambda layer](https://aws-otel.github.io/docs/getting-started/lambda)
matching the function's architecture, and set
`OPENTELEMETRY_COLLECTOR_CONFIG_URI=/var/task/otel-collector-config.yaml`. The supplied
collector accepts Ruby traces via OTLP/HTTP on `127.0.0.1:4318` and Core metrics via
OTLP/gRPC on `127.0.0.1:4317`. It exports detailed telemetry to the function's
CloudWatch logs for sandbox verification, **not** to X-Ray or CloudWatch Metrics.
Replace the debug exporter with your chosen production destination and grant its
required execution-role permissions. Detailed logs can contain workflow identifiers
and application attributes; do not use them indiscriminately in production.

The optional application configuration supports:

| Variable | Purpose |
| --- | --- |
| `OTEL_SERVICE_NAME` | Service name for traces and metrics |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | Trace HTTP endpoint, including `/v1/traces` |
| `TEMPORAL_METRICS_ENDPOINT` | Core metrics gRPC endpoint |

The sample exports metrics periodically during an invocation; this is not a synchronous
shutdown flush. It composes the existing tracing interceptor through a `SimplePlugin`
and an application-defined shutdown hook. To propagate a complete trace from a starter
through the workflow and activity, instrument the starter's client with the same tracing
interceptor (see [open_telemetry](../open_telemetry)). Without an incoming client trace,
the interceptor still produces activity spans but omits workflow spans by default.
For custom provider setup, the relevant composition looks like:

```ruby
require 'opentelemetry/sdk'
require 'temporalio/contrib/open_telemetry'
require 'temporalio/simple_plugin'

provider = OpenTelemetry.tracer_provider # Already configured by the application.
tracing = Temporalio::SimplePlugin.new(
  name: 'application-tracing',
  client_interceptors: [
    Temporalio::Contrib::OpenTelemetry::TracingInterceptor.new(provider.tracer('temporal-ruby'))
  ]
)
options = Temporalio::Contrib::Aws::LambdaWorker::Options.new(
  workflows: [AwsLambda::GreetingWorkflow],
  activities: [AwsLambda::GreetingActivity],
  plugins: [tracing],
  shutdown_hooks: [
    ->(remaining) { provider.force_flush(timeout: remaining) if remaining.positive? }
  ]
)
# Pass options: options to LambdaWorker.define.
```

The hook receives the remaining invocation budget in **seconds** after worker and
connection cleanup and passes that budget to the provider's trace flush. Hooks must
return within their remaining budget. Do not shut down the provider on each invocation:
warm invocations reuse the application-owned provider and exporter. Configure exporters
to a collector reachable from Lambda, such as an ADOT extension.
See [open_telemetry](../open_telemetry) for provider setup.
Core metrics can use a shared `Temporalio::Runtime` supplied in
`client_options[:runtime]`; use an export interval shorter than the invocation.
Core periodic metric export is **not** synchronously flushed by the trace hook, so
metrics produced just before Lambda freezes may be delayed or lost.

## Validation scope

The workflow test runs with the regular repository bundle:

```bash
bundle exec ruby -Itest -I. test/aws_lambda/greeting_workflow_test.rb
```

It validates the application workflow/activity, not AWS provisioning or the unreleased
Lambda adapter. To test two warm invocations in one Ruby process with an unreleased SDK
installed for your host platform, start a local server in another terminal:

```bash
temporal server start-dev --ip 0.0.0.0 --port 17233 --headless
```

Then, from the samples repository root, outside Bundler:

```bash
TEMPORAL_ADDRESS=localhost:17233 TEMPORAL_NAMESPACE=default \
  TEMPORAL_TASK_QUEUE=lambda-migration-smoke TEMPORAL_DEPLOYMENT_NAME=lambda-migration-smoke \
  TEMPORAL_WORKER_BUILD_ID=migration-v1 ruby test/aws_lambda/local_smoke.rb
```

Each simulated invocation has a 20-second budget and runs the real starter in a separate
process. The smoke test retries only the initial "pinned version not present" registration
race, checks `Hello, Ruby!` for both invocations, and waits for each handler to shut down.
Use an isolated local server/task queue; this is not a test to run against production.
It does not emulate the Lambda runtime API or AWS's hard timeout.

For an AWS sandbox test, use an isolated function, task queue, and deployment:

1. Build and upload the ZIP for the selected managed runtime and architecture. For
   telemetry, enable the option and attach/configure the collector as described above.
2. Publish a Lambda version. Configure the matching Temporal serverless deployment
   version with its qualified ARN and a scoped invocation role, then select its routing.
   Follow the [serverless deployment guide](https://docs.temporal.io/production-deployment/worker-deployments/serverless-workers/aws-lambda)
   for account-specific provisioning. Do not repoint another application's deployment.
3. Run the starter and confirm `Hello, Ruby!`. Repeat after the previous invocation
   shuts down so the test exercises another invocation rather than the same worker.
4. Check workflow history for `PINNED` behavior and the expected deployment/build ID.
   Check Lambda logs for clean completion without hard timeouts or cleanup errors.
   Multiple requests in the same log stream provide evidence of warm process reuse.
5. In the collector output, verify actual `RunActivity:GreetingActivity` spans
   (including `temporalWorkflowID`) and `temporal_activity_*` metrics for the tested
   workflow, not merely collector startup messages. For stronger flush/provider reuse
   evidence, instrument the application's hook to record its remaining budget, flush
   result, and provider identity across invocations.

The collector debug exporter verifies OTLP delivery, not delivery to an external trace
backend such as X-Ray. Validate each target architecture separately.
