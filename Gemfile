# frozen_string_literal: true

source 'https://rubygems.org'

# Primary Temporal dependency
gem 'temporalio'

# Some samples require certain dependencies, so they are in groups below alphabetically by group

group :coinbase_ruby do
  # TODO(cretz): Move this to coinbase/temporal-ruby and off this fork/branch
  # when https://github.com/coinbase/temporal-ruby/pull/335 merged, and then update the coinbase_ruby README
  gem 'temporal-ruby', github: 'cretz/coinbase-temporal-ruby', branch: 'disable-proto-load-option'
end

group :development do
  gem 'minitest'
  gem 'rake'
  gem 'rubocop'
end

group :encryption do
  gem 'puma'
  gem 'rackup'
  gem 'sinatra'
end
