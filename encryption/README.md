# Encryption

This sample shows how to make an encryption codec for end-to-end encryption. It is built to match encryption samples in
other SDK languages.

To run, first see [README.md](../README.md) for prerequisites. Then with the local dev server running, in another
terminal, start the Ruby worker from this directory:

    bundle exec ruby worker.rb

Finally in another terminal, use the Ruby client to the workflow from this directory:

    bundle exec ruby starter.rb

The Ruby starter will invoke the workflow which and return output like:

    Workflow result: Hello, Temporal!

Run this to get the workflow output via CLI:

    temporal workflow show --workflow-id encryption-sample-workflow-id

The result will be encrypted and not very visible. Same for UI when visiting
http://localhost:8233/namespaces/default/workflows/encryption-sample-workflow-id. The input and result are encrypted.

This is because the data is end-to-end encrypted and neither interface knows how to decrypt it by default. But both
interfaces can be provided a codec endpoint that they will invoke to get the decrypted data for viewing.

To run the codec server, run the following in a separate terminal from this directory:

    bundle exec ruby codec_server.rb

Now with the codec server running, provide it to the CLI when showing workflow:

    temporal workflow show --workflow-id encryption-sample-workflow-id --codec-endpoint http://localhost:8081

Now the result shows:

    Result          "Hello, Temporal!"

This decoding was done in the CLI. The Temporal server itself never accesses or even knows about the codec endpoint.

This also applies to the UI. In the UI, set the "Remote Codec Endpoint" to `http://localhost:8081`. This is in the upper
right via the sunglasses icon at the time of this writing. Once set, visit/refresh
http://localhost:8233/namespaces/default/workflows/encryption-sample-workflow-id and the input/result are now decrypted
for viewing. Like CLI, this does not happen on the server, but in the browser itself and is a completely optional
feature.