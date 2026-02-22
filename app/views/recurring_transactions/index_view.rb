# frozen_string_literal: true

class Views::RecurringTransactions::IndexView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(transactions:)
    @transactions = transactions
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Recurring" }
          p(class: "text-muted-foreground") { "Manage your recurring income, expenses, and transfers." }
        end
        a(href: helpers.new_recurring_transaction_path, class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90") do
          plain "+ Add Recurring"
        end
      end

      # Summary
      div(class: "grid gap-4 md:grid-cols-4") do
        income_items = @transactions.select(&:income?)
        expense_items = @transactions.select(&:expense?)
        monthly_income = income_items.select(&:monthly?).sum(&:amount)
        monthly_expenses = expense_items.select(&:monthly?).sum(&:amount)

        summary_card("Monthly Income", format_currency(monthly_income), "#{income_items.size} income sources", "text-green-600")
        summary_card("Monthly Expenses", format_currency(monthly_expenses), "#{expense_items.size} recurring bills", "text-red-600")

        net = monthly_income - monthly_expenses
        net_color = net >= 0 ? "text-green-600" : "text-red-600"
        summary_card("Net Monthly", format_currency(net), net >= 0 ? "Surplus" : "Shortfall", net_color)

        overdue_count = expense_items.select(&:overdue?).size
        summary_card("Overdue", overdue_count.to_s, overdue_count > 0 ? "Action required" : "All up to date")
      end

      # Transactions table
      Card do
        CardContent(class: "pt-4") do
          if @transactions.any?
            Table do
              TableHeader do
                TableRow do
                  TableHead { "Name" }
                  TableHead { "Direction" }
                  TableHead { "Amount" }
                  TableHead { "Frequency" }
                  TableHead { "Due Day" }
                  TableHead { "Next Due" }
                  TableHead { "Status" }
                  TableHead { "Category" }
                  TableHead { "Account" }
                  TableHead { "Actions" }
                end
              end
              TableBody do
                @transactions.each do |txn|
                  TableRow do
                    TableCell(class: "font-medium") { txn.name }
                    TableCell { direction_badge(txn) }
                    TableCell(class: txn.income? ? "text-green-600" : "text-red-600") { format_currency(txn.amount) }
                    TableCell { txn.frequency.titleize }
                    TableCell { txn.due_day.to_s }
                    TableCell { txn.next_due_date&.strftime("%b %d, %Y") || "-" }
                    TableCell { status_badge(txn) }
                    TableCell { txn.budget_category&.name || "-" }
                    TableCell { txn.account&.name || "-" }
                    TableCell do
                      div(class: "flex gap-2") do
                        a(href: helpers.edit_recurring_transaction_path(txn), class: "text-sm text-primary hover:underline") { "Edit" }
                        a(href: helpers.recurring_transaction_path(txn), data: { turbo_method: :delete, turbo_confirm: "Delete this recurring transaction?" }, class: "text-sm text-destructive hover:underline") { "Delete" }
                      end
                    end
                  end
                end
              end
            end
          else
            div(class: "flex h-[100px] items-center justify-center text-muted-foreground") do
              plain "No recurring transactions found. Add one to start tracking."
            end
          end
        end
      end
    end
  end

  private

  def direction_badge(txn)
    case txn.direction
    when "income"
      Badge(variant: :default, class: "bg-green-500/10 text-green-700 border-green-500/20") { "Income" }
    when "transfer"
      Badge(variant: :secondary) { "Transfer" }
    else
      Badge(variant: :default, class: "bg-red-500/10 text-red-700 border-red-500/20") { "Expense" }
    end
  end

  def status_badge(txn)
    if txn.expense? && txn.overdue?
      Badge(variant: :destructive) { "Overdue" }
    elsif txn.days_until_due && txn.days_until_due <= 3
      Badge(variant: :warning) { "Due Soon" }
    elsif txn.days_until_due && txn.days_until_due <= 7
      Badge(variant: :secondary) { "Upcoming" }
    else
      Badge(variant: :outline) { "Scheduled" }
    end
  end

  def summary_card(title, value, description, value_class = nil)
    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium") { title }
      end
      CardContent do
        div(class: "text-2xl font-bold #{value_class}") { value }
        p(class: "text-xs text-muted-foreground") { description }
      end
    end
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
