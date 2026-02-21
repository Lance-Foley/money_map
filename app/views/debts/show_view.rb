# frozen_string_literal: true

class Views::Debts::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(account:, payments:)
    @account = account
    @payments = payments
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Breadcrumb
      div(class: "flex items-center gap-2") do
        a(href: helpers.debts_path, class: "text-sm text-muted-foreground hover:text-foreground") { "< Back to Debt Payoff" }
      end

      # Header
      div(class: "flex items-center gap-3") do
        h1(class: "text-2xl font-bold tracking-tight") { @account.name }
        Badge(variant: :destructive) { @account.account_type.titleize }
      end

      # Account details
      div(class: "grid gap-4 md:grid-cols-4") do
        detail_card("Current Balance", format_currency(@account.balance))
        detail_card("Interest Rate", @account.interest_rate ? "#{(@account.interest_rate * 100).round(2)}%" : "N/A")
        detail_card("Minimum Payment", format_currency(@account.minimum_payment))
        if @account.original_balance.present? && @account.original_balance > 0
          progress = ((@account.original_balance - @account.balance) / @account.original_balance * 100).round(1)
          detail_card("Paid Off", "#{progress}%")
        end
      end

      # Payment history
      Card do
        CardHeader do
          CardTitle { "Payment History" }
          CardDescription { "#{@payments.size} payments recorded" }
        end
        CardContent do
          if @payments.any?
            Table do
              TableHeader do
                TableRow do
                  TableHead { "Date" }
                  TableHead { "Total Payment" }
                  TableHead { "Principal" }
                  TableHead { "Interest" }
                end
              end
              TableBody do
                @payments.each do |payment|
                  TableRow do
                    TableCell { payment.payment_date.strftime("%b %d, %Y") }
                    TableCell(class: "font-medium") { format_currency(payment.amount) }
                    TableCell { payment.principal_portion ? format_currency(payment.principal_portion) : "-" }
                    TableCell { payment.interest_portion ? format_currency(payment.interest_portion) : "-" }
                  end
                end
              end
            end
          else
            div(class: "flex h-[100px] items-center justify-center text-muted-foreground") do
              plain "No payment history recorded."
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
