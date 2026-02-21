# frozen_string_literal: true

class Views::Reports::IndexView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(income_vs_expenses:, spending_by_category:, net_worth_history:, debt_progress:, budget_accuracy:, period_range:)
    @income_vs_expenses = income_vs_expenses
    @spending_by_category = spending_by_category
    @net_worth_history = net_worth_history
    @debt_progress = debt_progress
    @budget_accuracy = budget_accuracy
    @period_range = period_range
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Reports" }
          p(class: "text-muted-foreground") { "Analyze your financial data across multiple dimensions." }
        end
        period_selector
      end

      # Tabs
      Tabs(default_value: "income_expenses") do
        TabsList do
          TabsTrigger(value: "income_expenses") { "Income vs Expenses" }
          TabsTrigger(value: "spending") { "Spending by Category" }
          TabsTrigger(value: "net_worth") { "Net Worth" }
          TabsTrigger(value: "debt") { "Debt Progress" }
          TabsTrigger(value: "budget") { "Budget Accuracy" }
        end

        TabsContent(value: "income_expenses") { income_vs_expenses_tab }
        TabsContent(value: "spending") { spending_by_category_tab }
        TabsContent(value: "net_worth") { net_worth_tab }
        TabsContent(value: "debt") { debt_progress_tab }
        TabsContent(value: "budget") { budget_accuracy_tab }
      end
    end
  end

  private

  def period_selector
    div(class: "flex items-center gap-2") do
      span(class: "text-sm text-muted-foreground") { "Period:" }
      [3, 6, 12, 24].each do |months|
        a(
          href: helpers.reports_path(months: months),
          class: "inline-flex items-center justify-center rounded-md px-3 py-1.5 text-sm font-medium #{months == @period_range ? 'bg-primary text-primary-foreground' : 'bg-muted text-muted-foreground hover:bg-muted/80'}"
        ) { "#{months}mo" }
      end
    end
  end

  # Tab 1: Income vs Expenses
  def income_vs_expenses_tab
    Card do
      CardHeader do
        CardTitle { "Income vs Expenses" }
        CardDescription { "Monthly income and spending comparison for the last #{@period_range} months." }
      end
      CardContent do
        if @income_vs_expenses.empty?
          empty_state("No budget periods found. Create budget periods to see income vs expense data.")
        else
          # Chart.js canvas
          chart_data = {
            labels: @income_vs_expenses.map { |d| d[:label] },
            datasets: [
              { label: "Income", data: @income_vs_expenses.map { |d| d[:income] }, backgroundColor: "rgba(16, 185, 129, 0.7)", borderColor: "rgb(16, 185, 129)", borderWidth: 1 },
              { label: "Expenses", data: @income_vs_expenses.map { |d| d[:expenses] }, backgroundColor: "rgba(239, 68, 68, 0.7)", borderColor: "rgb(239, 68, 68)", borderWidth: 1 }
            ]
          }
          div(class: "relative", style: "height: 300px") do
            canvas(
              data: {
                controller: "chart",
                chart_type_value: "bar",
                chart_data_value: chart_data.to_json,
                chart_options_value: { scales: { y: { beginAtZero: true } } }.to_json
              }
            )
          end

          # Data table below chart
          div(class: "mt-6") do
            Table do
              TableHeader do
                TableRow do
                  TableHead { "Period" }
                  TableHead(class: "text-right") { "Income" }
                  TableHead(class: "text-right") { "Expenses" }
                  TableHead(class: "text-right") { "Net" }
                end
              end
              TableBody do
                @income_vs_expenses.each do |data|
                  net = data[:income] - data[:expenses]
                  TableRow do
                    TableCell(class: "font-medium") { data[:label] }
                    TableCell(class: "text-right text-green-600") { format_currency(data[:income]) }
                    TableCell(class: "text-right text-red-600") { format_currency(data[:expenses]) }
                    TableCell(class: "text-right #{net >= 0 ? 'text-green-600' : 'text-red-600'}") { format_currency(net) }
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  # Tab 2: Spending by Category
  def spending_by_category_tab
    Card do
      CardHeader do
        CardTitle { "Spending by Category" }
        CardDescription { "Current month spending breakdown." }
      end
      CardContent do
        if @spending_by_category.empty?
          empty_state("No spending data for the current month.")
        else
          total = @spending_by_category.sum { |d| d[:amount] }

          # Chart.js canvas - doughnut chart
          chart_data = {
            labels: @spending_by_category.map { |d| d[:category] },
            datasets: [{
              data: @spending_by_category.map { |d| d[:amount] },
              backgroundColor: @spending_by_category.map { |d| d[:color] || "#6366f1" },
              borderWidth: 2
            }]
          }
          div(class: "relative mx-auto", style: "height: 300px; max-width: 400px") do
            canvas(
              data: {
                controller: "chart",
                chart_type_value: "doughnut",
                chart_data_value: chart_data.to_json,
                chart_options_value: { plugins: { legend: { position: "bottom" } } }.to_json
              }
            )
          end

          # Category breakdown
          div(class: "mt-6 space-y-3") do
            @spending_by_category.each do |data|
              pct = total > 0 ? (data[:amount] / total * 100).round(1) : 0
              div(class: "space-y-1") do
                div(class: "flex items-center justify-between text-sm") do
                  div(class: "flex items-center gap-2") do
                    div(class: "h-3 w-3 rounded-full", style: "background-color: #{data[:color] || '#6366f1'}")
                    span(class: "font-medium") { data[:category] }
                  end
                  div(class: "flex items-center gap-3") do
                    span(class: "text-muted-foreground") { "#{pct}%" }
                    span(class: "font-medium") { format_currency(data[:amount]) }
                  end
                end
                div(class: "h-2 rounded-full bg-muted overflow-hidden") do
                  div(class: "h-full rounded-full", style: "width: #{pct}%; background-color: #{data[:color] || '#6366f1'}")
                end
              end
            end
          end
        end
      end
    end
  end

  # Tab 3: Net Worth Over Time
  def net_worth_tab
    Card do
      CardHeader do
        CardTitle { "Net Worth Over Time" }
        CardDescription { "Track your net worth trajectory." }
      end
      CardContent do
        if @net_worth_history.empty?
          empty_state("No net worth snapshots found. Snapshots are captured periodically.")
        else
          # Chart.js canvas - line chart
          chart_data = {
            labels: @net_worth_history.map { |d| d[:date] },
            datasets: [
              { label: "Net Worth", data: @net_worth_history.map { |d| d[:net_worth] }, borderColor: "rgb(99, 102, 241)", backgroundColor: "rgba(99, 102, 241, 0.1)", fill: true, tension: 0.3 },
              { label: "Assets", data: @net_worth_history.map { |d| d[:assets] }, borderColor: "rgb(16, 185, 129)", backgroundColor: "transparent", borderDash: [5, 5], tension: 0.3 },
              { label: "Liabilities", data: @net_worth_history.map { |d| d[:liabilities] }, borderColor: "rgb(239, 68, 68)", backgroundColor: "transparent", borderDash: [5, 5], tension: 0.3 }
            ]
          }
          div(class: "relative", style: "height: 300px") do
            canvas(
              data: {
                controller: "chart",
                chart_type_value: "line",
                chart_data_value: chart_data.to_json,
                chart_options_value: { scales: { y: { beginAtZero: false } } }.to_json
              }
            )
          end

          # Data table
          div(class: "mt-6") do
            Table do
              TableHeader do
                TableRow do
                  TableHead { "Date" }
                  TableHead(class: "text-right") { "Assets" }
                  TableHead(class: "text-right") { "Liabilities" }
                  TableHead(class: "text-right") { "Net Worth" }
                end
              end
              TableBody do
                @net_worth_history.each do |data|
                  TableRow do
                    TableCell(class: "font-medium") { data[:date] }
                    TableCell(class: "text-right text-green-600") { format_currency(data[:assets]) }
                    TableCell(class: "text-right text-red-600") { format_currency(data[:liabilities]) }
                    TableCell(class: "text-right font-semibold #{data[:net_worth] >= 0 ? 'text-green-600' : 'text-red-600'}") { format_currency(data[:net_worth]) }
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  # Tab 4: Debt Progress
  def debt_progress_tab
    Card do
      CardHeader do
        CardTitle { "Debt Progress" }
        CardDescription { "Track your progress paying down debt." }
      end
      CardContent do
        if @debt_progress.empty?
          empty_state("No debt accounts found.")
        else
          total_original = @debt_progress.sum { |d| d[:original] }
          total_current = @debt_progress.sum { |d| d[:current] }
          total_paid = total_original - total_current
          overall_progress = total_original > 0 ? (total_paid / total_original * 100).round(1) : 0

          # Overall summary
          div(class: "mb-6 rounded-lg border bg-muted/30 p-4") do
            div(class: "flex items-center justify-between mb-2") do
              span(class: "text-sm font-medium") { "Overall Debt Progress" }
              span(class: "text-sm font-semibold") { "#{overall_progress}% paid off" }
            end
            div(class: "h-4 rounded-full bg-muted overflow-hidden") do
              div(class: "h-full rounded-full bg-primary transition-all", style: "width: #{[overall_progress, 100].min}%")
            end
            div(class: "flex justify-between mt-2 text-xs text-muted-foreground") do
              span { "#{format_currency(total_paid)} paid" }
              span { "#{format_currency(total_current)} remaining" }
            end
          end

          # Individual debts
          div(class: "space-y-4") do
            @debt_progress.each do |debt|
              div(class: "rounded-lg border p-4") do
                div(class: "flex items-center justify-between mb-2") do
                  span(class: "font-medium") { debt[:name] }
                  span(class: "text-sm text-muted-foreground") { "#{debt[:progress]}%" }
                end
                div(class: "h-3 rounded-full bg-muted overflow-hidden") do
                  color = if debt[:progress] >= 75
                            "bg-green-500"
                          elsif debt[:progress] >= 50
                            "bg-yellow-500"
                          elsif debt[:progress] >= 25
                            "bg-orange-500"
                          else
                            "bg-red-500"
                          end
                  div(class: "h-full rounded-full #{color}", style: "width: #{[debt[:progress], 100].min}%")
                end
                div(class: "flex justify-between mt-1 text-xs text-muted-foreground") do
                  span { "Current: #{format_currency(debt[:current])}" }
                  span { "Original: #{format_currency(debt[:original])}" }
                end
              end
            end
          end
        end
      end
    end
  end

  # Tab 5: Budget Accuracy
  def budget_accuracy_tab
    Card do
      CardHeader do
        CardTitle { "Budget Accuracy" }
        CardDescription { "How closely does your spending match your budget?" }
      end
      CardContent do
        if @budget_accuracy.empty?
          empty_state("No budget periods found.")
        else
          # Chart.js canvas - bar chart
          chart_data = {
            labels: @budget_accuracy.map { |d| d[:period] },
            datasets: [
              { label: "Planned", data: @budget_accuracy.map { |d| d[:planned] }, backgroundColor: "rgba(99, 102, 241, 0.7)", borderColor: "rgb(99, 102, 241)", borderWidth: 1 },
              { label: "Actual", data: @budget_accuracy.map { |d| d[:actual] }, backgroundColor: "rgba(249, 115, 22, 0.7)", borderColor: "rgb(249, 115, 22)", borderWidth: 1 }
            ]
          }
          div(class: "relative", style: "height: 300px") do
            canvas(
              data: {
                controller: "chart",
                chart_type_value: "bar",
                chart_data_value: chart_data.to_json,
                chart_options_value: { scales: { y: { beginAtZero: true } } }.to_json
              }
            )
          end

          # Accuracy table
          div(class: "mt-6") do
            Table do
              TableHeader do
                TableRow do
                  TableHead { "Period" }
                  TableHead(class: "text-right") { "Planned" }
                  TableHead(class: "text-right") { "Actual" }
                  TableHead(class: "text-right") { "Accuracy" }
                  TableHead(class: "text-right") { "Variance" }
                end
              end
              TableBody do
                @budget_accuracy.each do |data|
                  variance = data[:actual] - data[:planned]
                  TableRow do
                    TableCell(class: "font-medium") { data[:period] }
                    TableCell(class: "text-right") { format_currency(data[:planned]) }
                    TableCell(class: "text-right") { format_currency(data[:actual]) }
                    TableCell(class: "text-right") do
                      accuracy_badge(data[:accuracy])
                    end
                    TableCell(class: "text-right #{variance > 0 ? 'text-red-600' : 'text-green-600'}") { format_currency(variance) }
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def accuracy_badge(accuracy)
    color = if accuracy <= 100
              "bg-green-100 text-green-800"
            elsif accuracy <= 110
              "bg-yellow-100 text-yellow-800"
            else
              "bg-red-100 text-red-800"
            end
    span(class: "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{color}") { "#{accuracy}%" }
  end

  def empty_state(message)
    div(class: "flex h-[200px] items-center justify-center text-muted-foreground") do
      plain message
    end
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
