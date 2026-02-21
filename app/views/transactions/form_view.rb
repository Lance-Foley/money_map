# frozen_string_literal: true

class Views::Transactions::FormView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(transaction:, accounts:, budget_items:)
    @transaction = transaction
    @accounts = accounts
    @budget_items = budget_items
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Breadcrumb
      div(class: "flex items-center gap-2") do
        a(href: helpers.transactions_path, class: "text-sm text-muted-foreground hover:text-foreground") { "< Back to Transactions" }
      end

      h1(class: "text-2xl font-bold tracking-tight") do
        plain @transaction.persisted? ? "Edit Transaction" : "New Transaction"
      end

      Card(class: "max-w-2xl") do
        CardContent(class: "pt-6") do
          form_with(model: @transaction, class: "space-y-6") do |f|
            # Errors
            if @transaction.errors.any?
              div(class: "rounded-lg border border-destructive/20 bg-destructive/5 p-4 text-sm text-destructive") do
                ul(class: "list-disc pl-4 space-y-1") do
                  @transaction.errors.full_messages.each do |msg|
                    li { msg }
                  end
                end
              end
            end

            # Date
            div(class: "space-y-2") do
              label(for: "transaction_date", class: "text-sm font-medium leading-none") { "Date" }
              f.date_field :date, value: @transaction.date || Date.current, class: input_class
            end

            # Account
            div(class: "space-y-2") do
              label(for: "transaction_account_id", class: "text-sm font-medium leading-none") { "Account" }
              f.select :account_id, @accounts.map { |a| [a.name, a.id] }, { prompt: "Select account..." }, class: input_class
            end

            # Transaction type
            div(class: "space-y-2") do
              label(for: "transaction_transaction_type", class: "text-sm font-medium leading-none") { "Type" }
              f.select :transaction_type, Transaction.transaction_types.keys.map { |t| [t.titleize, t] }, { prompt: "Select type..." }, class: input_class
            end

            # Amount
            div(class: "space-y-2") do
              label(for: "transaction_amount", class: "text-sm font-medium leading-none") { "Amount" }
              f.number_field :amount, step: 0.01, class: input_class, placeholder: "0.00"
            end

            # Description
            div(class: "space-y-2") do
              label(for: "transaction_description", class: "text-sm font-medium leading-none") { "Description" }
              f.text_field :description, class: input_class, placeholder: "e.g. Weekly groceries"
            end

            # Merchant
            div(class: "space-y-2") do
              label(for: "transaction_merchant", class: "text-sm font-medium leading-none") { "Merchant" }
              f.text_field :merchant, class: input_class, placeholder: "e.g. Kroger"
            end

            # Budget item (category)
            div(class: "space-y-2") do
              label(for: "transaction_budget_item_id", class: "text-sm font-medium leading-none") { "Budget Category" }
              f.select :budget_item_id, @budget_items.map { |bi| ["#{bi.budget_category.name}: #{bi.name}", bi.id] }, { prompt: "Uncategorized" }, class: input_class
            end

            # Notes
            div(class: "space-y-2") do
              label(for: "transaction_notes", class: "text-sm font-medium leading-none") { "Notes" }
              f.text_area :notes, rows: 3, class: "flex w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring", placeholder: "Optional notes..."
            end

            # Submit
            div(class: "flex gap-3") do
              f.submit(@transaction.persisted? ? "Update Transaction" : "Add Transaction", class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer")
              a(href: helpers.transactions_path, class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent") { "Cancel" }
            end
          end
        end
      end

      # Transaction Splits section (only for existing transactions)
      if @transaction.persisted?
        splits_section
      end
    end
  end

  private

  def splits_section
    Card(class: "max-w-2xl") do
      CardHeader do
        CardTitle(class: "text-base") { "Transaction Splits" }
        CardDescription { "Split this transaction across multiple budget categories." }
      end
      CardContent do
        # Existing splits
        if @transaction.transaction_splits.any?
          div(class: "space-y-2 mb-4") do
            @transaction.transaction_splits.includes(:budget_item).each do |split|
              div(class: "flex items-center justify-between py-2 px-3 rounded-lg border bg-card") do
                div do
                  span(class: "text-sm font-medium") do
                    if split.budget_item
                      plain "#{split.budget_item.budget_category&.name}: #{split.budget_item.name}"
                    else
                      plain "Unknown category"
                    end
                  end
                  span(class: "text-sm text-muted-foreground ml-2") { "$#{'%.2f' % split.amount}" }
                end
                form_with(url: helpers.transaction_transaction_split_path(@transaction, split), method: :delete, class: "inline") do |f|
                  f.submit "Remove", class: "h-7 rounded border border-input bg-background px-2 text-xs font-medium text-destructive hover:bg-destructive/10 cursor-pointer"
                end
              end
            end
          end
          div(class: "text-sm text-muted-foreground mb-4") do
            total_split = @transaction.transaction_splits.sum(:amount)
            plain "Split total: $#{'%.2f' % total_split} of $#{'%.2f' % @transaction.amount}"
          end
        end

        # Add new split form
        div(class: "pt-2 border-t") do
          h4(class: "text-sm font-medium mb-2") { "Add Split" }
          form_with(model: TransactionSplit.new, url: helpers.transaction_transaction_splits_path(@transaction), method: :post, class: "flex flex-wrap gap-3 items-end") do |f|
            div(class: "space-y-1 flex-1 min-w-[200px]") do
              label(class: "text-xs font-medium text-muted-foreground") { "Budget Category" }
              f.select :budget_item_id, @budget_items.map { |bi| ["#{bi.budget_category.name}: #{bi.name}", bi.id] }, { prompt: "Select..." }, class: input_class
            end
            div(class: "space-y-1 w-32") do
              label(class: "text-xs font-medium text-muted-foreground") { "Amount" }
              f.number_field :amount, step: 0.01, class: input_class, placeholder: "0.00"
            end
            div do
              f.submit "Add Split", class: "inline-flex items-center justify-center rounded-md bg-primary px-3 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer"
            end
          end
        end
      end
    end
  end

  def input_class
    "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
  end
end
