# frozen_string_literal: true

require "test_helper"

class CaptureNetWorthJobTest < ActiveJob::TestCase
  test "captures net worth snapshot when none exists for current month" do
    # Remove any snapshots for current month
    NetWorthSnapshot.where(recorded_at: Date.current.beginning_of_month..Date.current.end_of_month).destroy_all

    assert_difference("NetWorthSnapshot.count") do
      CaptureNetWorthJob.perform_now
    end

    snapshot = NetWorthSnapshot.last
    assert_equal Date.current, snapshot.recorded_at
    assert snapshot.net_worth.present?
  end

  test "does not capture snapshot when one already exists for current month" do
    # Ensure a snapshot exists for this month
    NetWorthSnapshot.find_or_create_by!(recorded_at: Date.current.beginning_of_month) do |s|
      s.total_assets = 10000
      s.total_liabilities = 5000
      s.net_worth = 5000
      s.breakdown = []
    end

    assert_no_difference("NetWorthSnapshot.count") do
      CaptureNetWorthJob.perform_now
    end
  end
end
