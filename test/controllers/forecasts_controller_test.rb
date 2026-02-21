# frozen_string_literal: true

require "test_helper"

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @forecast = forecasts(:with_results)
  end

  test "should get index" do
    get forecasts_url
    assert_response :success
  end

  test "index displays forecasts" do
    get forecasts_url
    assert_response :success
    assert_match "Forecasting", response.body
  end

  test "should get new" do
    get new_forecast_url
    assert_response :success
  end

  test "new pre-fills with defaults" do
    get new_forecast_url
    assert_response :success
    assert_match "New Forecast", response.body
  end

  test "should create forecast with valid params" do
    assert_difference("Forecast.count") do
      post forecasts_url, params: {
        forecast: {
          name: "Test Scenario",
          projection_months: 12,
          assumptions: {
            monthly_income: 6000,
            monthly_expenses: 4500,
            extra_debt_payment: 300,
            income_growth_rate: 0.03,
            expense_growth_rate: 0.02
          }
        }
      }
    end
    forecast = Forecast.last
    assert_redirected_to forecast_path(forecast)
    assert forecast.parsed_results.present?, "Expected results to be generated"
  end

  test "should not create forecast with invalid params" do
    post forecasts_url, params: {
      forecast: { name: "", projection_months: 0 }
    }
    assert_response :unprocessable_entity
  end

  test "should show forecast with results" do
    get forecast_url(@forecast)
    assert_response :success
    assert_match @forecast.name, response.body
  end

  test "should show forecast without results" do
    forecast = forecasts(:basic_forecast)
    get forecast_url(forecast)
    assert_response :success
  end

  test "should destroy forecast" do
    assert_difference("Forecast.count", -1) do
      delete forecast_url(@forecast)
    end
    assert_redirected_to forecasts_path
  end

  test "requires authentication" do
    delete session_url
    get forecasts_url
    assert_response :redirect
  end
end
