# frozen_string_literal: true

class Views::Forecasts::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(forecast:)
    @forecast = forecast
    @assumptions = forecast.parsed_assumptions
    @results = forecast.parsed_results
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { @forecast.name }
          p(class: "text-muted-foreground") { "#{@forecast.projection_months}-month financial projection" }
        end
        div(class: "flex gap-2") do
          a(href: helpers.forecasts_path, class: "inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted") { "Back to Forecasts" }
          a(href: helpers.forecast_path(@forecast), data: { turbo_method: :delete, turbo_confirm: "Delete this forecast?" }, class: "inline-flex items-center justify-center rounded-md bg-destructive px-4 py-2 text-sm font-medium text-destructive-foreground shadow hover:bg-destructive/90") { "Delete" }
        end
      end

      # Assumptions summary
      assumptions_card

      if @results.present? && @results.any?
        # Summary stats
        summary_stats_card

        # Chart
        projection_chart

        # Monthly projection table
        projection_table
      else
        Card do
          CardContent(class: "pt-6") do
            div(class: "flex h-[100px] items-center justify-center text-muted-foreground") do
              plain "No projection results yet. This forecast may need to be regenerated."
            end
          end
        end
      end
    end
  end

  private

  def assumptions_card
    Card do
      CardHeader(class: "pb-2") do
        CardTitle { "Assumptions" }
      end
      CardContent do
        div(class: "grid gap-3 sm:grid-cols-2 md:grid-cols-5") do
          assumption_stat("Monthly Income", format_currency(@assumptions["monthly_income"]))
          assumption_stat("Monthly Expenses", format_currency(@assumptions["monthly_expenses"]))
          assumption_stat("Extra Debt Payment", format_currency(@assumptions["extra_debt_payment"]))
          assumption_stat("Income Growth", format_pct(@assumptions["income_growth_rate"]))
          assumption_stat("Expense Growth", format_pct(@assumptions["expense_growth_rate"]))
        end
      end
    end
  end

  def summary_stats_card
    return unless @results.present? && @results.any?

    first_month = @results.first
    last_month = @results.last
    debt_free = @forecast.debt_free_month
    total_surplus = @results.sum { |r| (r["surplus"] || r[:surplus] || 0).to_f }

    Card do
      CardHeader(class: "pb-2") do
        CardTitle { "Projection Summary" }
      end
      CardContent do
        div(class: "grid gap-4 sm:grid-cols-2 md:grid-cols-4") do
          summary_stat(
            "Ending Net Worth",
            format_currency(last_month["net_worth"] || last_month[:net_worth]),
            "After #{@forecast.projection_months} months"
          )
          summary_stat(
            "Total Savings",
            format_currency(last_month["savings"] || last_month[:savings]),
            "Projected savings balance"
          )
          summary_stat(
            "Total Surplus",
            format_currency(total_surplus),
            "Cumulative income minus expenses"
          )
          if debt_free
            summary_stat(
              "Debt-Free",
              "Month #{debt_free}",
              "When all debt is paid off"
            )
          else
            summary_stat(
              "Remaining Debt",
              format_currency(last_month["total_debt"] || last_month[:total_debt]),
              "At end of projection"
            )
          end
        end
      end
    end
  end

  def projection_chart
    return unless @results.present? && @results.any?

    labels = @results.map { |r| r["date"] || r[:date] }
    net_worth_data = @results.map { |r| (r["net_worth"] || r[:net_worth]).to_f }
    debt_data = @results.map { |r| (r["total_debt"] || r[:total_debt]).to_f }
    savings_data = @results.map { |r| (r["savings"] || r[:savings]).to_f }

    chart_data = {
      labels: labels,
      datasets: [
        { label: "Net Worth", data: net_worth_data, borderColor: "rgb(99, 102, 241)", backgroundColor: "rgba(99, 102, 241, 0.1)", fill: true, tension: 0.3 },
        { label: "Savings", data: savings_data, borderColor: "rgb(16, 185, 129)", backgroundColor: "transparent", tension: 0.3 },
        { label: "Total Debt", data: debt_data, borderColor: "rgb(239, 68, 68)", backgroundColor: "transparent", tension: 0.3 }
      ]
    }

    Card do
      CardHeader(class: "pb-2") do
        CardTitle { "Projection Chart" }
        CardDescription { "Net worth, savings, and debt over time" }
      end
      CardContent do
        div(class: "relative", style: "height: 350px") do
          canvas(
            data: {
              controller: "chart",
              chart_type_value: "line",
              chart_data_value: chart_data.to_json,
              chart_options_value: {
                scales: { y: { beginAtZero: false } },
                interaction: { mode: "index", intersect: false }
              }.to_json
            }
          )
        end
      end
    end
  end

  def projection_table
    return unless @results.present? && @results.any?

    Card do
      CardHeader(class: "pb-2") do
        CardTitle { "Monthly Projections" }
        CardDescription { "Detailed month-by-month breakdown" }
      end
      CardContent do
        div(class: "overflow-x-auto") do
          Table do
            TableHeader do
              TableRow do
                TableHead { "Month" }
                TableHead { "Date" }
                TableHead(class: "text-right") { "Income" }
                TableHead(class: "text-right") { "Expenses" }
                TableHead(class: "text-right") { "Surplus" }
                TableHead(class: "text-right") { "Total Debt" }
                TableHead(class: "text-right") { "Savings" }
                TableHead(class: "text-right") { "Net Worth" }
              end
            end
            TableBody do
              @results.each do |row|
                month = row["month"] || row[:month]
                surplus = (row["surplus"] || row[:surplus]).to_f
                net_worth = (row["net_worth"] || row[:net_worth]).to_f

                TableRow do
                  TableCell(class: "font-medium") { month.to_s }
                  TableCell { (row["date"] || row[:date]).to_s }
                  TableCell(class: "text-right text-green-600") { format_currency(row["income"] || row[:income]) }
                  TableCell(class: "text-right text-red-600") { format_currency(row["expenses"] || row[:expenses]) }
                  TableCell(class: "text-right #{surplus >= 0 ? 'text-green-600' : 'text-red-600'}") { format_currency(surplus) }
                  TableCell(class: "text-right") { format_currency(row["total_debt"] || row[:total_debt]) }
                  TableCell(class: "text-right") { format_currency(row["savings"] || row[:savings]) }
                  TableCell(class: "text-right font-semibold #{net_worth >= 0 ? 'text-green-600' : 'text-red-600'}") { format_currency(net_worth) }
                end
              end
            end
          end
        end
      end
    end
  end

  def assumption_stat(label, value)
    div do
      p(class: "text-xs text-muted-foreground") { label }
      p(class: "text-sm font-semibold") { value }
    end
  end

  def summary_stat(label, value, description)
    div do
      p(class: "text-sm text-muted-foreground") { label }
      p(class: "text-2xl font-bold") { value }
      p(class: "text-xs text-muted-foreground") { description }
    end
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end

  def format_pct(rate)
    "#{'%.1f' % ((rate || 0).to_f * 100)}%"
  end
end
