# Client mTLS Sample

This sample demonstrates how to use mutual TLS (mTLS) authentication with the Temporal Ruby SDK.

## Overview

mTLS (mutual Transport Layer Security) provides secure, encrypted communication where both client and server authenticate each other. This is required to connect to Temporal Cloud, or to a self-hosted Temporal deployment that is secured with TLS.

The sample includes:

- A simple workflow that executes an activity
- A worker and starter that accept certificate parameters for mTLS authentication
- Command-line options to configure connection parameters

## Prerequisites

Before running this sample, you'll need:

1. A Temporal server with mTLS enabled
2. TLS certificates:
   - Client certificate and private key
   - Server root CA certificate (optional, depending on your setup)

## Running the Sample

### 1. Start the Worker

```bash
ruby worker.rb \
  --client-cert /path/to/client.pem \
  --client-key /path/to/client.key \
  [--server-root-ca-cert /path/to/ca.pem] \
  [--target-host your-temporal-server:7233] \
  [--namespace your-namespace] \
  [--task-queue custom-task-queue]
```

### 2. Execute the Workflow

In a separate terminal:

```bash
ruby starter.rb \
  --client-cert /path/to/client.pem \
  --client-key /path/to/client.key \
  [--server-root-ca-cert /path/to/ca.pem] \
  [--target-host your-temporal-server:7233] \
  [--namespace your-namespace] \
  [--task-queue custom-task-queue]
```

## Common Configurations

### Temporal Cloud with mTLS

When connecting to Temporal Cloud:

- **Address**: Use the mTLS endpoint from Temporal Cloud (e.g., `namespace.tmprl.cloud:7233`)
- **Namespace**: Include the account identifier suffix (e.g., `my-namespace.abc123`)
- **Server Root CA Certificate**: Not typically needed as Temporal Cloud uses well-known Root CAs

### Self-Hosted Temporal with mTLS

For a self-hosted Temporal cluster:

- **Server Root CA Certificate**: Required if your server uses a certificate signed by a private CA
- You'll need both client certificate and key files

## Notes on Certificate Files

Certificate and key files should be in PEM format. The client certificate file may include the full certificate chain if needed.

## Troubleshooting

- If you see TLS handshake errors, verify your certificate paths are correct
- Make sure certificates haven't expired
- For Temporal Cloud, confirm you're using the correct endpoint and namespace 