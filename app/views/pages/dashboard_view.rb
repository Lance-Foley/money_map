# frozen_string_literal: true

class Views::Pages::DashboardView < Views::Base
  def view_template
    div(class: "flex flex-1 flex-col gap-4 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Dashboard" }
          p(class: "text-muted-foreground") { "Welcome to MoneyMap. Your financial overview at a glance." }
        end
      end

      # Placeholder cards
      div(class: "grid gap-4 md:grid-cols-2 lg:grid-cols-4") do
        dashboard_card("Total Balance", "$0.00", "Across all accounts")
        dashboard_card("Monthly Income", "$0.00", "This month")
        dashboard_card("Monthly Expenses", "$0.00", "This month")
        dashboard_card("Savings Rate", "0%", "This month")
      end

      # Placeholder content area
      div(class: "grid gap-4 md:grid-cols-2 lg:grid-cols-7") do
        Card(class: "col-span-4") do
          CardHeader do
            CardTitle { "Spending Overview" }
            CardDescription { "Your spending breakdown for this month." }
          end
          CardContent do
            div(class: "flex h-[200px] items-center justify-center text-muted-foreground") do
              "Chart will be displayed here"
            end
          end
        end

        Card(class: "col-span-3") do
          CardHeader do
            CardTitle { "Recent Transactions" }
            CardDescription { "Your latest financial activity." }
          end
          CardContent do
            div(class: "flex h-[200px] items-center justify-center text-muted-foreground") do
              "Transactions will be displayed here"
            end
          end
        end
      end
    end
  end

  private

  def dashboard_card(title, value, description)
    Card do
      CardHeader(class: "flex flex-row items-center justify-between space-y-0 pb-2") do
        CardTitle(class: "text-sm font-medium") { title }
      end
      CardContent do
        div(class: "text-2xl font-bold") { value }
        p(class: "text-xs text-muted-foreground") { description }
      end
    end
  end
end
