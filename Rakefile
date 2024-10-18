# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.warning = false
  t.libs << 'test'
  t.libs << '.'
  t.test_files = FileList['test/**/*_test.rb']
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %w[rubocop test]
