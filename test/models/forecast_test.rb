require "test_helper"

class ForecastTest < ActiveSupport::TestCase
  test "valid forecast" do
    forecast = Forecast.new(name: "Test Forecast", projection_months: 12)
    assert forecast.valid?
  end

  test "requires name" do
    forecast = Forecast.new(projection_months: 12)
    assert_not forecast.valid?
    assert_includes forecast.errors[:name], "can't be blank"
  end

  test "requires projection_months" do
    forecast = Forecast.new(name: "Test")
    assert_not forecast.valid?
    assert_includes forecast.errors[:projection_months], "can't be blank"
  end

  test "projection_months must be between 1 and 60" do
    assert_not Forecast.new(name: "Test", projection_months: 0).valid?
    assert_not Forecast.new(name: "Test", projection_months: 61).valid?
    assert Forecast.new(name: "Test", projection_months: 1).valid?
    assert Forecast.new(name: "Test", projection_months: 60).valid?
  end

  test "generate_projection! creates results" do
    forecast = forecasts(:basic_forecast)
    forecast.generate_projection!
    forecast.reload

    assert_not_nil forecast.results
    assert_equal 12, forecast.results.size
    assert_equal 1, forecast.results.first["month"]
    assert_equal 12, forecast.results.last["month"]
  end

  test "generate_projection! includes expected fields" do
    forecast = forecasts(:basic_forecast)
    forecast.generate_projection!
    forecast.reload

    first_month = forecast.results.first
    assert first_month.key?("month")
    assert first_month.key?("date")
    assert first_month.key?("income")
    assert first_month.key?("expenses")
    assert first_month.key?("surplus")
    assert first_month.key?("total_debt")
    assert first_month.key?("savings")
    assert first_month.key?("net_worth")
  end

  test "debt_free_month returns month when debt reaches zero" do
    forecast = forecasts(:with_results)
    assert_equal 3, forecast.debt_free_month
  end

  test "debt_free_month returns nil when no results" do
    forecast = forecasts(:basic_forecast)
    assert_nil forecast.debt_free_month
  end

  test "debt_free_month returns nil when debt never reaches zero" do
    forecast = Forecast.new(
      name: "Never Free",
      projection_months: 3,
      results: [
        { "month" => 1, "total_debt" => 10000.0 },
        { "month" => 2, "total_debt" => 9500.0 },
        { "month" => 3, "total_debt" => 9000.0 }
      ]
    )
    assert_nil forecast.debt_free_month
  end
end
