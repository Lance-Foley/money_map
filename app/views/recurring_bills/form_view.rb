# frozen_string_literal: true

class Views::RecurringBills::FormView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(bill:, accounts:, categories:)
    @bill = bill
    @accounts = accounts
    @categories = categories
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Breadcrumb
      div(class: "flex items-center gap-2") do
        a(href: helpers.recurring_bills_path, class: "text-sm text-muted-foreground hover:text-foreground") { "< Back to Recurring Bills" }
      end

      h1(class: "text-2xl font-bold tracking-tight") do
        plain @bill.persisted? ? "Edit Recurring Bill" : "New Recurring Bill"
      end

      Card(class: "max-w-2xl") do
        CardContent(class: "pt-6") do
          form_with(model: @bill, class: "space-y-6") do |f|
            # Errors
            if @bill.errors.any?
              div(class: "rounded-lg border border-destructive/20 bg-destructive/5 p-4 text-sm text-destructive") do
                ul(class: "list-disc pl-4 space-y-1") do
                  @bill.errors.full_messages.each do |msg|
                    li { msg }
                  end
                end
              end
            end

            # Name
            div(class: "space-y-2") do
              label(for: "recurring_bill_name", class: "text-sm font-medium leading-none") { "Bill Name" }
              f.text_field :name, class: input_class, placeholder: "e.g. Electric Bill"
            end

            # Amount
            div(class: "space-y-2") do
              label(for: "recurring_bill_amount", class: "text-sm font-medium leading-none") { "Amount" }
              f.number_field :amount, step: 0.01, class: input_class, placeholder: "0.00"
            end

            # Frequency
            div(class: "space-y-2") do
              label(for: "recurring_bill_frequency", class: "text-sm font-medium leading-none") { "Frequency" }
              f.select :frequency, RecurringBill.frequencies.keys.map { |freq| [freq.titleize, freq] }, { prompt: "Select frequency..." }, class: input_class
            end

            # Due day
            div(class: "space-y-2") do
              label(for: "recurring_bill_due_day", class: "text-sm font-medium leading-none") { "Due Day of Month (1-31)" }
              f.number_field :due_day, min: 1, max: 31, class: input_class, placeholder: "1"
            end

            # Account
            div(class: "space-y-2") do
              label(for: "recurring_bill_account_id", class: "text-sm font-medium leading-none") { "Account" }
              f.select :account_id, @accounts.map { |a| [a.name, a.id] }, { prompt: "Select account (optional)..." }, class: input_class
            end

            # Category
            div(class: "space-y-2") do
              label(for: "recurring_bill_budget_category_id", class: "text-sm font-medium leading-none") { "Budget Category" }
              f.select :budget_category_id, @categories.map { |c| [c.name, c.id] }, { prompt: "Select category (optional)..." }, class: input_class
            end

            # Auto create transaction
            div(class: "flex items-center gap-2") do
              f.check_box :auto_create_transaction, class: "rounded border-input"
              label(for: "recurring_bill_auto_create_transaction", class: "text-sm font-medium leading-none") { "Auto-create transaction when due" }
            end

            # Reminder days
            div(class: "space-y-2") do
              label(for: "recurring_bill_reminder_days_before", class: "text-sm font-medium leading-none") { "Reminder Days Before" }
              f.number_field :reminder_days_before, min: 0, max: 30, class: input_class, placeholder: "3"
            end

            # Submit
            div(class: "flex gap-3") do
              f.submit(@bill.persisted? ? "Update Bill" : "Create Bill", class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer")
              a(href: helpers.recurring_bills_path, class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent") { "Cancel" }
            end
          end
        end
      end
    end
  end

  private

  def input_class
    "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
  end
end
