# frozen_string_literal: true

source 'https://rubygems.org'

# Primary Temporal dependency
gem 'temporalio'

# Some samples require certain dependencies, so they are in groups below alphabetically by group
# TODO(cretz): Move this to coinbase/temporal-ruby and off this fork/branch
# when https://github.com/coinbase/temporal-ruby/pull/335 merged
gem 'temporal-ruby', github: 'cretz/coinbase-temporal-ruby', branch: 'disable-proto-load-option', group: :coinbase_ruby

group :development do
  gem 'minitest'
  gem 'rake'
  gem 'rubocop'
end
