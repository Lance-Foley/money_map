# frozen_string_literal: true

class Views::Accounts::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(account:, transactions:)
    @account = account
    @transactions = transactions
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Back link
      div(class: "flex items-center gap-2") do
        a(href: helpers.accounts_path, class: "text-sm text-muted-foreground hover:text-foreground") { "< Back to Accounts" }
      end

      # Account header
      div(class: "flex items-center justify-between") do
        div do
          div(class: "flex items-center gap-3") do
            h1(class: "text-2xl font-bold tracking-tight") { @account.name }
            Badge(variant: @account.debt? ? :destructive : :default) { @account.account_type.titleize }
          end
          p(class: "text-muted-foreground") { @account.institution_name || "No institution" }
        end
        a(
          href: helpers.edit_account_path(@account),
          class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent"
        ) do
          plain "Edit Account"
        end
      end

      # Balance info cards
      div(class: "grid gap-4 md:grid-cols-2 lg:grid-cols-4") do
        # Current balance - always shown
        info_card("Current Balance", format_currency(@account.balance), @account.debt? ? "text-red-600 dark:text-red-400" : "text-green-600 dark:text-green-400")

        # Interest rate - shown if present
        if @account.interest_rate.present? && @account.interest_rate > 0
          info_card("Interest Rate", format_rate(@account.interest_rate))
        end

        # Minimum payment - for debt accounts
        if @account.debt? && @account.minimum_payment.present? && @account.minimum_payment > 0
          info_card("Minimum Payment", format_currency(@account.minimum_payment))
        end

        # Credit limit - for credit cards
        if @account.credit_card? && @account.credit_limit.present? && @account.credit_limit > 0
          info_card("Credit Limit", format_currency(@account.credit_limit))
        end

        # Original balance - for loans/mortgages
        if (@account.loan? || @account.mortgage?) && @account.original_balance.present? && @account.original_balance > 0
          info_card("Original Balance", format_currency(@account.original_balance))
        end

        # Utilization - for credit cards
        if @account.credit_card? && @account.credit_limit.present? && @account.credit_limit > 0
          pct = ((@account.balance / @account.credit_limit) * 100).round(1)
          info_card("Utilization", "#{pct}%", pct > 75 ? "text-red-600 dark:text-red-400" : nil)
        end

        # Remaining balance - for loans/mortgages
        if (@account.loan? || @account.mortgage?) && @account.original_balance.present? && @account.original_balance > 0
          paid_off = ((((@account.original_balance - @account.balance) / @account.original_balance) * 100)).round(1)
          info_card("Paid Off", "#{paid_off}%", "text-green-600 dark:text-green-400")
        end
      end

      # Transaction history
      Card do
        CardHeader do
          CardTitle { "Transaction History" }
          CardDescription { "Last 50 transactions for this account." }
        end
        CardContent do
          if @transactions.any?
            Table do
              TableHeader do
                TableRow do
                  TableHead { "Date" }
                  TableHead { "Description" }
                  TableHead { "Merchant" }
                  TableHead { "Category" }
                  TableHead(class: "text-right") { "Amount" }
                end
              end
              TableBody do
                @transactions.each do |txn|
                  TableRow do
                    TableCell { txn.date.strftime("%b %d, %Y") }
                    TableCell { txn.description || "-" }
                    TableCell { txn.merchant || "-" }
                    TableCell { txn.budget_item&.name || "Uncategorized" }
                    TableCell(class: "text-right font-medium #{txn.income? ? 'text-green-600 dark:text-green-400' : ''}") do
                      plain "#{txn.income? ? '+' : '-'}#{format_currency(txn.amount)}"
                    end
                  end
                end
              end
            end
          else
            div(class: "flex h-[100px] items-center justify-center text-muted-foreground") do
              plain "No transactions found for this account."
            end
          end
        end
      end
    end
  end

  private

  def info_card(title, value, value_class = nil)
    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium text-muted-foreground") { title }
      end
      CardContent do
        div(class: "text-2xl font-bold #{value_class}") { value }
      end
    end
  end

  def format_currency(amount)
    number = amount || 0
    if number >= 1000
      whole, decimal = ("%.2f" % number).split(".")
      whole_with_commas = whole.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
      "$#{whole_with_commas}.#{decimal}"
    else
      "$#{'%.2f' % number}"
    end
  end

  def format_rate(rate)
    "#{'%.2f' % ((rate || 0) * 100)}%"
  end
end
