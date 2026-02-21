require "test_helper"

class NetWorthSnapshotTest < ActiveSupport::TestCase
  test "valid snapshot" do
    snapshot = NetWorthSnapshot.new(
      recorded_at: Date.new(2025, 12, 1),
      net_worth: 50000.00,
      total_assets: 100000.00,
      total_liabilities: 50000.00
    )
    assert snapshot.valid?
  end

  test "requires recorded_at" do
    snapshot = NetWorthSnapshot.new(net_worth: 50000.00)
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:recorded_at], "can't be blank"
  end

  test "requires net_worth" do
    snapshot = NetWorthSnapshot.new(recorded_at: Date.new(2025, 12, 1))
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:net_worth], "can't be blank"
  end

  test "recorded_at must be unique" do
    existing = net_worth_snapshots(:january_snapshot)
    duplicate = NetWorthSnapshot.new(
      recorded_at: existing.recorded_at,
      net_worth: 1000.00
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:recorded_at], "has already been taken"
  end

  test "chronological scope orders by recorded_at" do
    snapshots = NetWorthSnapshot.chronological
    dates = snapshots.map(&:recorded_at)
    assert_equal dates, dates.sort
  end

  test "recent scope returns latest snapshots" do
    recent = NetWorthSnapshot.recent(1)
    assert_equal 1, recent.size
    assert_equal net_worth_snapshots(:february_snapshot).id, recent.last.id
  end

  test "capture! creates a snapshot from active accounts" do
    # Delete existing snapshot for today if any
    NetWorthSnapshot.where(recorded_at: Date.current).destroy_all

    assert_difference "NetWorthSnapshot.count", 1 do
      snapshot = NetWorthSnapshot.capture!
      assert_equal Date.current, snapshot.recorded_at
      assert_not_nil snapshot.total_assets
      assert_not_nil snapshot.total_liabilities
      assert_equal snapshot.total_assets - snapshot.total_liabilities, snapshot.net_worth
      assert_not_nil snapshot.breakdown
    end
  end
end
