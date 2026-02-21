# frozen_string_literal: true

class Views::Transactions::IndexView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(transactions:, accounts:, budget_items:)
    @transactions = transactions
    @accounts = accounts
    @budget_items = budget_items
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Transactions" }
          p(class: "text-muted-foreground") { "View and manage all your transactions." }
        end
        div(class: "flex gap-2") do
          a(href: helpers.new_csv_import_path, class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent") do
            plain "Import CSV"
          end
          a(href: helpers.new_transaction_path, class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90") do
            plain "+ Add Transaction"
          end
        end
      end

      # Filters
      Card do
        CardContent(class: "pt-4") do
          form_with(url: helpers.transactions_path, method: :get, class: "flex flex-wrap gap-3 items-end") do |f|
            div(class: "flex-1 min-w-[200px]") do
              label(class: "text-sm font-medium mb-1 block") { "Search" }
              f.text_field :search, value: helpers.params[:search], placeholder: "Search descriptions...", class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            end
            div(class: "w-48") do
              label(class: "text-sm font-medium mb-1 block") { "Account" }
              f.select :account_id, @accounts.map { |a| [a.name, a.id] }, { prompt: "All accounts", selected: helpers.params[:account_id] }, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            end
            div(class: "w-40") do
              label(class: "text-sm font-medium mb-1 block") { "Start Date" }
              f.date_field :start_date, value: helpers.params[:start_date], class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            end
            div(class: "w-40") do
              label(class: "text-sm font-medium mb-1 block") { "End Date" }
              f.date_field :end_date, value: helpers.params[:end_date], class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            end
            div do
              f.submit "Filter", class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
            end
            div do
              a(href: helpers.transactions_path(uncategorized: "true"), class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-3 py-2 text-sm font-medium shadow-sm hover:bg-accent h-9") do
                plain "Uncategorized"
              end
            end
          end
        end
      end

      # Transactions table
      Card do
        CardContent(class: "pt-4") do
          if @transactions.any?
            Table do
              TableHeader do
                TableRow do
                  TableHead { "Date" }
                  TableHead { "Description" }
                  TableHead { "Merchant" }
                  TableHead { "Account" }
                  TableHead { "Category" }
                  TableHead { "Type" }
                  TableHead(class: "text-right") { "Amount" }
                  TableHead { "Actions" }
                end
              end
              TableBody do
                @transactions.each do |txn|
                  TableRow do
                    TableCell { txn.date.strftime("%b %d, %Y") }
                    TableCell(class: "font-medium") { txn.description || "-" }
                    TableCell { txn.merchant || "-" }
                    TableCell { txn.account&.name || "-" }
                    TableCell do
                      if txn.budget_item
                        Badge(variant: :secondary) { txn.budget_item.name }
                      else
                        Badge(variant: :outline) { "Uncategorized" }
                      end
                    end
                    TableCell do
                      Badge(variant: txn.income? ? :default : :destructive) { txn.transaction_type.titleize }
                    end
                    TableCell(class: "text-right font-medium #{txn.income? ? 'text-green-600 dark:text-green-400' : ''}") do
                      plain "#{txn.income? ? '+' : '-'}#{format_currency(txn.amount)}"
                    end
                    TableCell do
                      div(class: "flex gap-2") do
                        a(href: helpers.edit_transaction_path(txn), class: "text-sm text-primary hover:underline") { "Edit" }
                        a(href: helpers.transaction_path(txn), data: { turbo_method: :delete, turbo_confirm: "Delete this transaction?" }, class: "text-sm text-destructive hover:underline") { "Delete" }
                      end
                    end
                  end
                end
              end
            end
          else
            div(class: "flex h-[100px] items-center justify-center text-muted-foreground") do
              plain "No transactions found."
            end
          end
        end
      end
    end
  end

  private

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
