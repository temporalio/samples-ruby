# frozen_string_literal: true

require 'temporalio/activity'

# To get JSON additions for struct
require 'json/add/struct'

module Saga
  module Activities
    # Transfer details parameter we use everywhere
    TransferDetails = Struct.new(
      :amount,
      :from_account,
      :to_account,
      :reference_id
    )

    class Withdraw < Temporalio::Activity::Definition
      def execute(details)
        Temporalio::Activity::Context.current.logger.info(
          "Withdrawing #{details.amount} from #{details.from_account}. Reference ID: #{details.reference_id}"
        )
      end
    end

    class WithdrawCompensation < Temporalio::Activity::Definition
      def execute(details)
        Temporalio::Activity::Context.current.logger.info(
          "Undoing withdraw of #{details.amount} from #{details.from_account}. Reference ID: #{details.reference_id}"
        )
      end
    end

    class Deposit < Temporalio::Activity::Definition
      def execute(details)
        Temporalio::Activity::Context.current.logger.info(
          "Depositing #{details.amount} into #{details.to_account}. Reference ID: #{details.reference_id}"
        )
      end
    end

    class DepositCompensation < Temporalio::Activity::Definition
      def execute(details)
        Temporalio::Activity::Context.current.logger.info(
          "Undoing deposit of #{details.amount} into #{details.to_account}. Reference ID: #{details.reference_id}"
        )
      end
    end

    class SomethingThatFails < Temporalio::Activity::Definition
      def execute(details)
        Temporalio::Activity::Context.current.logger.info(
          "Simulate failure to trigger compensation. Reference ID: #{details.reference_id}"
        )
        raise Temporalio::Error::ApplicationError.new('Simulated failure', non_retryable: true)
      end
    end
  end
end
