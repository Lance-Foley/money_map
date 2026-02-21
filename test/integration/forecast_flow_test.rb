# frozen_string_literal: true

require "test_helper"

class ForecastFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "can view forecasts index" do
    get forecasts_path
    assert_response :success
  end

  test "can view new forecast form" do
    get new_forecast_path
    assert_response :success
  end

  test "can create and view a forecast" do
    assert_difference("Forecast.count") do
      post forecasts_path, params: {
        forecast: {
          name: "Test Forecast",
          projection_months: 12,
          assumptions: {
            monthly_income: 6000,
            monthly_expenses: 4500,
            extra_debt_payment: 200,
            income_growth_rate: 0.03,
            expense_growth_rate: 0.02
          }
        }
      }
    end
    assert_response :redirect
    forecast = Forecast.last
    assert_equal "Test Forecast", forecast.name
    assert forecast.results.present?

    # Can view the forecast
    get forecast_path(forecast)
    assert_response :success
  end

  test "can delete a forecast" do
    forecast = forecasts(:with_results)
    assert_difference("Forecast.count", -1) do
      delete forecast_path(forecast)
    end
    assert_redirected_to forecasts_path
  end
end
