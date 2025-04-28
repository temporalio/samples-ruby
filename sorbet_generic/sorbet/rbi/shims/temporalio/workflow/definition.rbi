# typed: strict

class Temporalio::Workflow::Definition
  extend T::Sig
  extend T::Generic
  abstract!

  Input = type_member(:in)
  Output = type_member(:out)

  sig { abstract.params(arg: Input).returns(Output) }
  def execute(arg); end

  class Signal
    extend T::Sig
    extend T::Generic

    Input = type_member(:in)
  end

  class Query
    extend T::Sig
    extend T::Generic

    Input = type_member(:in)
    Output = type_member(:out)
  end

  class Update
    extend T::Sig
    extend T::Generic

    Input = type_member(:in)
    Output = type_member(:out)
  end
end
