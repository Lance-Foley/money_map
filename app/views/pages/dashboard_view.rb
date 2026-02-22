# frozen_string_literal: true

class Views::Pages::DashboardView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(period:, left_to_budget:, debt_comparison:, monthly_cash_flow:, upcoming_bills:, net_worth:, recent_transactions:, savings_goals:)
    @period = period
    @left_to_budget = left_to_budget
    @debt_comparison = debt_comparison
    @monthly_cash_flow = monthly_cash_flow
    @upcoming_bills = upcoming_bills
    @net_worth = net_worth
    @recent_transactions = recent_transactions
    @savings_goals = savings_goals
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-4 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Dashboard" }
          p(class: "text-muted-foreground") { "Your financial overview at a glance." }
        end
      end

      # Full width: Left to Budget
      left_to_budget_card

      # Row 1: Debt-Free Date + Monthly Cash Flow
      div(class: "grid gap-4 md:grid-cols-2") do
        debt_free_date_card
        monthly_cash_flow_card
      end

      # Row 2: Net Worth + Savings Goals
      div(class: "grid gap-4 md:grid-cols-2") do
        net_worth_card
        savings_goals_card
      end

      # Row 3: Upcoming Bills + Recent Transactions
      div(class: "grid gap-4 md:grid-cols-2") do
        upcoming_bills_card
        recent_transactions_card
      end
    end
  end

  private

  # 1. Left to Budget (full width top)
  def left_to_budget_card
    zero_based = @left_to_budget.to_f.zero?
    color = zero_based ? "text-green-600" : "text-red-600"
    bg = zero_based ? "border-green-500/30" : "border-red-500/30"

    Card(class: bg) do
      CardContent(class: "pt-6") do
        div(class: "flex items-center justify-between") do
          div do
            p(class: "text-sm font-medium text-muted-foreground") { "Left to Budget" }
            p(class: "text-3xl font-bold #{color}") { format_currency(@left_to_budget) }
            if @period
              p(class: "text-xs text-muted-foreground mt-1") do
                if zero_based
                  plain "Every dollar is assigned! Your budget is zero-based."
                else
                  plain "#{format_currency(@left_to_budget.abs)} #{@left_to_budget > 0 ? 'still needs to be assigned' : 'over-budgeted'}"
                end
              end
            else
              p(class: "text-xs text-muted-foreground mt-1") { "No budget period for this month yet." }
            end
          end
          a(
            href: helpers.budget_path,
            class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90"
          ) { "Go to Budget" }
        end
      end
    end
  end

  # 2. Debt-Free Date card
  def debt_free_date_card
    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium") { "Debt-Free Date" }
        CardDescription { "Snowball vs Avalanche strategies" }
      end
      CardContent do
        if @debt_comparison
          div(class: "grid grid-cols-2 gap-4") do
            # Snowball
            div(class: "space-y-1") do
              p(class: "text-xs text-muted-foreground") { "Snowball" }
              p(class: "text-lg font-bold") { @debt_comparison[:snowball][:debt_free_date].strftime("%b %Y") }
              p(class: "text-xs text-muted-foreground") { "#{@debt_comparison[:snowball][:months_to_freedom]} months" }
            end
            # Avalanche
            div(class: "space-y-1") do
              p(class: "text-xs text-muted-foreground") { "Avalanche" }
              p(class: "text-lg font-bold") { @debt_comparison[:avalanche][:debt_free_date].strftime("%b %Y") }
              p(class: "text-xs text-muted-foreground") { "#{@debt_comparison[:avalanche][:months_to_freedom]} months" }
            end
          end
          div(class: "mt-3 pt-3 border-t") do
            p(class: "text-xs text-muted-foreground") do
              plain "Avalanche saves #{format_currency(@debt_comparison[:savings_difference])} in interest"
            end
          end
        else
          div(class: "flex h-[80px] items-center justify-center text-sm text-muted-foreground") do
            plain "No debt accounts found."
          end
        end
      end
      CardFooter(class: "pt-0") do
        a(href: helpers.debts_path, class: "text-xs text-primary hover:underline") { "View Debt Payoff Plan" }
      end
    end
  end

  # 3. Monthly Cash Flow card
  def monthly_cash_flow_card
    income = @monthly_cash_flow[:income]
    spent = @monthly_cash_flow[:spent]
    remaining = @monthly_cash_flow[:remaining]
    pct = income > 0 ? (spent / income * 100).round(0) : 0

    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium") { "Monthly Cash Flow" }
        CardDescription { @period ? @period.display_name : "No period" }
      end
      CardContent do
        div(class: "space-y-3") do
          div(class: "flex justify-between text-sm") do
            span(class: "text-muted-foreground") { "Income" }
            span(class: "font-medium text-green-600") { format_currency(income) }
          end
          div(class: "flex justify-between text-sm") do
            span(class: "text-muted-foreground") { "Spent" }
            span(class: "font-medium text-red-600") { format_currency(spent) }
          end
          div(class: "h-3 rounded-full bg-muted overflow-hidden") do
            bar_color = pct > 100 ? "bg-red-500" : pct > 80 ? "bg-yellow-500" : "bg-green-500"
            div(class: "h-full rounded-full #{bar_color}", style: "width: #{[pct, 100].min}%")
          end
          div(class: "flex justify-between text-sm") do
            span(class: "text-muted-foreground") { "Remaining" }
            span(class: "font-bold #{remaining >= 0 ? 'text-green-600' : 'text-red-600'}") { format_currency(remaining) }
          end
        end
      end
    end
  end

  # 4. Net Worth card
  def net_worth_card
    current = @net_worth[:current]
    previous = @net_worth[:previous]
    trend = @net_worth[:trend]
    change = current - previous

    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium") { "Net Worth" }
      end
      CardContent do
        div(class: "flex items-baseline gap-2") do
          p(class: "text-2xl font-bold") { format_currency(current) }
          if trend == :up
            span(class: "text-sm text-green-600") { "+#{format_currency(change.abs)}" }
          elsif trend == :down
            span(class: "text-sm text-red-600") { "-#{format_currency(change.abs)}" }
          end
        end
        p(class: "text-xs text-muted-foreground mt-1") do
          case trend
          when :up then plain "Trending up from last snapshot"
          when :down then plain "Trending down from last snapshot"
          else plain "No trend data available"
          end
        end
      end
      CardFooter(class: "pt-0") do
        a(href: helpers.reports_path, class: "text-xs text-primary hover:underline") { "View Reports" }
      end
    end
  end

  # 5. Savings Goals card
  def savings_goals_card
    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium") { "Savings Goals" }
        CardDescription { "Top priorities" }
      end
      CardContent do
        if @savings_goals.any?
          div(class: "space-y-3") do
            @savings_goals.each do |goal|
              div(class: "space-y-1") do
                div(class: "flex justify-between text-sm") do
                  span(class: "font-medium") { goal.name }
                  span(class: "text-muted-foreground") { "#{goal.progress_percentage}%" }
                end
                div(class: "h-2 rounded-full bg-muted overflow-hidden") do
                  div(class: "h-full rounded-full bg-primary", style: "width: #{[goal.progress_percentage, 100].min}%")
                end
                div(class: "flex justify-between text-xs text-muted-foreground") do
                  span { format_currency(goal.current_amount) }
                  span { "of #{format_currency(goal.target_amount)}" }
                end
              end
            end
          end
        else
          div(class: "flex h-[80px] items-center justify-center text-sm text-muted-foreground") do
            plain "No active savings goals."
          end
        end
      end
      CardFooter(class: "pt-0") do
        a(href: helpers.savings_goals_path, class: "text-xs text-primary hover:underline") { "View All Goals" }
      end
    end
  end

  # 6. Upcoming Bills card
  def upcoming_bills_card
    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium") { "Upcoming Bills" }
        CardDescription { "Next 7 days" }
      end
      CardContent do
        if @upcoming_bills.any?
          div(class: "space-y-2") do
            @upcoming_bills.each do |bill|
              div(class: "flex items-center justify-between rounded-md border p-2") do
                div do
                  p(class: "text-sm font-medium") { bill.name }
                  p(class: "text-xs text-muted-foreground") do
                    days = bill.days_until_due
                    if days == 0
                      plain "Due today"
                    elsif days == 1
                      plain "Due tomorrow"
                    else
                      plain "Due in #{days} days (#{bill.next_due_date.strftime('%b %d')})"
                    end
                  end
                end
                span(class: "font-medium text-sm") { format_currency(bill.amount) }
              end
            end
          end
        else
          div(class: "flex h-[80px] items-center justify-center text-sm text-muted-foreground") do
            plain "No bills due in the next 7 days."
          end
        end
      end
      CardFooter(class: "pt-0") do
        a(href: helpers.recurring_transactions_path, class: "text-xs text-primary hover:underline") { "View All Bills" }
      end
    end
  end

  # 7. Recent Transactions card
  def recent_transactions_card
    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium") { "Recent Transactions" }
        CardDescription { "Last 5 transactions" }
      end
      CardContent do
        if @recent_transactions.any?
          div(class: "space-y-2") do
            @recent_transactions.each do |txn|
              div(class: "flex items-center justify-between rounded-md border p-2") do
                div do
                  p(class: "text-sm font-medium") { txn.description || txn.merchant || "Transaction" }
                  p(class: "text-xs text-muted-foreground") { txn.date.strftime("%b %d, %Y") }
                end
                span(class: "font-medium text-sm #{txn.income? ? 'text-green-600' : 'text-red-600'}") do
                  plain "#{txn.income? ? '+' : '-'}#{format_currency(txn.amount)}"
                end
              end
            end
          end
        else
          div(class: "flex h-[80px] items-center justify-center text-sm text-muted-foreground") do
            plain "No transactions recorded yet."
          end
        end
      end
      CardFooter(class: "pt-0") do
        a(href: helpers.transactions_path, class: "text-xs text-primary hover:underline") { "View All Transactions" }
      end
    end
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
