# frozen_string_literal: true

class Views::ActionPlan::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(cash_flow:, periods:, timeline_by_month:, categories:, accounts:, months:,
                 active_accounts:, current_period:, next_milestone:)
    @cash_flow = cash_flow
    @periods = periods
    @timeline_by_month = timeline_by_month
    @categories = categories
    @accounts = accounts
    @months = months
    @active_accounts = active_accounts
    @current_period = current_period
    @next_milestone = next_milestone
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

      # Two-column layout: sidebar + main content
      div(class: "flex flex-col lg:flex-row gap-6") do
        # Left sidebar
        sidebar

        # Main content: ledger tables
        div(class: "flex-1 min-w-0 space-y-6") do
          @periods.each do |period|
            month_ledger_section(period)
          end
        end
      end
    end
  end

  private

  # ── Sidebar ──────────────────────────────────────────────────────────────

  def sidebar
    aside(class: "w-full lg:w-64 lg:shrink-0 space-y-4", aria: { label: "Action plan sidebar" }) do
      sidebar_add_action_button
      sidebar_search_field
      sidebar_accounts_overview
      sidebar_budget_overview
      sidebar_projected_cashflow
      sidebar_upcoming_milestone if @next_milestone
    end
  end

  def sidebar_add_action_button
    a(
      href: "#add-entry",
      class: "flex w-full items-center justify-center gap-2 rounded-md bg-primary px-4 py-2.5 text-sm font-semibold text-primary-foreground shadow hover:bg-primary/90 transition-colors",
      aria: { label: "Add new action" }
    ) do
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 20 20",
        fill: "currentColor",
        class: "h-4 w-4",
        aria: { hidden: "true" }
      ) do |s|
        s.path(
          fill_rule: "evenodd",
          d: "M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z",
          clip_rule: "evenodd"
        )
      end
      plain "Add New Action"
    end
  end

  def sidebar_search_field
    form_with(url: helpers.action_plan_path, method: :get, class: "relative") do |f|
      # Preserve current months param
      f.hidden_field :months, value: @months
      div(class: "relative") do
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          viewBox: "0 0 20 20",
          fill: "currentColor",
          class: "pointer-events-none absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground",
          aria: { hidden: "true" }
        ) do |s|
          s.path(
            fill_rule: "evenodd",
            d: "M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z",
            clip_rule: "evenodd"
          )
        end
        f.search_field :q,
          placeholder: "Search Name, Category or Amount",
          class: "flex h-9 w-full rounded-md border border-input bg-transparent pl-8 pr-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring",
          aria: { label: "Search actions" }
      end
    end
  end

  def sidebar_accounts_overview
    sidebar_collapsible_section(title: "Accounts Overview", id: "accounts-overview", open: true) do
      if @active_accounts.any?
        ul(class: "space-y-2") do
          @active_accounts.each do |account|
            li(class: "flex items-center justify-between text-sm") do
              div(class: "flex items-center gap-2 min-w-0") do
                span(class: "inline-block h-2 w-2 rounded-full shrink-0 #{account_dot_color(account)}")
                span(class: "truncate text-foreground") { account.name }
              end
              span(class: "font-medium tabular-nums #{account.debt? ? 'text-destructive' : 'text-foreground'}") do
                plain format_currency(account.balance)
              end
            end
          end
        end

        # Totals
        div(class: "mt-3 border-t border-border pt-3 space-y-1") do
          total_assets = @active_accounts.select(&:asset?).sum(&:balance)
          total_debts = @active_accounts.select(&:debt?).sum(&:balance)
          net = total_assets - total_debts

          div(class: "flex justify-between text-xs text-muted-foreground") do
            span { "Assets" }
            span(class: "font-medium text-green-600 dark:text-green-400") { format_currency(total_assets) }
          end
          div(class: "flex justify-between text-xs text-muted-foreground") do
            span { "Debts" }
            span(class: "font-medium text-destructive") { format_currency(total_debts) }
          end
          div(class: "flex justify-between text-sm font-semibold") do
            span { "Net" }
            span(class: net >= 0 ? "text-green-600 dark:text-green-400" : "text-destructive") do
              plain format_currency(net)
            end
          end
        end
      else
        p(class: "text-sm text-muted-foreground") { "No active accounts." }
      end
    end
  end

  def sidebar_budget_overview
    sidebar_collapsible_section(title: "Budget Overview", id: "budget-overview") do
      if @current_period
        dl(class: "space-y-2") do
          budget_overview_row("Monthly Income", @current_period.total_income, "text-green-600 dark:text-green-400")
          budget_overview_row("Monthly Expenses", @current_period.total_planned, "text-foreground")

          left = @current_period.left_to_budget
          color = if left > 0
            "text-green-600 dark:text-green-400"
          elsif left < 0
            "text-destructive"
          else
            "text-muted-foreground"
          end

          div(class: "border-t border-border pt-2") do
            budget_overview_row("Left to Budget", left, color)
          end
        end
      else
        p(class: "text-sm text-muted-foreground") { "No budget for the current month." }
      end
    end
  end

  def sidebar_projected_cashflow
    sidebar_collapsible_section(title: "Projected Cashflow", id: "projected-cashflow") do
      monthly_summary = @cash_flow[:monthly_summary]
      if monthly_summary.any?
        ul(class: "space-y-3") do
          monthly_summary.each do |summary|
            li(class: "space-y-1") do
              div(class: "flex justify-between items-baseline") do
                span(class: "text-xs font-medium text-foreground") { summary[:display_name] }
                surplus = summary[:surplus]
                span(class: "text-xs font-semibold tabular-nums #{surplus >= 0 ? 'text-green-600 dark:text-green-400' : 'text-destructive'}") do
                  plain "#{surplus >= 0 ? '+' : ''}#{format_currency(surplus)}"
                end
              end

              # Mini bar showing income vs expenses
              div(class: "flex h-1.5 w-full overflow-hidden rounded-full bg-muted") do
                income = summary[:total_income].to_f
                expenses = summary[:total_expenses].to_f
                max_val = [income, expenses, 1].max
                income_pct = (income / max_val * 100).clamp(0, 100)
                expense_pct = (expenses / max_val * 100).clamp(0, 100)

                div(
                  class: "h-full rounded-full bg-green-500",
                  style: "width: #{income_pct}%",
                  role: "img",
                  aria: { label: "Income: #{format_currency(income)}" }
                )
              end
              div(class: "flex justify-between text-xs text-muted-foreground") do
                span { "In: #{format_currency(summary[:total_income])}" }
                span { "Out: #{format_currency(summary[:total_expenses])}" }
              end
            end
          end
        end
      else
        p(class: "text-sm text-muted-foreground") { "No cashflow data available." }
      end
    end
  end

  def sidebar_upcoming_milestone
    goal = @next_milestone
    progress = goal.progress_percentage

    sidebar_collapsible_section(title: "Upcoming Milestone", id: "upcoming-milestone", open: true) do
      div(class: "space-y-3") do
        # Goal name
        span(class: "text-sm font-bold text-blue-600 dark:text-blue-400") { goal.name }

        # Progress bar
        div(class: "space-y-1") do
          div(class: "flex justify-between text-xs text-muted-foreground") do
            span { format_currency(goal.current_amount) }
            span { format_currency(goal.target_amount) }
          end
          div(class: "h-2 w-full overflow-hidden rounded-full bg-muted", role: "progressbar",
              aria: { valuenow: progress.to_s, valuemin: "0", valuemax: "100",
                      label: "#{goal.name} progress" }) do
            div(
              class: "h-full rounded-full bg-blue-600 transition-all",
              style: "width: #{progress}%"
            )
          end
          span(class: "text-xs font-medium text-foreground") { "#{progress}% complete" }
        end

        # Estimated months to goal
        remaining = goal.remaining
        if remaining > 0 && @current_period
          # Estimate monthly contribution from total_planned or a heuristic
          monthly_contrib = estimate_monthly_contribution(goal)
          if monthly_contrib && monthly_contrib > 0
            months_left = goal.months_to_goal(monthly_contrib)
            div(class: "rounded-md bg-muted/50 p-2 space-y-1") do
              div(class: "text-xs text-muted-foreground") do
                plain "Achievement Reached In: "
                span(class: "font-semibold text-foreground") { "#{months_left} months" }
              end
            end
          end
        end

        # Next step
        div(class: "rounded-md border border-border p-2 space-y-1") do
          span(class: "text-xs font-semibold text-foreground") { "Next Step" }
          p(class: "text-xs text-muted-foreground") do
            if goal.target_date && goal.target_date > Date.current
              months_rem = ((goal.target_date - Date.current) / 30).ceil
              monthly_needed = months_rem > 0 ? (remaining / months_rem).ceil : remaining
              plain "Contribute #{format_currency(monthly_needed)}/mo to reach #{format_currency(goal.target_amount)} by #{goal.target_date.strftime('%b %Y')}."
            else
              plain "#{format_currency(remaining)} remaining to reach your goal."
            end
          end
        end
      end
    end
  end

  # ── Sidebar helpers ──────────────────────────────────────────────────────

  def sidebar_collapsible_section(title:, id:, open: false, &block)
    details(class: "rounded-lg border border-border bg-card", open: open || nil, id: id) do
      summary(class: "flex cursor-pointer items-center justify-between px-3 py-2.5 text-sm font-semibold list-none select-none hover:bg-accent/50 rounded-lg transition-colors") do
        span { title }
        # Expand/collapse icon
        svg(
          xmlns: "http://www.w3.org/2000/svg",
          viewBox: "0 0 20 20",
          fill: "currentColor",
          class: "h-4 w-4 text-muted-foreground transition-transform",
          aria: { hidden: "true" }
        ) do |s|
          s.path(
            fill_rule: "evenodd",
            d: "M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z",
            clip_rule: "evenodd"
          )
        end
      end
      div(class: "px-3 pb-3", &block)
    end
  end

  def budget_overview_row(label, amount, color_class)
    div(class: "flex items-center justify-between") do
      dt(class: "text-xs text-muted-foreground") { label }
      dd(class: "text-sm font-semibold tabular-nums #{color_class}") { format_currency(amount) }
    end
  end

  def account_dot_color(account)
    case account.account_type
    when "checking" then "bg-blue-500"
    when "savings" then "bg-green-500"
    when "credit_card" then "bg-red-500"
    when "loan" then "bg-orange-500"
    when "mortgage" then "bg-amber-600"
    when "investment" then "bg-purple-500"
    else "bg-gray-400"
    end
  end

  def estimate_monthly_contribution(goal)
    # Use a simple heuristic: remaining / months until target, or $200/mo default
    if goal.target_date && goal.target_date > Date.current
      months_rem = ((goal.target_date - Date.current) / 30.0).ceil
      return goal.remaining / months_rem.to_f if months_rem > 0
    end
    200.0 # Default estimate
  end

  # ── Month range selector ─────────────────────────────────────────────────

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

  # ── Ledger table (unchanged) ─────────────────────────────────────────────

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
        div(class: "border-t border-border px-4 py-3 bg-muted/10", id: "add-entry") do
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
