# frozen_string_literal: true

class Views::ActionPlan::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(cash_flow:, periods:, categories:, months:)
    @cash_flow = cash_flow
    @periods = periods
    @categories = categories
    @months = months
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Action Plan" }
          p(class: "text-muted-foreground") { "Your multi-month cash flow projection and spending plan." }
        end

        div(class: "flex items-center gap-2") do
          months_selector
          form_with(url: helpers.generate_action_plan_path, method: :post, class: "inline") do |f|
            f.submit "Regenerate", class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
          end
        end
      end

      # Summary cards
      div(class: "grid gap-4 md:grid-cols-4") do
        summary_card("Starting Balance", format_currency(@cash_flow[:starting_balance]))
        if @cash_flow[:monthly_summary].any?
          last_month = @cash_flow[:monthly_summary].last
          summary_card("Ending Balance", format_currency(last_month[:ending_balance]))
          total_income = @cash_flow[:monthly_summary].sum { |m| m[:total_income] }
          total_expenses = @cash_flow[:monthly_summary].sum { |m| m[:total_expenses] }
          summary_card("Total Income", format_currency(total_income))
          summary_card("Total Expenses", format_currency(total_expenses))
        end
      end

      # Cash flow chart
      if @cash_flow[:chart_data] && @cash_flow[:chart_data][:labels]&.any?
        Card do
          CardHeader do
            CardTitle { "Cash Flow" }
            CardDescription { "Running balance over the next #{@months} months." }
          end
          CardContent do
            chart_data = @cash_flow[:chart_data]
            div(
              data: {
                controller: "chart",
                chart_config_value: {
                  type: "line",
                  data: {
                    labels: chart_data[:labels],
                    datasets: [{
                      label: "Running Balance",
                      data: chart_data[:data],
                      borderColor: "hsl(var(--primary))",
                      backgroundColor: "hsl(var(--primary) / 0.1)",
                      fill: true,
                      tension: 0.3,
                      pointRadius: 2
                    }]
                  },
                  options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: { display: false }
                    },
                    scales: {
                      y: {
                        ticks: {
                          callback: "formatCurrency"
                        }
                      }
                    }
                  }
                }.to_json
              },
              class: "h-[300px]"
            ) do
              canvas(id: "cash-flow-chart")
            end
          end
        end
      end

      # Negative balance warnings
      if @cash_flow[:negative_dates].any?
        div(class: "rounded-lg border border-destructive/50 bg-destructive/5 px-4 py-3") do
          div(class: "flex items-center gap-2") do
            span(class: "text-destructive font-medium text-sm") { "Warning: Negative balance projected" }
          end
          p(class: "text-sm text-destructive/80 mt-1") do
            dates = @cash_flow[:negative_dates].first(5).map { |d| d.strftime("%b %d") }.join(", ")
            plain "Your balance may go negative on: #{dates}"
            if @cash_flow[:negative_dates].size > 5
              plain " and #{@cash_flow[:negative_dates].size - 5} more dates."
            end
          end
        end
      end

      # Month sections
      @periods.each do |period|
        month_section(period)
      end
    end
  end

  private

  def months_selector
    div(class: "flex items-center gap-1 rounded-md border border-input p-1") do
      [3, 6, 12].each do |m|
        active = m == @months
        a(
          href: helpers.action_plan_path(months: m),
          class: "inline-flex items-center justify-center rounded-sm px-3 py-1 text-sm font-medium transition-colors #{active ? 'bg-primary text-primary-foreground shadow-sm' : 'hover:bg-accent'}"
        ) do
          plain "#{m}mo"
        end
      end
    end
  end

  def month_section(period)
    incomes = period.incomes.sort_by { |i| i.pay_date || Date.new(period.year, period.month, 1) }
    items = period.budget_items.sort_by { |i| i.expected_date || Date.new(period.year, period.month, 1) }

    total_income = incomes.sum(&:expected_amount)
    total_expenses = items.sum(&:planned_amount)
    surplus = total_income - total_expenses

    Card do
      CardHeader do
        div(class: "flex items-center justify-between") do
          div do
            CardTitle { period.display_name }
            CardDescription do
              plain "Income: #{format_currency(total_income)} | Expenses: #{format_currency(total_expenses)} | "
              span(class: surplus >= 0 ? "text-green-600 dark:text-green-400" : "text-destructive") do
                plain "#{surplus >= 0 ? 'Surplus' : 'Deficit'}: #{format_currency(surplus.abs)}"
              end
            end
          end
          div(class: "flex items-center gap-2") do
            Badge(variant: period.status == "active" ? :default : :secondary) { period.status.titleize }
          end
        end
      end
      CardContent do
        # Income subsection
        div(class: "mb-6") do
          h4(class: "text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3") { "Income" }
          if incomes.any?
            div(class: "space-y-2") do
              incomes.each do |income|
                income_row(income)
              end
            end
          else
            p(class: "text-sm text-muted-foreground") { "No income entries." }
          end

          # Add income form
          div(class: "mt-3 pt-3 border-t") do
            add_income_form(period)
          end
        end

        # Expense subsection
        div do
          h4(class: "text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3") { "Expenses" }
          if items.any?
            div(class: "space-y-2") do
              items.each do |item|
                expense_row(item)
              end
            end
          else
            p(class: "text-sm text-muted-foreground") { "No budget items." }
          end

          # Add item form
          div(class: "mt-3 pt-3 border-t") do
            add_item_form(period)
          end
        end
      end
    end
  end

  def income_row(income)
    div(class: "flex items-center justify-between rounded-md px-3 py-2 hover:bg-accent/50 transition-colors") do
      div(class: "flex items-center gap-3") do
        span(class: "text-xs text-muted-foreground w-16") { income.pay_date&.strftime("%b %d") || "-" }
        span(class: "text-sm font-medium") { income.source_name }
        if income.recurring?
          Badge(variant: :secondary) { "Recurring" }
        else
          Badge(variant: :outline) { "One-off" }
        end
      end
      span(class: "text-sm font-semibold text-green-600 dark:text-green-400") do
        plain "+#{format_currency(income.expected_amount)}"
      end
    end
  end

  def expense_row(item)
    div(class: "flex items-center justify-between rounded-md px-3 py-2 hover:bg-accent/50 transition-colors") do
      div(class: "flex items-center gap-3") do
        span(class: "text-xs text-muted-foreground w-16") { item.expected_date&.strftime("%b %d") || "-" }
        span(class: "text-sm font-medium") { item.name }
        if item.budget_category
          Badge(variant: :outline) { item.budget_category.name }
        end
        if item.from_recurring?
          Badge(variant: :secondary) { "Recurring" }
        else
          Badge(variant: :outline) { "One-off" }
        end
      end
      span(class: "text-sm font-semibold") do
        plain "-#{format_currency(item.planned_amount)}"
      end
    end
  end

  def add_item_form(period)
    form_with(model: BudgetItem.new, url: helpers.action_plan_items_path, class: "flex flex-wrap gap-2 items-end") do |f|
      f.hidden_field :budget_period_id, value: period.id
      div(class: "w-36") do
        f.select :budget_category_id,
          @categories.map { |c| [c.name, c.id] },
          { prompt: "Category" },
          class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
      end
      div(class: "flex-1 min-w-[100px]") do
        f.text_field :name, placeholder: "Item name", class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
      end
      div(class: "w-28") do
        f.number_field :planned_amount, step: 0.01, placeholder: "Amount", class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
      end
      div(class: "w-36") do
        f.date_field :expected_date, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
      end
      f.submit "+ Add Item", class: "inline-flex items-center justify-center rounded-md bg-primary px-3 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
    end
  end

  def add_income_form(period)
    form_with(model: Income.new, url: helpers.action_plan_incomes_path, class: "flex flex-wrap gap-2 items-end") do |f|
      f.hidden_field :budget_period_id, value: period.id
      div(class: "flex-1 min-w-[120px]") do
        f.text_field :source_name, placeholder: "Source name", class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
      end
      div(class: "w-28") do
        f.number_field :expected_amount, step: 0.01, placeholder: "Amount", class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
      end
      div(class: "w-36") do
        f.date_field :pay_date, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
      end
      f.submit "+ Add Income", class: "inline-flex items-center justify-center rounded-md bg-primary px-3 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
    end
  end

  def summary_card(title, value)
    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium") { title }
      end
      CardContent do
        div(class: "text-2xl font-bold") { value }
      end
    end
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
