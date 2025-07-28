# frozen_string_literal: true

require 'minitest/autorun'

class Test < Minitest::Test
  def skip_if_not_x86!
    skip('Test only supported on x86') unless RbConfig::CONFIG['host_cpu'] == 'x86_64'
  end
end
