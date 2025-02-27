# typed: true
# frozen_string_literal: true

require 'sorbet-runtime'
require 'temporalio/activity'

module SorbetGeneric
  class SayHelloActivity < Temporalio::Activity::Definition
    extend T::Sig
    extend T::Generic

    Input = type_member { { fixed: String } }
    Output = type_member { { fixed: String } }

    sig { override.params(name: Input).returns(Output) }
    def execute(name)
      "Hello, #{name}!"
    end
  end
end
