# frozen_string_literal: true

class Views::ActionPlan::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(cash_flow:, periods:, timeline_by_month:, categories:, accounts:, months:)
    @cash_flow = cash_flow
    @periods = periods
    @timeline_by_month = timeline_by_month
    @categories = categories
    @accounts = accounts
    @months = months
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Action Plan" }
          p(class: "text-muted-foreground") { "Your unified cash flow register — every planned money movement in chronological order." }
        end

        div(class: "flex items-center gap-2") do
          months_selector
          form_with(url: helpers.generate_action_plan_path, method: :post, class: "inline") do |f|
            f.submit "Regenerate", class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
          end
        end
      end

      # Monthly ledger sections
      @periods.each do |period|
        month_ledger_section(period)
      end
    end
  end

  private

  def months_selector
    nav(aria: { label: "Month range selector" }, class: "flex items-center gap-1 rounded-md border border-input p-1") do
      [3, 6, 12].each do |m|
        active = m == @months
        a(
          href: helpers.action_plan_path(months: m),
          class: "inline-flex items-center justify-center rounded-sm px-3 py-1 text-sm font-medium transition-colors #{active ? 'bg-primary text-primary-foreground shadow-sm' : 'hover:bg-accent'}",
          aria: { current: active ? "page" : nil }
        ) do
          plain "#{m}mo"
        end
      end
    end
  end

  def month_ledger_section(period)
    key = [period.year, period.month]
    events = @timeline_by_month[key] || []

    section(aria: { label: "#{period.display_name} actions" }, class: "space-y-0") do
      # Month header row
      div(class: "flex items-center justify-between bg-muted/50 rounded-t-lg px-4 py-3 border border-border") do
        h2(class: "text-base font-bold") { "#{period.display_name} Actions" }
        a(
          href: helpers.budget_path(year: period.year, month: period.month),
          class: "text-blue-600 dark:text-blue-400 hover:underline text-sm font-medium"
        ) { "Select Month" }
      end

      # Table
      div(class: "border border-t-0 border-border rounded-b-lg overflow-hidden") do
        table(class: "w-full", role: "table") do
          # Table header
          thead(class: "bg-muted/30") do
            tr do
              th(scope: "col", class: "text-left text-xs font-medium text-muted-foreground uppercase tracking-wider px-4 py-2 w-24") { "Date" }
              th(scope: "col", class: "text-left text-xs font-medium text-muted-foreground uppercase tracking-wider px-4 py-2") { "From" }
              th(scope: "col", class: "text-left text-xs font-medium text-muted-foreground uppercase tracking-wider px-4 py-2") { "To" }
              th(scope: "col", class: "text-right text-xs font-medium text-muted-foreground uppercase tracking-wider px-4 py-2 w-36") { "Amount" }
              th(scope: "col", class: "text-right text-xs font-medium text-muted-foreground uppercase tracking-wider px-4 py-2 w-36") { "Balance" }
            end
          end

          tbody do
            if events.any?
              events.each do |event|
                ledger_row(event)
              end
            else
              tr do
                td(colspan: "5", class: "text-center text-sm text-muted-foreground py-8 px-4") do
                  plain "No planned actions for this month."
                end
              end
            end
          end
        end

        # Add Entry button
        div(class: "border-t border-border px-4 py-3 bg-muted/10") do
          add_entry_button(period)
        end
      end
    end
  end

  def ledger_row(event)
    row_bg = event[:is_negative] ? "bg-red-50 dark:bg-red-950" : "hover:bg-accent/30"
    event_type = event[:event_type]

    tr(class: "border-t border-border transition-colors #{row_bg}") do
      # Date
      td(class: "px-4 py-2.5 text-sm text-muted-foreground whitespace-nowrap") do
        plain event[:date].strftime("%b %d")
      end

      # From
      td(class: "px-4 py-2.5") do
        from_to_pill(event[:from_label])
      end

      # To (with transfer icon if applicable)
      td(class: "px-4 py-2.5") do
        if event_type == :transfer
          div(class: "flex items-center gap-1.5") do
            span(class: "text-blue-500 text-xs font-bold", aria: { label: "Transfer" }) { "~" }
            from_to_pill(event[:to_label])
          end
        else
          from_to_pill(event[:to_label])
        end
      end

      # Amount (color-coded by type)
      td(class: "px-4 py-2.5 text-right whitespace-nowrap") do
        amount_display(event)
      end

      # Running balance
      td(class: "px-4 py-2.5 text-right whitespace-nowrap") do
        if event[:is_negative]
          span(class: "text-sm font-semibold text-destructive") do
            plain format_currency(event[:running_balance])
          end
          div(class: "text-xs text-destructive font-medium") do
            plain "Short: #{format_currency(event[:running_balance])}"
          end
        else
          span(class: "text-sm text-muted-foreground") do
            plain format_currency(event[:running_balance])
          end
        end
      end
    end
  end

  def from_to_pill(label)
    span(class: "inline-flex items-center rounded-md border border-border bg-background px-2 py-0.5 text-sm font-medium") do
      plain label
    end
  end

  def amount_display(event)
    event_type = event[:event_type]
    amount = event[:amount].abs

    case event_type
    when :income
      span(class: "text-sm font-semibold text-green-600 dark:text-green-400") do
        plain "+#{format_currency(amount)}"
      end
    when :transfer
      span(class: "text-sm font-semibold text-blue-600 dark:text-blue-400") do
        plain "-#{format_currency(amount)}"
      end
    when :debt_payoff
      span(class: "text-sm font-semibold text-orange-600 dark:text-orange-400") do
        plain "-#{format_currency(amount)}"
      end
    else # :expense
      span(class: "text-sm font-semibold text-foreground") do
        plain "-#{format_currency(amount)}"
      end
    end
  end

  def add_entry_button(period)
    details(class: "group") do
      summary(class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-3 py-1.5 text-sm font-medium shadow-sm hover:bg-accent cursor-pointer list-none") do
        plain "+ Add Entry"
      end

      div(class: "mt-3 space-y-4") do
        # Expense/Income/Transfer add form
        add_entry_form(period)
      end
    end
  end

  def add_entry_form(period)
    # Add budget item form (covers expense, transfer, debt payoff)
    div(class: "space-y-3") do
      h4(class: "text-sm font-medium text-muted-foreground") { "Add Expense / Transfer / Debt Payment" }
      form_with(model: BudgetItem.new, url: helpers.action_plan_items_path, class: "flex flex-wrap gap-2 items-end") do |f|
        f.hidden_field :budget_period_id, value: period.id

        div(class: "w-36") do
          label(for: "budget_item_budget_category_id", class: "text-xs font-medium text-muted-foreground") { "Category" }
          f.select :budget_category_id,
            @categories.map { |c| [c.name, c.id] },
            { prompt: "Category" },
            class: input_class, "aria-label": "Category"
        end

        div(class: "w-36") do
          label(for: "budget_item_account_id", class: "text-xs font-medium text-muted-foreground") { "From Account" }
          f.select :account_id,
            @accounts.map { |a| [a.name, a.id] },
            { prompt: "Account" },
            class: input_class, "aria-label": "From account"
        end

        div(class: "flex-1 min-w-[100px]") do
          label(for: "budget_item_name", class: "text-xs font-medium text-muted-foreground") { "Payee/Name" }
          f.text_field :name, placeholder: "e.g. Groceries", class: input_class, "aria-label": "Item name"
        end

        div(class: "w-28") do
          label(for: "budget_item_planned_amount", class: "text-xs font-medium text-muted-foreground") { "Amount" }
          f.number_field :planned_amount, step: 0.01, placeholder: "0.00", class: input_class, "aria-label": "Amount"
        end

        div(class: "w-36") do
          label(for: "budget_item_expected_date", class: "text-xs font-medium text-muted-foreground") { "Date" }
          f.date_field :expected_date, class: input_class, "aria-label": "Expected date"
        end

        f.submit "+ Add", class: "inline-flex items-center justify-center rounded-md bg-primary px-3 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
      end
    end

    # Add income form
    div(class: "space-y-3 pt-3 border-t border-border") do
      h4(class: "text-sm font-medium text-muted-foreground") { "Add Income" }
      form_with(model: Income.new, url: helpers.action_plan_incomes_path, class: "flex flex-wrap gap-2 items-end") do |f|
        f.hidden_field :budget_period_id, value: period.id

        div(class: "flex-1 min-w-[120px]") do
          label(for: "income_source_name", class: "text-xs font-medium text-muted-foreground") { "Source" }
          f.text_field :source_name, placeholder: "e.g. Employer Inc", class: input_class, "aria-label": "Income source"
        end

        div(class: "w-28") do
          label(for: "income_expected_amount", class: "text-xs font-medium text-muted-foreground") { "Amount" }
          f.number_field :expected_amount, step: 0.01, placeholder: "0.00", class: input_class, "aria-label": "Income amount"
        end

        div(class: "w-36") do
          label(for: "income_pay_date", class: "text-xs font-medium text-muted-foreground") { "Pay Date" }
          f.date_field :pay_date, class: input_class, "aria-label": "Pay date"
        end

        f.submit "+ Add Income", class: "inline-flex items-center justify-center rounded-md bg-primary px-3 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
      end
    end
  end

  def input_class
    "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
