# frozen_string_literal: true

class CaptureNetWorthJob < ApplicationJob
  queue_as :default

  def perform
    # Only capture once per month
    return if NetWorthSnapshot.exists?(recorded_at: Date.current.beginning_of_month..Date.current.end_of_month)
    NetWorthSnapshot.capture!
  end
end
