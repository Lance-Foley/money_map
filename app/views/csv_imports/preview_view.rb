# frozen_string_literal: true

class Views::CsvImports::PreviewView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(import:, analysis:, categories:)
    @import = import
    @analysis = analysis
    @categories = categories
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4 max-w-5xl mx-auto") do
      # Breadcrumb
      div(class: "flex items-center gap-2") do
        a(href: helpers.new_csv_import_path, class: "text-sm text-muted-foreground hover:text-foreground transition-colors") { "< New Import" }
      end

      # Header with summary
      div(class: "space-y-2") do
        h1(class: "text-3xl font-bold tracking-tight") { "Import Preview" }
        p(class: "text-muted-foreground text-base") { "Review what we found in your CSV. Toggle items on or off, then confirm to import." }
      end

      # Summary stats
      render_summary_stats

      form_with(url: helpers.confirm_csv_import_path(@import), method: :post, scope: :selections, class: "space-y-6") do |f|
        # Primary Account
        render_account_section

        # Detected Sub-Accounts
        render_detected_accounts_section

        # Recurring Income
        render_recurring_income_section

        # Recurring Bills
        render_recurring_bills_section

        # Category Mapping
        render_category_mapping_section

        # Budget Suggestions
        render_budget_suggestions_section

        # Transactions preview
        render_transactions_section

        # Confirm button
        div(class: "sticky bottom-4 z-10") do
          Card(class: "border-primary/20 bg-background shadow-lg") do
            CardContent(class: "pt-4 pb-4") do
              div(class: "flex items-center justify-between") do
                div do
                  p(class: "font-semibold") { "Ready to import" }
                  p(class: "text-sm text-muted-foreground") do
                    summary = @analysis[:summary]
                    "#{summary[:total_transactions]} transactions across #{summary[:months_covered]} months"
                  end
                end
                div(class: "flex gap-3") do
                  a(
                    href: helpers.new_csv_import_path,
                    class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2.5 text-sm font-medium shadow-sm hover:bg-accent transition-colors"
                  ) { "Cancel" }
                  f.submit "Confirm Import",
                    class: "inline-flex items-center justify-center rounded-md bg-primary px-6 py-2.5 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer transition-colors"
                end
              end
            end
          end
        end
      end
    end
  end

  private

  def render_summary_stats
    summary = @analysis[:summary]
    div(class: "grid grid-cols-2 md:grid-cols-4 gap-4") do
      stat_card("Transactions", summary[:total_transactions].to_s, "Found in CSV")
      stat_card("Monthly Income", number_to_currency(summary[:monthly_income_avg]), "Average")
      stat_card("Monthly Expenses", number_to_currency(summary[:monthly_expense_avg]), "Average")
      stat_card("Categories", summary[:categories_found].to_s, "Detected")
    end
  end

  def stat_card(title, value, subtitle)
    Card do
      CardContent(class: "pt-4 pb-4") do
        p(class: "text-xs font-medium text-muted-foreground uppercase tracking-wider") { title }
        p(class: "text-2xl font-bold mt-1") { value }
        p(class: "text-xs text-muted-foreground") { subtitle }
      end
    end
  end

  def render_account_section
    account = @analysis[:account]
    return unless account

    Card do
      CardHeader(class: "pb-3") do
        div(class: "flex items-center justify-between") do
          CardTitle(class: "text-lg") { "Primary Account" }
          Badge(variant: :outline) { "Auto-detected" }
        end
      end
      CardContent do
        div(class: "flex items-center gap-4 p-3 rounded-lg bg-muted/50") do
          div(class: "w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0") do
            span(class: "text-primary font-bold text-sm") { (account[:name] || "?")[0..1].upcase }
          end
          div do
            p(class: "font-medium") { account[:name] || "Primary Checking" }
            p(class: "text-sm text-muted-foreground") do
              parts = []
              parts << account[:type].to_s.titleize if account[:type]
              parts << account[:institution] if account[:institution].present?
              parts.join(" - ")
            end
          end
        end
      end
    end
  end

  def render_detected_accounts_section
    accounts = @analysis[:detected_accounts]
    return if accounts.blank?

    Card do
      CardHeader(class: "pb-3") do
        div(class: "flex items-center justify-between") do
          CardTitle(class: "text-lg") { "Detected Accounts" }
          Badge(variant: :secondary) { "#{accounts.size} found" }
        end
        CardDescription { "Other accounts detected from transfers and credit card payments." }
      end
      CardContent do
        div(class: "space-y-2") do
          accounts.each_with_index do |acct, i|
            div(class: "flex items-center gap-3 p-3 rounded-lg border bg-card hover:bg-muted/50 transition-colors") do
              input(
                type: "checkbox",
                name: "selections[accounts][#{i}]",
                value: "1",
                checked: true,
                class: "h-4 w-4 rounded border-input text-primary focus:ring-primary"
              )
              div(class: "w-8 h-8 rounded-full flex items-center justify-center shrink-0 #{account_type_bg(acct[:type])}") do
                span(class: "text-xs font-bold") { account_type_icon(acct[:type]) }
              end
              div(class: "flex-1 min-w-0") do
                p(class: "font-medium text-sm") { acct[:name] }
                p(class: "text-xs text-muted-foreground") { "#{acct[:type].to_s.titleize} - #{acct[:source]}" }
              end
            end
          end
        end
      end
    end
  end

  def render_recurring_income_section
    incomes = @analysis[:recurring_income]
    return if incomes.blank?

    Card do
      CardHeader(class: "pb-3") do
        div(class: "flex items-center justify-between") do
          CardTitle(class: "text-lg") { "Recurring Income" }
          Badge(variant: :default) { "#{incomes.size} sources" }
        end
        CardDescription { "Income sources detected from recurring deposits." }
      end
      CardContent do
        div(class: "space-y-2") do
          incomes.each_with_index do |income, i|
            div(class: "flex items-center gap-3 p-3 rounded-lg border bg-card hover:bg-muted/50 transition-colors") do
              input(
                type: "checkbox",
                name: "selections[income][#{i}]",
                value: "1",
                checked: true,
                class: "h-4 w-4 rounded border-input text-primary focus:ring-primary"
              )
              div(class: "w-8 h-8 rounded-full bg-emerald-500/10 flex items-center justify-center shrink-0") do
                span(class: "text-emerald-600 text-xs font-bold") { "$" }
              end
              div(class: "flex-1 min-w-0") do
                p(class: "font-medium text-sm truncate") { income[:source_name] }
                p(class: "text-xs text-muted-foreground") { income[:frequency].to_s.titleize }
              end
              div(class: "text-right shrink-0") do
                p(class: "font-semibold text-sm text-emerald-600") { "+#{number_to_currency(income[:amount])}" }
                p(class: "text-xs text-muted-foreground") { "per occurrence" }
              end
            end
          end

          # Total
          div(class: "flex justify-between items-center pt-3 border-t mt-3") do
            p(class: "text-sm font-medium text-muted-foreground") { "Estimated monthly income" }
            p(class: "font-bold text-emerald-600") { "+#{number_to_currency(estimated_monthly_income)}" }
          end
        end
      end
    end
  end

  def render_recurring_bills_section
    bills = @analysis[:recurring_bills]
    return if bills.blank?

    Card do
      CardHeader(class: "pb-3") do
        div(class: "flex items-center justify-between") do
          CardTitle(class: "text-lg") { "Recurring Expenses" }
          Badge(variant: :secondary) { "#{bills.size} detected" }
        end
        CardDescription { "Bills and subscriptions detected from recurring charges." }
      end
      CardContent do
        div(class: "space-y-2") do
          bills.sort_by { |b| -(b[:amount] || 0) }.each_with_index do |bill, i|
            div(class: "flex items-center gap-3 p-3 rounded-lg border bg-card hover:bg-muted/50 transition-colors") do
              input(
                type: "checkbox",
                name: "selections[bills][#{i}]",
                value: "1",
                checked: true,
                class: "h-4 w-4 rounded border-input text-primary focus:ring-primary"
              )
              div(class: "w-8 h-8 rounded-full bg-orange-500/10 flex items-center justify-center shrink-0") do
                span(class: "text-orange-600 text-xs font-bold") { bill_icon(bill[:category]) }
              end
              div(class: "flex-1 min-w-0") do
                p(class: "font-medium text-sm truncate") { bill[:name] }
                div(class: "flex gap-2 items-center") do
                  span(class: "text-xs text-muted-foreground") { bill[:frequency].to_s.titleize }
                  if bill[:due_day]
                    span(class: "text-xs text-muted-foreground") { "- Due day #{bill[:due_day]}" }
                  end
                  if bill[:category].present?
                    Badge(variant: :outline, class: "text-[10px] px-1.5 py-0") { bill[:category] }
                  end
                end
              end
              div(class: "text-right shrink-0") do
                p(class: "font-semibold text-sm") { number_to_currency(bill[:amount]) }
              end
            end
          end

          # Total
          total_bills = bills.sum { |b| b[:amount] || 0 }
          div(class: "flex justify-between items-center pt-3 border-t mt-3") do
            p(class: "text-sm font-medium text-muted-foreground") { "Total recurring bills" }
            p(class: "font-bold") { number_to_currency(total_bills) }
          end
        end
      end
    end
  end

  def render_category_mapping_section
    mapping = @analysis[:category_mapping]
    return if mapping.blank?

    Card do
      CardHeader(class: "pb-3") do
        div(class: "flex items-center justify-between") do
          CardTitle(class: "text-lg") { "Category Mapping" }
          Badge(variant: :outline) { "#{mapping.size} categories" }
        end
        CardDescription { "How CSV categories map to your budget categories." }
      end
      CardContent do
        div(class: "grid gap-2") do
          mapping.each do |csv_cat, budget_cat|
            div(class: "flex items-center gap-3 p-2 rounded-lg hover:bg-muted/50 transition-colors") do
              div(class: "flex-1") do
                span(class: "text-sm") { csv_cat }
              end
              span(class: "text-muted-foreground text-sm") { "->" }
              div(class: "flex-1") do
                if budget_cat.present?
                  Badge(variant: :secondary) { budget_cat }
                else
                  span(class: "text-xs text-muted-foreground italic") { "Skipped (income)" }
                end
              end
            end
          end
        end
      end
    end
  end

  def render_budget_suggestions_section
    suggestions = @analysis[:budget_suggestions]
    return if suggestions.blank?

    Card do
      CardHeader(class: "pb-3") do
        div(class: "flex items-center justify-between") do
          CardTitle(class: "text-lg") { "Budget Suggestions" }
          Badge(variant: :outline) { "Based on #{@analysis.dig(:summary, :months_covered)} months of data" }
        end
        CardDescription { "Suggested monthly budget amounts based on your spending patterns." }
      end
      CardContent do
        div(class: "space-y-4") do
          suggestions.first(8).each do |suggestion|
            div(class: "space-y-2") do
              div(class: "flex items-center justify-between") do
                span(class: "text-sm font-medium") { suggestion[:category] }
                span(class: "text-sm font-bold") { "#{number_to_currency(suggestion[:monthly_total])}/mo" }
              end

              # Progress-like bar showing relative spending
              max_total = suggestions.first[:monthly_total].to_f
              width_pct = max_total > 0 ? ((suggestion[:monthly_total].to_f / max_total) * 100).round : 0
              div(class: "h-2 rounded-full bg-muted overflow-hidden") do
                div(class: "h-full rounded-full bg-primary/60", style: "width: #{width_pct}%") {}
              end

              # Top items in this category
              if suggestion[:items]&.any?
                div(class: "pl-4") do
                  suggestion[:items].first(3).each do |item|
                    div(class: "flex justify-between text-xs text-muted-foreground py-0.5") do
                      span { item[:name] }
                      span { "#{number_to_currency(item[:amount])}/mo" }
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def render_transactions_section
    transactions = @analysis[:transactions]
    return if transactions.blank?

    Card do
      CardHeader(class: "pb-3") do
        div(class: "flex items-center justify-between") do
          CardTitle(class: "text-lg") { "Transaction Preview" }
          Badge(variant: :outline) { "#{transactions.size} total" }
        end
        CardDescription { "Sample of transactions that will be imported." }
      end
      CardContent do
        div(class: "space-y-1") do
          input(
            type: "hidden",
            name: "selections[import_transactions]",
            value: "1"
          )

          # Show first 15 transactions
          transactions.last(15).reverse.each do |txn|
            div(class: "flex items-center gap-3 py-2 border-b border-border/50 last:border-0") do
              div(class: "w-2 h-2 rounded-full shrink-0 #{txn_type_color(txn[:transaction_type])}") {}
              div(class: "flex-1 min-w-0") do
                p(class: "text-sm truncate") { txn[:description] }
                p(class: "text-xs text-muted-foreground") { txn[:date].to_s }
              end
              if txn[:mapped_category].present?
                Badge(variant: :outline, class: "text-[10px] shrink-0") { txn[:mapped_category] }
              end
              div(class: "text-right shrink-0 min-w-[80px]") do
                amount = txn[:amount].to_f
                color_class = amount >= 0 ? "text-emerald-600" : ""
                p(class: "text-sm font-medium #{color_class}") do
                  amount >= 0 ? "+#{number_to_currency(amount.abs)}" : "-#{number_to_currency(amount.abs)}"
                end
              end
            end
          end

          if transactions.size > 15
            div(class: "text-center pt-3") do
              p(class: "text-sm text-muted-foreground") { "...and #{transactions.size - 15} more transactions" }
            end
          end
        end
      end
    end
  end

  # --- Helpers ---

  def number_to_currency(amount)
    return "$0.00" unless amount
    "$#{'%.2f' % amount.to_f.abs}"
  end

  def estimated_monthly_income
    incomes = @analysis[:recurring_income] || []
    incomes.sum do |i|
      case i[:frequency]&.to_sym
      when :weekly then (i[:amount] || 0) * 4.33
      when :biweekly then (i[:amount] || 0) * 2.17
      when :monthly then (i[:amount] || 0)
      else (i[:amount] || 0)
      end
    end.round(2)
  end

  def account_type_bg(type)
    case type&.to_sym
    when :credit_card then "bg-red-500/10"
    when :savings then "bg-emerald-500/10"
    when :checking then "bg-blue-500/10"
    else "bg-muted"
    end
  end

  def account_type_icon(type)
    case type&.to_sym
    when :credit_card then "CC"
    when :savings then "SV"
    when :checking then "CK"
    else "??"
    end
  end

  def bill_icon(category)
    case category
    when "Housing" then "H"
    when "Utilities" then "U"
    when "Insurance" then "I"
    when "Debt" then "D"
    else "B"
    end
  end

  def txn_type_color(type)
    case type&.to_sym
    when :income then "bg-emerald-500"
    when :transfer then "bg-blue-500"
    when :expense then "bg-orange-500"
    else "bg-muted-foreground"
    end
  end
end
