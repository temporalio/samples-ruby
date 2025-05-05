# Rails

This demonstrates a simple API-only Rails app that uses Temporal. It has the following features:

* Shopping cart workflow, activities, and models
* Active model JSON support for Temporal data conversion
* Database models for products and orders
* Global shared Temporal client
* API controllers for interacting with the shopping cart
* Script for running a Temporal worker

To run, first see the base [README.md](../README.md) for prerequisites such as running the local dev server. Also, make
sure `curl` is available since there will be API calls.

Navigate inside this `rails_app` directory, and run:

    bundle install

With the bundle installed, run the following two commands to setup the database:

    bin/rails db:migrate
    bin/rails db:seed

For this sample, we have enabled extra logging to see what is happening. Now with the database setup, we can start a
worker. In one terminal, run:

    bin/rails runner script/temporal_worker.rb

This runs the worker. To run in production mode, `-e production` can be passed to `runner`.

Now, while the worker is running, in another terminal, start the API server from this directory:

    bin/rails server

With the worker and Rails API server both running, now a shopping cart can be interacted with. First, see which products
are available in the database:

    bin/rails runner "puts Product.all.inspect"

A scooter with SKU "1234" and a TV with SKU "2345" are both available. Fetch the current shopping cart for `my-user-id`:

    curl http://127.0.0.1:3000/api/shopping_carts/my-user-id

This should return:

    {"error":"Cart not found"}

This makes sense, no products have been added. Add 3 scooters to the cart:

    curl -X POST http://127.0.0.1:3000/api/shopping_carts/my-user-id/entries \
         -H "Content-Type: application/json" -d '{ "sku": "1234", "quantity": 3 }'

The result will be JSON showing we've added an entry with ID `1` and some details about the entry. Check the cart again:

    curl http://127.0.0.1:3000/api/shopping_carts/my-user-id

The cart is now present with one entry. The current total can be seen too:

    curl http://127.0.0.1:3000/api/shopping_carts/my-user-id/current_total

This is powered by a Temporal workflow. Getting the cart and total are simply workflow queries.

The workflow can be seen in the UI. If using the local dev server with defaults,
http://localhost:8233/namespaces/default/workflows/shopping-cart-my-user-id will show this cart. Notice how there is an
`add_cart_entry` workflow update the product we added and it had to fetch the product details from the database via an
activity. Can even use the "Queries" tab to fetch the current cart or total.

Now lets remove the 3 scooters, add just 1 scooter, and 2 TVs:

    curl -X DELETE http://127.0.0.1:3000/api/shopping_carts/my-user-id/entries/1
    curl -X POST http://127.0.0.1:3000/api/shopping_carts/my-user-id/entries \
         -H "Content-Type: application/json" -d '{ "sku": "1234", "quantity": 1 }'
    curl -X POST http://127.0.0.1:3000/api/shopping_carts/my-user-id/entries \
         -H "Content-Type: application/json" -d '{ "sku": "2345", "quantity": 21 }'

The workflow history in the UI clearly shows the removal and addition of cart items. All of this state is in Temporal,
there is nothing stored in the database at this time. To complete this cart, call checkout with a payment ID:

    curl -X POST http://127.0.0.1:3000/api/shopping_carts/my-user-id/checkout \
         -H "Content-Type: application/json" -d '{ "payment_id": "my-payment-id" }'

This will apply payment and persist the order in the database. The result will be a JSON with the completed order. The
workflow is now complete as can be seen in the UI. The order can be seen from the database:

    bin/rails runner "puts Order.all.inspect"

This is obviously just a demonstration for this sample. A real shopping cart may have many more layers to it. For
instance, it'd be normal to have a script that looks for open shopping cart workflows with products after some time and
emails users about them.

## Details

### Bootstrapping

This app was created with:

    bin/rails new rails_app --minimal --api --skip-keeps

Then it was adjusted to keep it minimal and DB models were added. Much of the boilerplate code has been left intact.

### Global Client

When using Temporal, most Rails users will want a single Temporal client that is shared across all uses. This sample
does this at [lib/temporal_client.rb](lib/temporal_client.rb) by having a `TemporalClient` module with a singleton
method for `instance` (along with a setter for tests).

Although this is created lazily, it is ideal to load this on Rails startup so it can fail if the connection options are
invalid or the server is unavailable. So
[config/initializers/temporal_client.rb](config/initializers/temporal_client.rb) is a simple file to load on startup in
non-test scenarios.

### Controller Code vs Temporal Workflow/Activity Code

To separate concerns, workflows, activities, and their models are in [lib/workflows](lib/workflows). This separation
from `app` and controller code allows the workflows to be used in any manner, loaded as necessary, rather than to be
assumed as part of the runtime app.

### Database Models vs Temporal Models

It is recommended that database models not be blindly reused as Temporal models. Many database models change as database
needs change, and those needs may not reflect what a workflow or activity needs. Users are encouraged to use active
models made specifically for the Temporal workflow/activity and translate to/from them as needed.

The [lib/workflows/models.rb](lib/workflows/models.rb) file contains all models a workflow client may use when
interacting with a workflow. These are in addition to the activity input models accepted for each activity in
[lib/workflows/shopping_cart_activities.rb](lib/workflows/shopping_cart_activities.rb).

### Active Model Serialization Support

By default, Temporal uses the standard library `JSON` module to serialize/deserialize inputs/outputs. JSON additions are
enabled. By default Ruby only serializes/deserializes objects to/from a `Hash`. To properly deserialize into a specific
class, a key for `JSON.create_id` must be on the JSON object when serialized with the fully qualified class name. A
helper at [lib/workflows/active_model_json_support.rb](lib/workflows/active_model_json_support.rb) is available that can
be `include`d into active models to have them automatically work with Temporal JSON serialization.

### Workers

Workers are long-running Ruby daemons. Per convention, this sample has code to run the worker in
[script/temporal_worker.rb](script/temporal_worker.rb) that can be used with `bin/rails runner`. This allows Rails
features to be available to the worker and its activities (e.g. `Rails.logger`, database, etc).

### Tests

To run tests, simply:

    bin/rails test

As part of this sample, we enabled stdout logs for most things, so it will have a lot of output.

There are two test files in this sample:

* [test/controllers/api/shopping_carts_controller_test.rb](test/controllers/api/shopping_carts_controller_test.rb) -
  Tests parts of the controller API
* [test/workflows/shopping_cart_workflow_test.rb](test/workflows/shopping_cart_workflow_test.rb) - Tests parts of the
  workflow and activities

These are effectively integration tests. To test Temporal workflows, a testing environment is needed, which is often the
same local dev server used to run this sample manually, just downloaded/executed programmatically via
`Temporalio::Testing::WorkflowEnvironment.start_local`. The bottom of [test/test_helper.rb](test/test_helper.rb) shows
how a test server is created for the entire suite, shutdown on suite completion, and has the global client instance set
to the environment client.

Since workflow-related tests need to have a worker running, a `TestHelper#with_worker_running` helper was added to
[test/test_helper.rb](test/test_helper.rb). This also demonstrates using a "mock" activity to replace the actual
`ApplyPayment` activity which a test may want to replace. Users should use similar approaches to mocking out activities
as needed when testing workflows.