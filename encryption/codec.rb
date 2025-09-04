# frozen_string_literal: true

require 'openssl'
require 'securerandom'
require 'temporalio/converters'
require 'temporalio/api'
# TODO(cretz): Remove when https://github.com/temporalio/sdk-ruby/issues/333 released
require 'temporalio/converters/payload_codec'

module Encryption
  class Codec < Temporalio::Converters::PayloadCodec
    DEFAULT_KEY_ID = 'test-key-id'
    DEFAULT_KEY = 'test-key-test-key-test-key-test!'.b

    def initialize(key_id: DEFAULT_KEY_ID, key: DEFAULT_KEY)
      super()
      @key_id = key_id
      @cipher_key = key
    end

    def encode(payloads)
      # Encode all payloads using AES-GCM with a random nonce. This sample is built using AESGCM to match other SDK
      # samples, but many users may prefer a different algorithm.
      payloads.map do |p|
        Temporalio::Api::Common::V1::Payload.new(
          metadata: {
            'encoding' => 'binary/encrypted'.b,
            'encryption-key-id' => @key_id.b
          },
          data: encrypt(p.to_proto)
        )
      end
    end

    def decode(payloads)
      payloads.map do |p|
        # Ignore ones w/out our expected encoding
        if p.metadata['encoding'] == 'binary/encrypted'
          key_id = p.metadata['encryption-key-id']
          # Confirm our key ID is the same
          raise "Unrecognized key ID #{key_id}. Current key ID is #{@key_id}." unless key_id == @key_id

          Temporalio::Api::Common::V1::Payload.decode(decrypt(p.data))
        else
          p
        end
      end
    end

    private

    def encrypt(data)
      nonce = SecureRandom.random_bytes(12)
      cipher = OpenSSL::Cipher.new('aes-256-gcm')
      cipher.encrypt
      cipher.key = @cipher_key
      cipher.iv  = nonce
      nonce + cipher.update(data) + cipher.final + cipher.auth_tag
    end

    def decrypt(data)
      cipher = OpenSSL::Cipher.new('aes-256-gcm')
      cipher.decrypt
      cipher.key = @cipher_key
      cipher.iv  = data[0, 12]
      cipher.auth_tag = data[-16, 16]
      cipher.update(data[12...-16]) + cipher.final
    end
  end
end
