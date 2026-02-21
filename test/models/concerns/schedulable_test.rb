require "test_helper"

class SchedulableTestModel
  include ActiveModel::Model
  include ActiveModel::Attributes
  include Schedulable

  attribute :frequency, :integer
  attribute :start_date, :date
  attribute :custom_interval_value, :integer
  attribute :custom_interval_unit, :integer
end

class SchedulableTest < ActiveSupport::TestCase
  # --- next_occurrence_after: weekly ---

  test "weekly next_occurrence_after returns correct date" do
    model = SchedulableTestModel.new(frequency: 0, start_date: Date.new(2026, 1, 5))
    result = model.next_occurrence_after(Date.new(2026, 2, 10))
    assert_equal Date.new(2026, 2, 16), result
  end

  test "weekly next_occurrence_after when date falls on an occurrence returns next week" do
    model = SchedulableTestModel.new(frequency: 0, start_date: Date.new(2026, 1, 5))
    # Jan 5 + 5 weeks = Feb 9
    result = model.next_occurrence_after(Date.new(2026, 2, 9))
    assert_equal Date.new(2026, 2, 16), result
  end

  test "weekly next_occurrence_after when date is before start_date returns start_date" do
    model = SchedulableTestModel.new(frequency: 0, start_date: Date.new(2026, 3, 1))
    result = model.next_occurrence_after(Date.new(2026, 2, 10))
    assert_equal Date.new(2026, 3, 1), result
  end

  # --- next_occurrence_after: biweekly ---

  test "biweekly next_occurrence_after returns correct date" do
    model = SchedulableTestModel.new(frequency: 1, start_date: Date.new(2026, 1, 5))
    result = model.next_occurrence_after(Date.new(2026, 2, 10))
    assert result > Date.new(2026, 2, 10)
    days_diff = (result - Date.new(2026, 1, 5)).to_i
    assert_equal 0, days_diff % 14
  end

  test "biweekly next_occurrence_after when date falls on an occurrence returns next biweek" do
    model = SchedulableTestModel.new(frequency: 1, start_date: Date.new(2026, 1, 5))
    # Jan 5 + 14 = Jan 19, Jan 19 + 14 = Feb 2
    result = model.next_occurrence_after(Date.new(2026, 2, 2))
    assert_equal Date.new(2026, 2, 16), result
  end

  test "biweekly next_occurrence_after when date is before start_date returns start_date" do
    model = SchedulableTestModel.new(frequency: 1, start_date: Date.new(2026, 3, 1))
    result = model.next_occurrence_after(Date.new(2026, 2, 10))
    assert_equal Date.new(2026, 3, 1), result
  end

  # --- next_occurrence_after: semimonthly ---

  test "semimonthly next_occurrence_after returns 1st and 15th" do
    model = SchedulableTestModel.new(frequency: 2, start_date: Date.new(2026, 1, 1))
    result = model.next_occurrence_after(Date.new(2026, 2, 2))
    assert_equal Date.new(2026, 2, 15), result
  end

  test "semimonthly next_occurrence_after returns next month first date after second date" do
    model = SchedulableTestModel.new(frequency: 2, start_date: Date.new(2026, 1, 1))
    result = model.next_occurrence_after(Date.new(2026, 2, 15))
    assert_equal Date.new(2026, 3, 1), result
  end

  test "semimonthly next_occurrence_after with start_date on 10th uses day 10 and day 24" do
    model = SchedulableTestModel.new(frequency: 2, start_date: Date.new(2026, 1, 10))
    result = model.next_occurrence_after(Date.new(2026, 2, 10))
    assert_equal Date.new(2026, 2, 24), result
  end

  test "semimonthly next_occurrence_after caps second date at 28" do
    model = SchedulableTestModel.new(frequency: 2, start_date: Date.new(2026, 1, 20))
    # day1 = 20, day2 = min(20+14, 28) = 28
    result = model.next_occurrence_after(Date.new(2026, 2, 20))
    assert_equal Date.new(2026, 2, 28), result
  end

  # --- next_occurrence_after: monthly ---

  test "monthly next_occurrence_after returns same day next month" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 20))
    result = model.next_occurrence_after(Date.new(2026, 2, 21))
    assert_equal Date.new(2026, 3, 20), result
  end

  test "monthly next_occurrence_after when date is before occurrence in same month" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 20))
    result = model.next_occurrence_after(Date.new(2026, 2, 10))
    assert_equal Date.new(2026, 2, 20), result
  end

  test "monthly next_occurrence_after handles end-of-month dates" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 31))
    result = model.next_occurrence_after(Date.new(2026, 1, 31))
    # Feb doesn't have 31 days, so Date#>> adjusts to Feb 28
    assert_equal Date.new(2026, 2, 28), result
  end

  test "monthly next_occurrence_after when date is before start_date" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 6, 15))
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert_equal Date.new(2026, 6, 15), result
  end

  # --- next_occurrence_after: quarterly ---

  test "quarterly next_occurrence_after returns every 3 months" do
    model = SchedulableTestModel.new(frequency: 4, start_date: Date.new(2026, 1, 15))
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert_equal Date.new(2026, 4, 15), result
  end

  test "quarterly next_occurrence_after skips to next quarter when past current quarter" do
    model = SchedulableTestModel.new(frequency: 4, start_date: Date.new(2026, 1, 15))
    result = model.next_occurrence_after(Date.new(2026, 4, 15))
    assert_equal Date.new(2026, 7, 15), result
  end

  # --- next_occurrence_after: semi_annual ---

  test "semi_annual next_occurrence_after returns every 6 months" do
    model = SchedulableTestModel.new(frequency: 5, start_date: Date.new(2026, 1, 10))
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert_equal Date.new(2026, 7, 10), result
  end

  test "semi_annual next_occurrence_after returns next year when past second half" do
    model = SchedulableTestModel.new(frequency: 5, start_date: Date.new(2026, 1, 10))
    result = model.next_occurrence_after(Date.new(2026, 7, 10))
    assert_equal Date.new(2027, 1, 10), result
  end

  # --- next_occurrence_after: annual ---

  test "annual next_occurrence_after returns same date next year" do
    model = SchedulableTestModel.new(frequency: 6, start_date: Date.new(2025, 6, 15))
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert_equal Date.new(2026, 6, 15), result
  end

  test "annual next_occurrence_after when past this years date returns next year" do
    model = SchedulableTestModel.new(frequency: 6, start_date: Date.new(2025, 1, 15))
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert_equal Date.new(2027, 1, 15), result
  end

  test "annual next_occurrence_after when date is before start_date" do
    model = SchedulableTestModel.new(frequency: 6, start_date: Date.new(2027, 3, 1))
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert_equal Date.new(2027, 3, 1), result
  end

  # --- next_occurrence_after: custom ---

  test "custom frequency with weeks calculates correctly" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2026, 1, 1),
      custom_interval_value: 6,
      custom_interval_unit: 1 # weeks
    )
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert result > Date.new(2026, 2, 1)
    days_diff = (result - Date.new(2026, 1, 1)).to_i
    assert_equal 0, days_diff % 42 # 6 weeks * 7 days
  end

  test "custom frequency with days calculates correctly" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2026, 1, 1),
      custom_interval_value: 10,
      custom_interval_unit: 0 # days
    )
    result = model.next_occurrence_after(Date.new(2026, 1, 15))
    assert_equal Date.new(2026, 1, 21), result # 1/1 + 20 days
  end

  test "custom frequency with months calculates correctly" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2026, 1, 15),
      custom_interval_value: 2,
      custom_interval_unit: 2 # months
    )
    result = model.next_occurrence_after(Date.new(2026, 3, 15))
    assert_equal Date.new(2026, 5, 15), result
  end

  test "custom frequency with years calculates correctly" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2024, 6, 1),
      custom_interval_value: 2,
      custom_interval_unit: 3 # years
    )
    result = model.next_occurrence_after(Date.new(2026, 5, 31))
    assert_equal Date.new(2026, 6, 1), result
  end

  test "custom frequency when date is before start_date returns start_date" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2026, 6, 1),
      custom_interval_value: 3,
      custom_interval_unit: 1 # weeks
    )
    result = model.next_occurrence_after(Date.new(2026, 2, 1))
    assert_equal Date.new(2026, 6, 1), result
  end

  # --- occurrences_in_range ---

  test "occurrences_in_range returns all dates within range for weekly" do
    model = SchedulableTestModel.new(frequency: 0, start_date: Date.new(2026, 1, 5))
    dates = model.occurrences_in_range(Date.new(2026, 2, 1), Date.new(2026, 2, 28))
    assert dates.length >= 4
    assert dates.all? { |d| d >= Date.new(2026, 2, 1) && d <= Date.new(2026, 2, 28) }
  end

  test "occurrences_in_range returns sorted dates" do
    model = SchedulableTestModel.new(frequency: 0, start_date: Date.new(2026, 1, 5))
    dates = model.occurrences_in_range(Date.new(2026, 2, 1), Date.new(2026, 3, 31))
    assert_equal dates.sort, dates
  end

  test "occurrences_in_range for monthly returns one per month" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 15))
    dates = model.occurrences_in_range(Date.new(2026, 2, 1), Date.new(2026, 4, 30))
    assert_equal 3, dates.length
    assert_equal [Date.new(2026, 2, 15), Date.new(2026, 3, 15), Date.new(2026, 4, 15)], dates
  end

  test "occurrences_in_range for semimonthly returns two per month" do
    model = SchedulableTestModel.new(frequency: 2, start_date: Date.new(2026, 1, 1))
    dates = model.occurrences_in_range(Date.new(2026, 3, 1), Date.new(2026, 3, 31))
    assert_equal 2, dates.length
    assert_equal [Date.new(2026, 3, 1), Date.new(2026, 3, 15)], dates
  end

  test "occurrences_in_range returns empty array when no occurrences in range" do
    model = SchedulableTestModel.new(frequency: 6, start_date: Date.new(2026, 6, 15))
    dates = model.occurrences_in_range(Date.new(2026, 2, 1), Date.new(2026, 2, 28))
    assert_empty dates
  end

  test "occurrences_in_range includes dates on range boundaries" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 1))
    dates = model.occurrences_in_range(Date.new(2026, 3, 1), Date.new(2026, 3, 1))
    assert_equal [Date.new(2026, 3, 1)], dates
  end

  test "occurrences_in_range for quarterly returns one in three month span" do
    model = SchedulableTestModel.new(frequency: 4, start_date: Date.new(2026, 1, 15))
    dates = model.occurrences_in_range(Date.new(2026, 4, 1), Date.new(2026, 6, 30))
    assert_equal 1, dates.length
    assert_equal Date.new(2026, 4, 15), dates.first
  end

  # --- schedule_description ---

  test "schedule_description for weekly" do
    model = SchedulableTestModel.new(frequency: 0, start_date: Date.new(2026, 1, 5)) # Monday
    assert_equal "Weekly on Mondays", model.schedule_description
  end

  test "schedule_description for biweekly" do
    model = SchedulableTestModel.new(frequency: 1, start_date: Date.new(2026, 1, 7)) # Wednesday
    assert_equal "Every 2 weeks on Wednesdays", model.schedule_description
  end

  test "schedule_description for semimonthly" do
    model = SchedulableTestModel.new(frequency: 2, start_date: Date.new(2026, 1, 1))
    assert_equal "1st and 15th of each month", model.schedule_description
  end

  test "schedule_description for monthly" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 15))
    assert_equal "Monthly on the 15th", model.schedule_description
  end

  test "schedule_description for monthly with ordinal suffix" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 1))
    assert_equal "Monthly on the 1st", model.schedule_description
  end

  test "schedule_description for monthly on 2nd" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 2))
    assert_equal "Monthly on the 2nd", model.schedule_description
  end

  test "schedule_description for monthly on 3rd" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 3))
    assert_equal "Monthly on the 3rd", model.schedule_description
  end

  test "schedule_description for quarterly" do
    model = SchedulableTestModel.new(frequency: 4, start_date: Date.new(2026, 1, 15))
    assert_equal "Quarterly on the 15th", model.schedule_description
  end

  test "schedule_description for semi_annual" do
    model = SchedulableTestModel.new(frequency: 5, start_date: Date.new(2026, 1, 10))
    assert_equal "Every 6 months on the 10th", model.schedule_description
  end

  test "schedule_description for annual" do
    model = SchedulableTestModel.new(frequency: 6, start_date: Date.new(2026, 6, 15))
    assert_equal "Annually on June 15", model.schedule_description
  end

  test "schedule_description for custom frequency" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2026, 1, 1),
      custom_interval_value: 3,
      custom_interval_unit: 2 # months
    )
    assert_match(/every 3 months/i, model.schedule_description)
  end

  test "schedule_description for custom frequency with weeks" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2026, 3, 15),
      custom_interval_value: 6,
      custom_interval_unit: 1 # weeks
    )
    description = model.schedule_description
    assert_match(/every 6 weeks/i, description)
    assert_match(/Mar 15, 2026/, description)
  end

  test "schedule_description for custom frequency with days" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2026, 1, 1),
      custom_interval_value: 10,
      custom_interval_unit: 0 # days
    )
    assert_match(/every 10 days/i, model.schedule_description)
  end

  test "schedule_description for custom frequency with years" do
    model = SchedulableTestModel.new(
      frequency: 7,
      start_date: Date.new(2026, 1, 1),
      custom_interval_value: 2,
      custom_interval_unit: 3 # years
    )
    assert_match(/every 2 years/i, model.schedule_description)
  end

  # --- Edge cases ---

  test "next_occurrence_after strictly returns a date after the given date" do
    model = SchedulableTestModel.new(frequency: 3, start_date: Date.new(2026, 1, 15))
    result = model.next_occurrence_after(Date.new(2026, 1, 15))
    assert result > Date.new(2026, 1, 15)
  end

  test "occurrences_in_range handles single day range with occurrence" do
    model = SchedulableTestModel.new(frequency: 0, start_date: Date.new(2026, 1, 5))
    # Jan 5 + 7*4 = Feb 2
    dates = model.occurrences_in_range(Date.new(2026, 2, 2), Date.new(2026, 2, 2))
    assert_equal [Date.new(2026, 2, 2)], dates
  end

  test "occurrences_in_range handles single day range without occurrence" do
    model = SchedulableTestModel.new(frequency: 0, start_date: Date.new(2026, 1, 5))
    dates = model.occurrences_in_range(Date.new(2026, 2, 3), Date.new(2026, 2, 3))
    assert_empty dates
  end

  test "FREQUENCY_MAP contains all expected frequencies" do
    expected_keys = (0..7).to_a
    assert_equal expected_keys, Schedulable::FREQUENCY_MAP.keys.sort
  end

  test "INTERVAL_UNITS contains all expected units" do
    expected = { 0 => :days, 1 => :weeks, 2 => :months, 3 => :years }
    assert_equal expected, Schedulable::INTERVAL_UNITS
  end
end
