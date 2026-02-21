# frozen_string_literal: true

class ForecastsController < ApplicationController
  def index
    @current_page = "Forecasting"
    @forecasts = Forecast.order(created_at: :desc)
    render Views::Forecasts::IndexView.new(forecasts: @forecasts)
  end

  def new
    @current_page = "Forecasting"
    current_period = BudgetPeriod.find_by(year: Date.current.year, month: Date.current.month)
    default_assumptions = {
      "monthly_income" => (current_period&.total_income || 5000).to_f,
      "monthly_expenses" => (current_period&.total_spent || 4000).to_f,
      "extra_debt_payment" => 0,
      "income_growth_rate" => 0.03,
      "expense_growth_rate" => 0.02
    }

    @forecast = Forecast.new(
      name: "Forecast #{Date.current.strftime('%b %Y')}",
      projection_months: 24,
      assumptions: default_assumptions
    )

    render Views::Forecasts::FormView.new(forecast: @forecast)
  end

  def create
    @current_page = "Forecasting"
    @forecast = Forecast.new(forecast_params)
    if @forecast.save
      @forecast.generate_projection!
      redirect_to @forecast, notice: "Forecast generated."
    else
      render Views::Forecasts::FormView.new(forecast: @forecast), status: :unprocessable_entity
    end
  end

  def show
    @current_page = "Forecasting"
    @forecast = Forecast.find(params[:id])
    render Views::Forecasts::ShowView.new(forecast: @forecast)
  end

  def destroy
    @current_page = "Forecasting"
    Forecast.find(params[:id]).destroy
    redirect_to forecasts_path, notice: "Forecast deleted."
  end

  private

  def forecast_params
    permitted = params.require(:forecast).permit(:name, :projection_months)
    if params[:forecast][:assumptions].present?
      permitted[:assumptions] = params[:forecast][:assumptions].to_unsafe_h
    end
    permitted
  end
end
