# frozen_string_literal: true

class Views::Accounts::IndexView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(accounts:)
    @accounts = accounts
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Accounts" }
          p(class: "text-muted-foreground") { "Manage your bank accounts, credit cards, and loans." }
        end
        a(href: helpers.new_account_path, class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90") do
          plain "+ Add Account"
        end
      end

      # Summary cards
      div(class: "grid gap-4 md:grid-cols-3") do
        summary_card("Total Assets", format_currency(asset_total), "Checking, Savings, Investment")
        summary_card("Total Liabilities", format_currency(liability_total), "Credit Cards, Loans, Mortgage")
        summary_card("Net Worth", format_currency(asset_total - liability_total), "Assets minus Liabilities")
      end

      # Accounts grouped by type
      account_types.each do |type_name, type_accounts|
        next if type_accounts.empty?
        div(class: "space-y-3") do
          h2(class: "text-lg font-semibold") { type_name }
          div(class: "grid gap-4 md:grid-cols-2 lg:grid-cols-3") do
            type_accounts.each do |account|
              account_card(account)
            end
          end
        end
      end
    end
  end

  private

  def account_types
    {
      "Checking" => @accounts.select(&:checking?),
      "Savings" => @accounts.select(&:savings?),
      "Credit Cards" => @accounts.select(&:credit_card?),
      "Loans" => @accounts.select(&:loan?),
      "Mortgages" => @accounts.select(&:mortgage?),
      "Investments" => @accounts.select(&:investment?)
    }
  end

  def asset_total
    @accounts.select(&:asset?).sum(&:balance)
  end

  def liability_total
    @accounts.select(&:debt?).sum(&:balance)
  end

  def account_card(account)
    Card do
      CardHeader(class: "pb-2") do
        div(class: "flex items-center justify-between") do
          CardTitle(class: "text-base") { account.name }
          Badge(variant: account.debt? ? :destructive : :default) { account.account_type.titleize }
        end
        CardDescription { account.institution_name || "No institution" }
      end
      CardContent do
        div(class: "text-2xl font-bold") { format_currency(account.balance) }
        if account.interest_rate.present? && account.interest_rate > 0
          p(class: "text-xs text-muted-foreground mt-1") { "#{(account.interest_rate * 100).round(2)}% APR" }
        end
        if account.credit_card? && account.credit_limit.present? && account.credit_limit > 0
          div(class: "mt-2") do
            div(class: "flex justify-between text-xs text-muted-foreground mb-1") do
              span { "Utilization" }
              span { "#{((account.balance / account.credit_limit) * 100).round(0)}%" }
            end
            div(class: "h-2 rounded-full bg-muted overflow-hidden") do
              pct = [(account.balance / account.credit_limit * 100).round(0), 100].min
              div(class: "h-full rounded-full #{pct > 75 ? 'bg-destructive' : 'bg-primary'}", style: "width: #{pct}%")
            end
          end
        end
      end
      CardFooter(class: "pt-2") do
        div(class: "flex gap-2") do
          a(href: helpers.account_path(account), class: "text-sm text-primary hover:underline") { "View" }
          a(href: helpers.edit_account_path(account), class: "text-sm text-muted-foreground hover:underline") { "Edit" }
        end
      end
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
