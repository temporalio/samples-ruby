# typed: strict

class Temporalio::Activity::Definition
  extend T::Sig
  extend T::Generic
  abstract!

  Input = type_member(:in)
  Output = type_member(:out)

  sig { abstract.params(arg: Input).returns(Output) }
  def execute(arg); end
end
