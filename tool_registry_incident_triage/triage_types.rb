# frozen_string_literal: true

# Shared data types for the Ruby triage worker. Plain Structs — Temporal Ruby
# SDK serializes them via the data-converter contract.
module TriageTypes
  AlertPayload = Struct.new(:status, :labels, :annotations, :starts_at, :ends_at, :fingerprint, keyword_init: true)
  ProposedRemediation = Struct.new(:action, :justification, keyword_init: true)
  TriageResult = Struct.new(:status, :summary, :remediations, keyword_init: true)
  ApprovalRequest = Struct.new(:message, :diagnosis, :proposed_action, keyword_init: true)
  ApprovalResponse = Struct.new(:decision, :reason, keyword_init: true)
end
