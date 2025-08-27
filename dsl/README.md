# DSL Sample

This sample demonstrates how to create a workflow that can interpret and execute operations defined in a YAML-based Domain Specific Language (DSL). This approach allows you to define workflow steps declaratively in a YAML file, which can be modified without changing the underlying code.

## Overview

The sample shows how to:

1. Define a DSL schema for workflow operations
2. Parse YAML files into Ruby objects
3. Create a workflow that can interpret and execute these operations
4. Execute activities based on the DSL definition
5. Support sequential and parallel execution patterns

## Prerequisites

See the [main README](../README.md) for prerequisites and setup instructions.

## Running the Sample

1. Start the worker in one terminal:

```
ruby worker.rb
```

2. Execute a workflow using one of the example YAML definitions:

```
ruby starter.rb workflow1.yaml
```

This will run the simple sequential workflow defined in `workflow1.yaml`.

3. Try the more complex workflow with parallel execution:

```
ruby starter.rb workflow2.yaml
```

## Understanding the Sample

### DSL Model

The DSL allows defining:

- Variables to be used across the workflow
- Activities with inputs and outputs
- Sequential execution of steps
- Parallel execution of branches

### Workflow Structure

- `my_activities.rb` - Example activities that can be executed by the workflow
- `dsl_models.rb` - Classes representing the DSL schema
- `dsl.rb` - Workflow implementation that interprets and executes the DSL
- `worker.rb` - Worker process that hosts the activities and workflow
- `starter.rb` - Client that reads a YAML file and executes the workflow
- `workflow1.yaml` - Simple sequential workflow example
- `workflow2.yaml` - More complex workflow with parallel execution

### Extending the Sample

You can extend this sample by:

1. Adding more activity types
2. Extending the DSL with new statement types (e.g., conditionals, loops)
3. Adding error handling and retry mechanisms
4. Creating validation for the DSL input 