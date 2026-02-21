# frozen_string_literal: true

class Views::RecurringBills::IndexView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(bills:)
    @bills = bills
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Recurring Bills" }
          p(class: "text-muted-foreground") { "Manage your recurring bills and subscriptions." }
        end
        a(href: helpers.new_recurring_bill_path, class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90") do
          plain "+ Add Bill"
        end
      end

      # Summary
      div(class: "grid gap-4 md:grid-cols-3") do
        monthly_total = @bills.select(&:monthly?).sum(&:amount)
        summary_card("Monthly Bills", format_currency(monthly_total), "#{@bills.select(&:monthly?).size} monthly bills")

        overdue_count = @bills.select(&:overdue?).size
        summary_card("Overdue", overdue_count.to_s, overdue_count > 0 ? "Action required" : "All up to date")

        upcoming = @bills.select { |b| b.days_until_due && b.days_until_due >= 0 && b.days_until_due <= 7 }
        summary_card("Due This Week", upcoming.size.to_s, "Next 7 days")
      end

      # Bills table
      Card do
        CardContent(class: "pt-4") do
          if @bills.any?
            Table do
              TableHeader do
                TableRow do
                  TableHead { "Name" }
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
                @bills.each do |bill|
                  TableRow do
                    TableCell(class: "font-medium") { bill.name }
                    TableCell { format_currency(bill.amount) }
                    TableCell { bill.frequency.titleize }
                    TableCell { bill.due_day.to_s }
                    TableCell { bill.next_due_date&.strftime("%b %d, %Y") || "-" }
                    TableCell { status_badge(bill) }
                    TableCell { bill.budget_category&.name || "-" }
                    TableCell { bill.account&.name || "-" }
                    TableCell do
                      div(class: "flex gap-2") do
                        a(href: helpers.edit_recurring_bill_path(bill), class: "text-sm text-primary hover:underline") { "Edit" }
                        a(href: helpers.recurring_bill_path(bill), data: { turbo_method: :delete, turbo_confirm: "Delete this bill?" }, class: "text-sm text-destructive hover:underline") { "Delete" }
                      end
                    end
                  end
                end
              end
            end
          else
            div(class: "flex h-[100px] items-center justify-center text-muted-foreground") do
              plain "No recurring bills found. Add one to start tracking."
            end
          end
        end
      end
    end
  end

  private

  def status_badge(bill)
    if bill.overdue?
      Badge(variant: :destructive) { "Overdue" }
    elsif bill.days_until_due && bill.days_until_due <= 3
      Badge(variant: :warning) { "Due Soon" }
    elsif bill.days_until_due && bill.days_until_due <= 7
      Badge(variant: :secondary) { "Upcoming" }
    else
      Badge(variant: :outline) { "Scheduled" }
    end
  end

  def summary_card(title, value, description)
    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium") { title }
      end
      CardContent do
        div(class: "text-2xl font-bold") { value }
        p(class: "text-xs text-muted-foreground") { description }
      end
    end
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
