# frozen_string_literal: true

class Views::Debts::IndexView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(accounts:, comparison:, extra_payment:)
    @accounts = accounts
    @comparison = comparison
    @extra_payment = extra_payment
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div do
        h1(class: "text-2xl font-bold tracking-tight") { "Debt Payoff" }
        p(class: "text-muted-foreground") { "Compare snowball vs avalanche strategies and plan your debt freedom." }
      end

      if @accounts.empty?
        Card do
          CardContent(class: "pt-6") do
            div(class: "flex h-[100px] items-center justify-center text-muted-foreground") do
              plain "No debt accounts found. Add credit card, loan, or mortgage accounts to see your payoff plan."
            end
          end
        end
      else
        # Extra payment input
        Card do
          CardContent(class: "pt-4") do
            form_with(url: helpers.debts_path, method: :get, class: "flex items-end gap-3") do |f|
              div(class: "space-y-2") do
                label(class: "text-sm font-medium") { "Extra Monthly Payment" }
                f.number_field :extra_payment, value: @extra_payment, step: 50, min: 0, class: "flex h-9 w-48 rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring", placeholder: "0.00"
              end
              f.submit "Recalculate", class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
            end
          end
        end

        # Debts summary table
        Card do
          CardHeader do
            CardTitle { "Your Debts" }
            CardDescription { "#{@accounts.size} debt accounts totaling #{format_currency(@accounts.sum(&:balance))}" }
          end
          CardContent do
            Table do
              TableHeader do
                TableRow do
                  TableHead { "Account" }
                  TableHead { "Balance" }
                  TableHead { "Interest Rate" }
                  TableHead { "Minimum Payment" }
                  TableHead { "Actions" }
                end
              end
              TableBody do
                @accounts.each do |account|
                  TableRow do
                    TableCell(class: "font-medium") { account.name }
                    TableCell { format_currency(account.balance) }
                    TableCell { account.interest_rate ? "#{(account.interest_rate * 100).round(2)}%" : "-" }
                    TableCell { account.minimum_payment ? format_currency(account.minimum_payment) : "-" }
                    TableCell do
                      a(href: helpers.debt_path(account), class: "text-sm text-primary hover:underline") { "Details" }
                    end
                  end
                end
              end
            end
          end
        end

        # Strategy comparison
        if @comparison
          div(class: "grid gap-6 md:grid-cols-2") do
            strategy_card("Snowball", @comparison[:snowball], "Pay smallest balances first for quick wins.")
            strategy_card("Avalanche", @comparison[:avalanche], "Pay highest interest first to save money.")
          end

          # Comparison summary
          Card do
            CardHeader do
              CardTitle { "Strategy Comparison" }
            end
            CardContent do
              div(class: "grid gap-4 sm:grid-cols-3") do
                comparison_stat(
                  "Interest Savings (Avalanche)",
                  format_currency(@comparison[:savings_difference]),
                  "Less interest paid with avalanche vs snowball"
                )
                comparison_stat(
                  "Time Difference",
                  "#{@comparison[:months_difference].abs} months",
                  @comparison[:months_difference] > 0 ? "Avalanche is faster" : @comparison[:months_difference] < 0 ? "Snowball is faster" : "Same timeline"
                )
                comparison_stat(
                  "Total Minimum Payments",
                  format_currency(@accounts.sum { |a| a.minimum_payment || 0 }),
                  "Per month across all debts"
                )
              end
            end
          end
        end
      end
    end
  end

  private

  def strategy_card(name, result, description)
    Card do
      CardHeader do
        CardTitle { "#{name} Strategy" }
        CardDescription { description }
      end
      CardContent do
        div(class: "space-y-4") do
          div(class: "grid gap-3 grid-cols-2") do
            stat_item("Debt-Free Date", result[:debt_free_date].strftime("%B %Y"))
            stat_item("Months to Freedom", result[:months_to_freedom].to_s)
            stat_item("Total Interest", format_currency(result[:total_interest]))
            stat_item("Total Paid", format_currency(result[:total_paid]))
          end

          # Payoff order
          div(class: "pt-3 border-t") do
            h4(class: "text-sm font-medium mb-2") { "Payoff Order" }
            div(class: "space-y-1") do
              result[:payoff_order].each_with_index do |debt, i|
                div(class: "flex items-center gap-2 text-sm") do
                  span(class: "flex h-5 w-5 items-center justify-center rounded-full bg-primary text-[10px] text-primary-foreground font-medium") { (i + 1).to_s }
                  span { "#{debt[:name]} (#{format_currency(debt[:balance])})" }
                end
              end
            end
          end
        end
      end
    end
  end

  def comparison_stat(label, value, description)
    div do
      p(class: "text-sm text-muted-foreground") { label }
      p(class: "text-2xl font-bold") { value }
      p(class: "text-xs text-muted-foreground") { description }
    end
  end

  def stat_item(label, value)
    div do
      p(class: "text-xs text-muted-foreground") { label }
      p(class: "text-sm font-semibold") { value }
    end
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
