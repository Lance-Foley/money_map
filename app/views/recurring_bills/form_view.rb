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

            # Frequency section with Stimulus controller for custom toggle
            div(data: { controller: "frequency-toggle" }) do
              # Frequency
              div(class: "space-y-2") do
                label(for: "recurring_bill_frequency", class: "text-sm font-medium leading-none") { "Frequency" }
                f.select :frequency, frequency_options, { prompt: "Select frequency..." }, class: input_class, data: { frequency_select: true, action: "change->frequency-toggle#toggle" }
              end

              # Custom interval fields (shown only when Custom is selected)
              div(class: "space-y-4 mt-4 #{@bill.custom? ? '' : 'hidden'}", data: { frequency_toggle_target: "customFields" }) do
                div(class: "rounded-lg border border-border bg-muted/50 p-4 space-y-4") do
                  p(class: "text-sm font-medium text-muted-foreground") { "Custom Interval" }

                  div(class: "grid grid-cols-2 gap-4") do
                    # Interval value
                    div(class: "space-y-2") do
                      label(for: "recurring_bill_custom_interval_value", class: "text-sm font-medium leading-none") { "Every" }
                      f.number_field :custom_interval_value, min: 1, class: input_class, placeholder: "1"
                    end

                    # Interval unit
                    div(class: "space-y-2") do
                      label(for: "recurring_bill_custom_interval_unit", class: "text-sm font-medium leading-none") { "Unit" }
                      f.select :custom_interval_unit, interval_unit_options, { prompt: "Select unit..." }, class: input_class
                    end
                  end
                end
              end
            end

            # Start date
            div(class: "space-y-2") do
              label(for: "recurring_bill_start_date", class: "text-sm font-medium leading-none") { "Start Date" }
              f.date_field :start_date, class: input_class
              p(class: "text-xs text-muted-foreground") { "The date the first occurrence falls on. Used to calculate future due dates." }
            end

            # Schedule description (for existing bills)
            if @bill.persisted? && @bill.start_date.present?
              div(class: "rounded-lg border border-border bg-muted/50 p-3") do
                p(class: "text-sm") do
                  span(class: "font-medium") { "Schedule: " }
                  plain @bill.schedule_description
                end
              end
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

  def frequency_options
    [
      ["Weekly", "weekly"],
      ["Biweekly", "biweekly"],
      ["Semi-monthly", "semimonthly"],
      ["Monthly", "monthly"],
      ["Quarterly", "quarterly"],
      ["Semi-annual", "semi_annual"],
      ["Annual", "annual"],
      ["Custom", "custom"]
    ]
  end

  def interval_unit_options
    [
      ["Days", 0],
      ["Weeks", 1],
      ["Months", 2],
      ["Years", 3]
    ]
  end
end
