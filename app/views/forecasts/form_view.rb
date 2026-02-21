# frozen_string_literal: true

class Views::Forecasts::FormView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(forecast:)
    @forecast = forecast
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div do
        h1(class: "text-2xl font-bold tracking-tight") { @forecast.new_record? ? "New Forecast" : "Edit Forecast" }
        p(class: "text-muted-foreground") { "Set your assumptions to project your financial future." }
      end

      Card do
        CardContent(class: "pt-6") do
          form_with(model: @forecast, class: "space-y-6") do |f|
            assumptions = @forecast.parsed_assumptions

            # Errors
            if @forecast.errors.any?
              div(class: "rounded-lg border border-destructive/20 bg-destructive/5 p-4") do
                p(class: "text-sm font-medium text-destructive") { "Please fix the following errors:" }
                ul(class: "mt-2 list-disc list-inside text-sm text-destructive") do
                  @forecast.errors.full_messages.each do |msg|
                    li { msg }
                  end
                end
              end
            end

            # Forecast name
            div(class: "space-y-2") do
              label(for: "forecast_name", class: "text-sm font-medium") { "Forecast Name" }
              f.text_field :name, class: input_class, placeholder: "e.g. Aggressive Payoff Plan"
            end

            # Projection months
            div(class: "space-y-2") do
              label(for: "forecast_projection_months", class: "text-sm font-medium") { "Projection Period (months)" }
              f.number_field :projection_months, class: input_class, min: 1, max: 60, step: 1
              p(class: "text-xs text-muted-foreground") { "How many months into the future to project (1-60)." }
            end

            # Assumptions section
            div(class: "space-y-4") do
              h3(class: "text-lg font-semibold border-b pb-2") { "Financial Assumptions" }

              div(class: "grid gap-4 md:grid-cols-2") do
                # Monthly income
                div(class: "space-y-2") do
                  label(for: "forecast_assumptions_monthly_income", class: "text-sm font-medium") { "Monthly Income" }
                  input(
                    type: "number", name: "forecast[assumptions][monthly_income]",
                    id: "forecast_assumptions_monthly_income",
                    value: assumptions["monthly_income"], class: input_class, step: 100, min: 0
                  )
                  p(class: "text-xs text-muted-foreground") { "Your expected monthly take-home pay." }
                end

                # Monthly expenses
                div(class: "space-y-2") do
                  label(for: "forecast_assumptions_monthly_expenses", class: "text-sm font-medium") { "Monthly Expenses" }
                  input(
                    type: "number", name: "forecast[assumptions][monthly_expenses]",
                    id: "forecast_assumptions_monthly_expenses",
                    value: assumptions["monthly_expenses"], class: input_class, step: 100, min: 0
                  )
                  p(class: "text-xs text-muted-foreground") { "Your expected monthly spending." }
                end

                # Extra debt payment
                div(class: "space-y-2") do
                  label(for: "forecast_assumptions_extra_debt_payment", class: "text-sm font-medium") { "Extra Debt Payment" }
                  input(
                    type: "number", name: "forecast[assumptions][extra_debt_payment]",
                    id: "forecast_assumptions_extra_debt_payment",
                    value: assumptions["extra_debt_payment"] || 0, class: input_class, step: 50, min: 0
                  )
                  p(class: "text-xs text-muted-foreground") { "Additional monthly payment toward debt beyond minimums." }
                end

                # Income growth rate
                div(class: "space-y-2") do
                  label(for: "forecast_assumptions_income_growth_rate", class: "text-sm font-medium") { "Annual Income Growth Rate" }
                  input(
                    type: "number", name: "forecast[assumptions][income_growth_rate]",
                    id: "forecast_assumptions_income_growth_rate",
                    value: assumptions["income_growth_rate"] || 0.03, class: input_class, step: 0.01, min: 0, max: 1
                  )
                  p(class: "text-xs text-muted-foreground") { "Expected annual income growth (e.g. 0.03 = 3%)." }
                end

                # Expense growth rate
                div(class: "space-y-2") do
                  label(for: "forecast_assumptions_expense_growth_rate", class: "text-sm font-medium") { "Annual Expense Growth Rate" }
                  input(
                    type: "number", name: "forecast[assumptions][expense_growth_rate]",
                    id: "forecast_assumptions_expense_growth_rate",
                    value: assumptions["expense_growth_rate"] || 0.02, class: input_class, step: 0.01, min: 0, max: 1
                  )
                  p(class: "text-xs text-muted-foreground") { "Expected annual expense inflation (e.g. 0.02 = 2%)." }
                end
              end
            end

            # Submit
            div(class: "flex gap-3") do
              f.submit "Generate Forecast", class: "inline-flex items-center justify-center rounded-md bg-primary px-6 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer"
              a(href: helpers.forecasts_path, class: "inline-flex items-center justify-center rounded-md border px-6 py-2 text-sm font-medium hover:bg-muted") { "Cancel" }
            end
          end
        end
      end
    end
  end

  private

  def input_class
    "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
  end
end
