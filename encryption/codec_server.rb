# frozen_string_literal: true

require 'sinatra/base'
require 'temporalio/api'
require_relative 'codec'

module Encryption
  class CodecServer < Sinatra::Base
    set :bind, '127.0.0.1'
    set :port, 8081

    CODEC = Codec.new
    CORS_ORIGIN = 'http://localhost:8233'

    def on_payloads(&)
      # Must request JSON
      halt 415, 'Unsupported Media Type' unless request.media_type == 'application/json'

      # Apply and convert to JSON
      payloads = Temporalio::Api::Common::V1::Payloads.decode_json(request.body.read)
      applied = Temporalio::Api::Common::V1::Payloads.new(payloads: yield(payloads.payloads))
      content_type 'application/json'
      applied.to_json
    end

    before do
      # Set CORS headers if it matches expected origin
      if request.env['HTTP_ORIGIN'] == CORS_ORIGIN
        headers({
                  'Access-Control-Allow-Origin' => CORS_ORIGIN,
                  'Access-Control-Allow-Methods' => 'POST',
                  'Access-Control-Allow-Headers' => 'content-type,x-namespace'
                })
      end
    end

    post('/encode') { on_payloads { |payloads| CODEC.encode(payloads) } }
    post('/decode') { on_payloads { |payloads| CODEC.decode(payloads) } }
    options('/decode') { '' }
  end
end

# Run if this file started directly
Encryption::CodecServer.run! if $PROGRAM_NAME == __FILE__
