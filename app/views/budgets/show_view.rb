# frozen_string_literal: true

class Views::Budgets::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(period:, categories:, items_by_category:, incomes:, new_transactions:, tracked_transactions:)
    @period = period
    @categories = categories
    @items_by_category = items_by_category
    @incomes = incomes
    @new_transactions = new_transactions
    @tracked_transactions = tracked_transactions
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-4 p-4") do
      # Page header
      page_header

      # Two-column layout
      div(class: "flex flex-col lg:flex-row gap-6") do
        # Left column (main budget content)
        main(class: "flex-1 lg:w-[65%] space-y-4", id: "budget-content") do
          income_section
          @categories.each do |category|
            items = @items_by_category[category.id] || []
            category_section(category, items)
          end
        end

        # Right column (transactions sidebar)
        aside(class: "w-full lg:w-[35%]", aria: { label: "Transactions panel" }) do
          transactions_panel
        end
      end
    end
  end

  private

  # ---------- PAGE HEADER ----------

  def page_header
    header(class: "space-y-3") do
      # Title row with month navigation
      div(class: "flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between") do
        div(class: "flex items-center gap-3") do
          a(
            href: helpers.budget_path(year: prev_year, month: prev_month),
            class: "inline-flex items-center justify-center rounded-md border border-input bg-background w-9 h-9 text-sm font-medium shadow-sm hover:bg-accent",
            aria: { label: "Previous month" }
          ) do
            plain "<"
          end
          h1(class: "text-2xl sm:text-3xl font-bold tracking-tight") { @period.display_name }
          a(
            href: helpers.budget_path(year: next_year, month: next_month),
            class: "inline-flex items-center justify-center rounded-md border border-input bg-background w-9 h-9 text-sm font-medium shadow-sm hover:bg-accent",
            aria: { label: "Next month" }
          ) do
            plain ">"
          end
        end

        div(class: "flex items-center gap-3") do
          left_to_budget_badge
          copy_previous_button
        end
      end
    end
  end

  def left_to_budget_badge
    left = @period.left_to_budget
    zero = left.zero?
    bg = zero ? "bg-green-100 dark:bg-green-900/30" : "bg-red-100 dark:bg-red-900/30"
    text_color = zero ? "text-green-700 dark:text-green-400" : "text-red-700 dark:text-red-400"
    border_color = zero ? "border-green-300 dark:border-green-700" : "border-red-300 dark:border-red-700"

    div(class: "inline-flex items-center gap-2 rounded-lg border #{border_color} #{bg} px-4 py-2") do
      span(class: "text-sm font-medium #{text_color}") { "Left to Budget:" }
      span(class: "text-lg font-bold #{text_color}") { format_currency(left) }
    end
  end

  def copy_previous_button
    form_with(url: helpers.copy_budget_path(year: @period.year, month: @period.month), method: :post, class: "inline") do |f|
      f.submit "Copy Previous Month", class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent cursor-pointer"
    end
  end

  # ---------- INCOME SECTION ----------

  def income_section
    section(aria: { label: "Income for #{@period.display_name}" }) do
      details(open: true, class: "group") do
        summary(class: "flex items-center gap-2 cursor-pointer list-none rounded-t-lg bg-green-50 dark:bg-green-950/30 border border-green-200 dark:border-green-800 px-4 py-3") do
          chevron_icon
          h2(class: "text-lg font-bold text-green-800 dark:text-green-300 flex-1") do
            plain "Income for #{@period.display_name}"
          end
          div(class: "flex gap-8 text-sm font-semibold text-green-700 dark:text-green-400 hidden sm:flex") do
            span { "Planned" }
            span { "Received" }
          end
        end

        div(class: "border border-t-0 border-green-200 dark:border-green-800 rounded-b-lg bg-background") do
          if @incomes.any?
            div(class: "divide-y divide-border") do
              @incomes.each do |income|
                income_row(income)
              end
            end

            # Income totals
            div(class: "flex items-center justify-between px-4 py-3 bg-green-50/50 dark:bg-green-950/20 border-t border-green-200 dark:border-green-800") do
              span(class: "text-sm font-bold text-green-800 dark:text-green-300") { "Total" }
              div(class: "flex items-center gap-4") do
                span(class: "text-sm font-bold text-green-700 dark:text-green-400 w-24 text-right") do
                  plain format_currency(@incomes.sum(&:expected_amount))
                end
                span(class: "text-sm font-bold text-green-700 dark:text-green-400 w-24 text-right") do
                  plain format_currency(@incomes.sum { |i| i.received_amount || 0 })
                end
              end
            end
          else
            div(class: "px-4 py-6 text-center") do
              p(class: "text-sm text-muted-foreground") { "No income entries yet. Add your first income source below." }
            end
          end

          # Add income form
          div(class: "px-4 py-3 border-t border-green-200 dark:border-green-800") do
            income_add_form
          end
        end
      end
    end
  end

  def income_row(income)
    pct = income.expected_amount.to_f > 0 ? ((income.received_amount || 0).to_f / income.expected_amount * 100).round(1) : 0
    div(class: "px-4 py-3") do
      div(class: "flex items-center justify-between") do
        div(class: "flex items-center gap-2 flex-1 min-w-0") do
          span(class: "text-sm font-medium truncate") { income.source_name }
          if income.recurring?
            span(class: "inline-flex items-center rounded-full bg-green-100 dark:bg-green-900/40 px-2 py-0.5 text-xs font-medium text-green-700 dark:text-green-400") do
              plain "Recurring"
            end
          end
        end
        div(class: "flex items-center gap-4 shrink-0") do
          span(class: "text-sm text-muted-foreground w-24 text-right") do
            plain format_currency(income.expected_amount)
          end
          span(class: "text-sm font-medium w-24 text-right #{income.received? ? 'text-green-600 dark:text-green-400' : 'text-muted-foreground'}") do
            plain income.received? ? format_currency(income.received_amount) : "-"
          end
        end
      end
      # Green progress bar
      div(class: "mt-1.5 h-1.5 rounded-full bg-green-100 dark:bg-green-900/40 overflow-hidden") do
        bar_width = [pct, 100].min
        div(class: "h-full rounded-full bg-green-500 dark:bg-green-400 transition-all", style: "width: #{bar_width}%")
      end
    end
  end

  def income_add_form
    details(class: "group") do
      summary(class: "text-sm font-medium text-green-700 dark:text-green-400 cursor-pointer hover:underline list-none inline-flex items-center gap-1") do
        plain "+ Add Income"
      end

      div(class: "mt-3") do
        form_with(model: Income.new, url: helpers.incomes_path, class: "space-y-3") do |f|
          f.hidden_field :budget_period_id, value: @period.id

          div(class: "flex flex-wrap gap-2 items-end") do
            div(class: "flex-1 min-w-[120px]") do
              label(for: "income_source_name", class: "text-xs font-medium text-muted-foreground") { "Source" }
              f.text_field :source_name, placeholder: "Income source", class: input_class, required: true
            end
            div(class: "w-28") do
              label(for: "income_expected_amount", class: "text-xs font-medium text-muted-foreground") { "Planned" }
              f.number_field :expected_amount, step: 0.01, placeholder: "0.00", class: input_class, required: true
            end
            div(class: "w-32") do
              label(for: "income_pay_date", class: "text-xs font-medium text-muted-foreground") { "Pay Date" }
              f.date_field :pay_date, class: input_class
            end
            f.submit "Add", class: "inline-flex items-center justify-center rounded-md bg-green-600 hover:bg-green-700 px-4 py-2 text-sm font-medium text-white shadow cursor-pointer h-9"
          end
        end
      end
    end
  end

  # ---------- EXPENSE CATEGORY SECTIONS ----------

  def category_section(category, items)
    category_total_planned = items.sum(&:planned_amount)
    category_total_remaining = items.sum(&:remaining)
    remaining_color = category_total_remaining.negative? ? "text-red-600 dark:text-red-400" : "text-muted-foreground"

    section(aria: { label: "#{category.name} budget category" }) do
      details(open: true, class: "group") do
        summary(class: "flex items-center gap-2 cursor-pointer list-none rounded-t-lg bg-muted/50 border border-border px-4 py-3") do
          chevron_icon
          div(class: "flex items-center gap-2 flex-1") do
            if category.color.present?
              div(class: "h-3 w-3 rounded-full shrink-0", style: "background-color: #{category.color}")
            end
            h2(class: "text-base font-bold") { category.name }
          end
          div(class: "flex items-center gap-4 text-sm font-semibold hidden sm:flex") do
            div(class: "w-24 text-right") do
              span(class: "text-muted-foreground") { "Planned" }
            end
            div(class: "w-24 text-right") do
              span(class: "text-muted-foreground") { "Remaining" }
            end
          end
        end

        div(class: "border border-t-0 border-border rounded-b-lg bg-background") do
          if items.any?
            div(class: "divide-y divide-border") do
              items.each do |item|
                budget_item_row(item)
              end
            end

            # Category total row
            div(class: "flex items-center justify-between px-4 py-3 bg-muted/30 border-t border-border") do
              span(class: "text-sm font-bold") { "#{category.name} Total" }
              div(class: "flex items-center gap-4") do
                span(class: "text-sm font-bold w-24 text-right") { format_currency(category_total_planned) }
                span(class: "text-sm font-bold w-24 text-right #{remaining_color}") { format_currency(category_total_remaining) }
              end
            end
          else
            div(class: "px-4 py-4 text-center") do
              p(class: "text-sm text-muted-foreground") { "No budget items in this category." }
            end
          end

          # Add item form
          div(class: "px-4 py-3 border-t border-border") do
            add_item_form(category)
          end
        end
      end
    end
  end

  def budget_item_row(item)
    pct = item.percentage_spent
    over = item.over_budget?
    remaining_color = over ? "text-red-600 dark:text-red-400 font-semibold" : "text-green-600 dark:text-green-400"

    div(class: "px-4 py-3") do
      div(class: "flex items-center justify-between") do
        div(class: "flex items-center gap-2 flex-1 min-w-0") do
          span(class: "text-sm font-medium truncate") { item.name }
          if item.rollover?
            span(class: "inline-flex items-center rounded-full bg-blue-100 dark:bg-blue-900/40 px-2 py-0.5 text-xs font-medium text-blue-700 dark:text-blue-400") do
              plain "Sinking Fund"
            end
          end
        end
        div(class: "flex items-center gap-4 shrink-0") do
          span(class: "text-sm text-muted-foreground w-24 text-right") do
            plain format_currency(item.planned_amount)
          end
          span(class: "text-sm w-24 text-right #{remaining_color}") do
            plain format_currency(item.remaining)
          end
        end
      end
      # Blue progress bar (turns red when over budget)
      div(class: "mt-1.5 h-1.5 rounded-full bg-muted overflow-hidden") do
        bar_pct = [pct, 100].min
        color = if pct > 100
          "bg-red-500 dark:bg-red-400"
        elsif pct > 80
          "bg-yellow-500 dark:bg-yellow-400"
        else
          "bg-blue-500 dark:bg-blue-400"
        end
        div(class: "h-full rounded-full #{color} transition-all", style: "width: #{bar_pct}%")
      end
    end
  end

  def add_item_form(category)
    details(class: "group") do
      summary(class: "text-sm font-medium text-blue-600 dark:text-blue-400 cursor-pointer hover:underline list-none inline-flex items-center gap-1") do
        plain "+ Add Item"
      end

      div(class: "mt-3") do
        form_with(model: BudgetItem.new, url: helpers.budget_items_path, class: "flex flex-wrap gap-2 items-end") do |f|
          f.hidden_field :budget_period_id, value: @period.id
          f.hidden_field :budget_category_id, value: category.id
          div(class: "flex-1 min-w-[120px]") do
            label(for: "budget_item_name", class: "text-xs font-medium text-muted-foreground") { "Item Name" }
            f.text_field :name, placeholder: "e.g. Groceries", class: input_class, required: true
          end
          div(class: "w-28") do
            label(for: "budget_item_planned_amount", class: "text-xs font-medium text-muted-foreground") { "Planned" }
            f.number_field :planned_amount, step: 0.01, placeholder: "0.00", class: input_class, required: true
          end
          f.submit "Add", class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
        end
      end
    end
  end

  # ---------- TRANSACTIONS PANEL (RIGHT SIDEBAR) ----------

  def transactions_panel
    div(class: "sticky top-4") do
      Card do
        CardContent(class: "p-0") do
          # Tabs - using a simple tab system with details/summary for no-JS
          div(class: "border-b border-border") do
            nav(class: "flex", aria: { label: "Budget panel tabs" }) do
              summary_tab_button
              transactions_tab_button
            end
          end

          # Summary content (default visible)
          div(id: "summary-panel") do
            summary_panel_content
          end
        end
      end
    end
  end

  def summary_tab_button
    a(
      href: "#summary-panel",
      class: "flex-1 text-center px-4 py-3 text-sm font-semibold border-b-2 border-primary text-primary",
      aria: { current: "page" }
    ) do
      plain "Summary"
    end
  end

  def transactions_tab_button
    a(
      href: "#transactions-panel",
      class: "flex-1 text-center px-4 py-3 text-sm font-medium text-muted-foreground hover:text-foreground border-b-2 border-transparent hover:border-muted-foreground/30"
    ) do
      new_count = @new_transactions.size
      plain "Transactions"
      if new_count > 0
        span(class: "ml-1.5 inline-flex items-center justify-center rounded-full bg-red-100 dark:bg-red-900/40 px-2 py-0.5 text-xs font-bold text-red-700 dark:text-red-400") do
          plain new_count.to_s
        end
      end
    end
  end

  def summary_panel_content
    left = @period.left_to_budget
    zero = left.zero?

    div(class: "p-4 space-y-4") do
      # Monthly income
      div(class: "flex items-center justify-between py-2") do
        span(class: "text-sm text-muted-foreground") { "Monthly Income" }
        span(class: "text-sm font-semibold text-green-600 dark:text-green-400") { format_currency(@period.total_income) }
      end

      # Monthly expenses (planned)
      div(class: "flex items-center justify-between py-2") do
        span(class: "text-sm text-muted-foreground") { "Monthly Planned" }
        span(class: "text-sm font-semibold") { format_currency(@period.total_planned) }
      end

      div(class: "border-t border-border")

      # Monthly spent
      div(class: "flex items-center justify-between py-2") do
        span(class: "text-sm text-muted-foreground") { "Spent So Far" }
        span(class: "text-sm font-semibold") { format_currency(@period.total_spent) }
      end

      div(class: "border-t border-border")

      # Left to budget (highlighted)
      ltb_bg = zero ? "bg-green-50 dark:bg-green-950/30" : "bg-red-50 dark:bg-red-950/30"
      ltb_text = zero ? "text-green-700 dark:text-green-400" : "text-red-700 dark:text-red-400"
      div(class: "flex items-center justify-between rounded-lg #{ltb_bg} px-3 py-3") do
        span(class: "text-sm font-bold #{ltb_text}") { "Left to Budget" }
        span(class: "text-lg font-bold #{ltb_text}") { format_currency(left) }
      end

      div(class: "border-t border-border pt-3") do
        h3(class: "text-sm font-semibold mb-3") { "Recent Transactions" }

        if @new_transactions.any? || @tracked_transactions.any?
          # New uncategorized
          if @new_transactions.any?
            div(class: "mb-3") do
              span(class: "text-xs font-semibold text-muted-foreground uppercase tracking-wider") do
                plain "New (#{@new_transactions.size})"
              end
            end
            div(class: "space-y-1") do
              @new_transactions.first(5).each do |txn|
                transaction_row(txn, uncategorized: true)
              end
              if @new_transactions.size > 5
                p(class: "text-xs text-muted-foreground text-center pt-1") do
                  plain "...and #{@new_transactions.size - 5} more"
                end
              end
            end
          end

          # Tracked
          if @tracked_transactions.any?
            div(class: "mt-4 mb-3") do
              span(class: "text-xs font-semibold text-muted-foreground uppercase tracking-wider") { "Tracked" }
            end
            div(class: "space-y-1") do
              @tracked_transactions.first(5).each do |txn|
                transaction_row(txn, uncategorized: false)
              end
              if @tracked_transactions.size > 5
                p(class: "text-xs text-muted-foreground text-center pt-1") do
                  plain "...and #{@tracked_transactions.size - 5} more"
                end
              end
            end
          end
        else
          div(class: "text-center py-4") do
            p(class: "text-sm text-muted-foreground") { "No transactions this month." }
          end
        end
      end
    end
  end

  def transaction_row(txn, uncategorized: false)
    div(class: "flex items-center justify-between rounded-md px-2 py-2 hover:bg-accent/50 transition-colors") do
      div(class: "flex-1 min-w-0") do
        div(class: "flex items-center gap-2") do
          if uncategorized
            div(class: "w-1.5 h-1.5 rounded-full bg-red-500 shrink-0", title: "Uncategorized")
          else
            div(class: "w-1.5 h-1.5 rounded-full bg-green-500 shrink-0", title: "Categorized")
          end
          span(class: "text-sm font-medium truncate") { txn.merchant || txn.description || "Transaction" }
        end
        div(class: "flex items-center gap-2 mt-0.5 pl-3.5") do
          span(class: "text-xs text-muted-foreground") { txn.date.strftime("%b %d") }
          if txn.account
            span(class: "text-xs text-muted-foreground") { txn.account.name }
          end
          if !uncategorized && txn.budget_item
            span(class: "inline-flex items-center rounded bg-muted px-1.5 py-0.5 text-xs text-muted-foreground") do
              plain txn.budget_item.name
            end
          end
        end
      end
      span(class: "text-sm font-medium shrink-0 #{txn.income? ? 'text-green-600 dark:text-green-400' : 'text-foreground'}") do
        plain txn.income? ? "+#{format_currency(txn.amount)}" : format_currency(txn.amount)
      end
    end
  end

  # ---------- HELPERS ----------

  def chevron_icon
    svg(
      xmlns: "http://www.w3.org/2000/svg",
      width: "16", height: "16", viewBox: "0 0 24 24",
      fill: "none", stroke: "currentColor", stroke_width: "2",
      stroke_linecap: "round", stroke_linejoin: "round",
      class: "shrink-0 transition-transform group-open:rotate-90",
      aria: { hidden: "true" }
    ) do |s|
      s.path(d: "m9 18 6-6-6-6")
    end
  end

  def prev_year
    @period.month == 1 ? @period.year - 1 : @period.year
  end

  def prev_month
    @period.month == 1 ? 12 : @period.month - 1
  end

  def next_year
    @period.month == 12 ? @period.year + 1 : @period.year
  end

  def next_month
    @period.month == 12 ? 1 : @period.month + 1
  end

  def input_class
    "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
