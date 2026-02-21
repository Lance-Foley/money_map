# frozen_string_literal: true

class Views::Forecasts::IndexView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(forecasts:)
    @forecasts = forecasts
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Forecasting" }
          p(class: "text-muted-foreground") { "Project your financial future with different scenarios." }
        end
        a(href: helpers.new_forecast_path, class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90") do
          plain "+ New Forecast"
        end
      end

      if @forecasts.any?
        div(class: "grid gap-4 md:grid-cols-2 lg:grid-cols-3") do
          @forecasts.each do |forecast|
            forecast_card(forecast)
          end
        end
      else
        Card do
          CardContent(class: "pt-6") do
            div(class: "flex h-[100px] items-center justify-center text-muted-foreground") do
              plain "No forecasts yet. Create one to project your financial future."
            end
          end
        end
      end
    end
  end

  private

  def forecast_card(forecast)
    assumptions = forecast.parsed_assumptions
    results = forecast.parsed_results
    has_results = results.present? && results.any?

    Card do
      CardHeader(class: "pb-2") do
        div(class: "flex items-center justify-between") do
          CardTitle(class: "text-base") { forecast.name }
          if has_results
            Badge(variant: :default) { "Complete" }
          else
            Badge(variant: :secondary) { "Pending" }
          end
        end
        CardDescription { "#{forecast.projection_months} month projection" }
      end
      CardContent do
        div(class: "space-y-2 text-sm") do
          if assumptions.any?
            detail_row("Monthly Income", format_currency(assumptions["monthly_income"]))
            detail_row("Monthly Expenses", format_currency(assumptions["monthly_expenses"]))
            if assumptions["extra_debt_payment"].to_f > 0
              detail_row("Extra Debt Payment", format_currency(assumptions["extra_debt_payment"]))
            end
          end

          if has_results
            last_month = results.last
            div(class: "pt-2 mt-2 border-t") do
              detail_row("Ending Net Worth", format_currency(last_month["net_worth"]))
              detail_row("Final Savings", format_currency(last_month["savings"]))
              if forecast.debt_free_month
                detail_row("Debt-Free Month", "Month #{forecast.debt_free_month}")
              end
            end
          end
        end
      end
      CardFooter(class: "pt-2 flex gap-2") do
        a(href: helpers.forecast_path(forecast), class: "text-sm text-primary hover:underline") { "View Details" }
        a(href: helpers.forecast_path(forecast), data: { turbo_method: :delete, turbo_confirm: "Delete this forecast?" }, class: "text-sm text-destructive hover:underline") { "Delete" }
      end
    end
  end

  def detail_row(label, value)
    div(class: "flex justify-between") do
      span(class: "text-muted-foreground") { label }
      span(class: "font-medium") { value }
    end
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
