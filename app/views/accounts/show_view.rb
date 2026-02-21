# frozen_string_literal: true

class Views::Accounts::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(account:, transactions:)
    @account = account
    @transactions = transactions
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Breadcrumb / back link
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
        a(href: helpers.edit_account_path(@account), class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent") do
          plain "Edit Account"
        end
      end

      # Account details
      div(class: "grid gap-4 md:grid-cols-4") do
        detail_card("Balance", format_currency(@account.balance))
        if @account.interest_rate.present? && @account.interest_rate > 0
          detail_card("Interest Rate", "#{(@account.interest_rate * 100).round(2)}%")
        end
        if @account.minimum_payment.present? && @account.minimum_payment > 0
          detail_card("Minimum Payment", format_currency(@account.minimum_payment))
        end
        if @account.credit_limit.present? && @account.credit_limit > 0
          detail_card("Credit Limit", format_currency(@account.credit_limit))
        end
        if @account.original_balance.present? && @account.original_balance > 0
          detail_card("Original Balance", format_currency(@account.original_balance))
        end
      end

      # Recent transactions
      Card do
        CardHeader do
          CardTitle { "Recent Transactions" }
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

  def detail_card(title, value)
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
