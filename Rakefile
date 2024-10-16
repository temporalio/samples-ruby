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

require 'steep/rake_task'

Steep::RakeTask.new

namespace :rbs do
  desc 'RBS tasks'
  task :install_collection do
    sh 'rbs collection install'
  end
end

task default: %w[rubocop test]
