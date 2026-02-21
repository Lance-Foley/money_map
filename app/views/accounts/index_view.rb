# frozen_string_literal: true

class Views::Accounts::IndexView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(accounts:, bank_accounts:, investments:, credit_cards:, loans:, mortgages:, total_assets:, total_liabilities:)
    @accounts = accounts
    @bank_accounts = bank_accounts
    @investments = investments
    @credit_cards = credit_cards
    @loans = loans
    @mortgages = mortgages
    @total_assets = total_assets
    @total_liabilities = total_liabilities
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        h1(class: "text-2xl font-bold tracking-tight") { "Accounts" }
        a(
          href: helpers.new_account_path,
          class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90"
        ) do
          plain "+ Add New Account"
        end
      end

      # ASSETS section
      section(aria: { label: "Assets" }) do
        # Green header bar
        div(class: "flex items-center justify-between rounded-t-lg bg-green-600 px-4 py-3 text-white") do
          div(class: "flex items-center gap-2") do
            svg(xmlns: "http://www.w3.org/2000/svg", class: "h-5 w-5", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", stroke_width: "2", aria: { hidden: "true" }) do |s|
              s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z")
            end
            span(class: "text-sm font-bold uppercase tracking-wider") { "Assets" }
          end
          span(class: "text-lg font-bold") { format_currency(@total_assets) }
        end

        div(class: "rounded-b-lg border border-t-0 border-border bg-card") do
          # Bank Accounts sub-group
          if @bank_accounts.any?
            render_sub_group(
              icon: :bank,
              title: "Bank Accounts",
              subtotal: @bank_accounts.sum(&:balance),
              accounts: @bank_accounts,
              type: :asset
            )
          end

          # Investments sub-group
          if @investments.any?
            render_sub_group(
              icon: :chart,
              title: "Investments",
              subtotal: @investments.sum(&:balance),
              accounts: @investments,
              type: :asset
            )
          end

          if @bank_accounts.empty? && @investments.empty?
            div(class: "flex h-20 items-center justify-center text-sm text-muted-foreground") do
              plain "No asset accounts yet."
            end
          end
        end
      end

      # LIABILITIES section
      section(aria: { label: "Liabilities" }) do
        # Red header bar
        div(class: "flex items-center justify-between rounded-t-lg bg-red-500 px-4 py-3 text-white") do
          div(class: "flex items-center gap-2") do
            svg(xmlns: "http://www.w3.org/2000/svg", class: "h-5 w-5", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", stroke_width: "2", aria: { hidden: "true" }) do |s|
              s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z")
            end
            span(class: "text-sm font-bold uppercase tracking-wider") { "Liabilities" }
          end
          span(class: "text-lg font-bold") { "-#{format_currency(@total_liabilities)}" }
        end

        div(class: "rounded-b-lg border border-t-0 border-border bg-card") do
          # Credit Cards sub-group
          if @credit_cards.any?
            render_sub_group(
              icon: :credit_card,
              title: "Credit Cards",
              subtotal: @credit_cards.sum(&:balance),
              accounts: @credit_cards,
              type: :liability
            )
          end

          # Loans sub-group
          if @loans.any?
            render_sub_group(
              icon: :document,
              title: "Loans",
              subtotal: @loans.sum(&:balance),
              accounts: @loans,
              type: :liability
            )
          end

          # Mortgages sub-group
          if @mortgages.any?
            render_sub_group(
              icon: :home,
              title: "Mortgages",
              subtotal: @mortgages.sum(&:balance),
              accounts: @mortgages,
              type: :liability
            )
          end

          if @credit_cards.empty? && @loans.empty? && @mortgages.empty?
            div(class: "flex h-20 items-center justify-center text-sm text-muted-foreground") do
              plain "No liability accounts yet."
            end
          end
        end
      end

      # Net Worth footer
      div(class: "rounded-lg border border-border bg-card p-4") do
        div(class: "flex items-center justify-between") do
          span(class: "text-lg font-semibold") { "Net Worth" }
          net = @total_assets - @total_liabilities
          color = net >= 0 ? "text-green-600 dark:text-green-400" : "text-red-600 dark:text-red-400"
          span(class: "text-xl font-bold #{color}") { format_currency(net) }
        end
      end
    end
  end

  private

  def render_sub_group(icon:, title:, subtotal:, accounts:, type:)
    div(class: "border-b border-border last:border-b-0") do
      # Sub-header
      div(class: "flex items-center justify-between border-l-4 #{type == :asset ? 'border-l-green-500' : 'border-l-red-400'} bg-muted/50 px-4 py-2.5") do
        div(class: "flex items-center gap-2") do
          render_icon(icon)
          span(class: "text-sm font-semibold") { title }
        end
        span(class: "text-sm font-semibold") { format_currency(subtotal) }
      end

      # Account rows
      accounts.each do |account|
        render_account_row(account, type)
      end
    end
  end

  def render_account_row(account, type)
    div(class: "flex flex-col gap-3 border-b border-border/50 bg-background px-4 py-3 last:border-b-0 sm:flex-row sm:items-center sm:justify-between") do
      # Left: account info
      div(class: "min-w-0 flex-1") do
        p(class: "font-semibold text-foreground") { account.name }
        p(class: "text-sm text-muted-foreground") { account.institution_name || "No institution" }
        p(class: "text-xs text-muted-foreground") { account.account_type.titleize }
      end

      # Middle: metrics grid
      div(class: "flex flex-wrap items-start gap-6") do
        if account.interest_rate.present? && account.interest_rate > 0
          metric_cell("Interest Rate", format_rate(account.interest_rate))
        end

        metric_cell("Current Balance", format_currency(account.balance))

        if account.debt? && account.minimum_payment.present? && account.minimum_payment > 0
          metric_cell("Min. Payment", format_currency(account.minimum_payment))
        end

        if account.credit_card? && account.credit_limit.present? && account.credit_limit > 0
          metric_cell("Credit Limit", format_currency(account.credit_limit))
        end

        if (account.loan? || account.mortgage?) && account.original_balance.present? && account.original_balance > 0
          metric_cell("Original Balance", format_currency(account.original_balance))
        end
      end

      # Right: action links
      div(class: "flex items-center gap-3 self-end sm:self-center") do
        a(href: helpers.account_path(account), class: "text-sm font-medium text-primary hover:underline") { "History" }
        a(href: helpers.edit_account_path(account), class: "text-sm font-medium text-muted-foreground hover:underline") { "Edit" }
      end
    end
  end

  def metric_cell(label, value)
    div(class: "text-right") do
      p(class: "text-xs text-muted-foreground") { label }
      p(class: "text-sm font-semibold") { value }
    end
  end

  def render_icon(icon)
    case icon
    when :bank
      svg(xmlns: "http://www.w3.org/2000/svg", class: "h-4 w-4 text-muted-foreground", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", stroke_width: "2", aria: { hidden: "true" }) do |s|
        s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M3 21h18M3 10h18M5 6l7-3 7 3M4 10v11M20 10v11M8 14v3M12 14v3M16 14v3")
      end
    when :chart
      svg(xmlns: "http://www.w3.org/2000/svg", class: "h-4 w-4 text-muted-foreground", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", stroke_width: "2", aria: { hidden: "true" }) do |s|
        s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M13 7h8m0 0v8m0-8l-8 8-4-4-6 6")
      end
    when :credit_card
      svg(xmlns: "http://www.w3.org/2000/svg", class: "h-4 w-4 text-muted-foreground", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", stroke_width: "2", aria: { hidden: "true" }) do |s|
        s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z")
      end
    when :document
      svg(xmlns: "http://www.w3.org/2000/svg", class: "h-4 w-4 text-muted-foreground", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", stroke_width: "2", aria: { hidden: "true" }) do |s|
        s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z")
      end
    when :home
      svg(xmlns: "http://www.w3.org/2000/svg", class: "h-4 w-4 text-muted-foreground", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor", stroke_width: "2", aria: { hidden: "true" }) do |s|
        s.path(stroke_linecap: "round", stroke_linejoin: "round", d: "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6")
      end
    end
  end

  def format_currency(amount)
    number = amount || 0
    if number >= 1000
      whole, decimal = ("%.2f" % number).split(".")
      whole_with_commas = whole.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
      "$#{whole_with_commas}.#{decimal}"
    else
      "$#{'%.2f' % number}"
    end
  end

  def format_rate(rate)
    "#{'%.2f' % ((rate || 0) * 100)}%"
  end
end
