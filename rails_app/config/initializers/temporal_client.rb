require "temporal_client"

# Eagerly load this in production so app fails if it cannot connect
TemporalClient.instance unless Rails.env.test? || ENV['NO_EAGER_TEMPORAL_CLIENT'] == '1'
