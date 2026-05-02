# frozen_string_literal: true

require 'temporalio/workflow'
require_relative 'triage_types'

class IncidentTriageWorkflow < Temporalio::Workflow::Definition
  workflow_name 'incidentTriageWorkflow'

  def execute(initial_alert)
    @current_alert = initial_alert
    @result = nil
    # agenticHitl-shaped timeouts (matches lexicon-temporal's profile).
    @result = Temporalio::Workflow.execute_activity(
      'triage_incident_activity',
      @current_alert,
      start_to_close_timeout: 8 * 60 * 60,  # 8 hours
      heartbeat_timeout: 120,                 # 120 s
      retry_policy: Temporalio::RetryPolicy.new(maximum_attempts: 1)
    )
    @result
  end

  workflow_signal name: 'alert-update'
  def alert_update(alert)
    # Webhook may re-fire with refreshed alert state. Agent reads the latest
    # via the current-alert query.
    @current_alert = alert
  end

  workflow_query name: 'current-alert'
  def current_alert
    @current_alert
  end

  workflow_query name: 'triage-result'
  def triage_result
    @result
  end
end
