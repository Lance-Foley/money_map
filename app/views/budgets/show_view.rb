# frozen_string_literal: true

class Views::Budgets::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(period:, categories:, items_by_category:, incomes:)
    @period = period
    @categories = categories
    @items_by_category = items_by_category
    @incomes = incomes
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Header with navigation
      div(class: "flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Budget" }
          p(class: "text-muted-foreground") { @period.display_name }
        end

        div(class: "flex items-center gap-2") do
          a(href: helpers.budget_path(year: prev_year, month: prev_month), class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-3 py-2 text-sm font-medium shadow-sm hover:bg-accent") do
            plain "< Prev"
          end
          span(class: "px-3 py-2 text-sm font-medium") { @period.display_name }
          a(href: helpers.budget_path(year: next_year, month: next_month), class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-3 py-2 text-sm font-medium shadow-sm hover:bg-accent") do
            plain "Next >"
          end
        end
      end

      # Left to budget indicator + copy button
      div(class: "grid gap-4 md:grid-cols-4") do
        left = @period.left_to_budget
        Card(class: left.zero? ? "border-green-500/50" : left.positive? ? "border-yellow-500/50" : "border-destructive/50") do
          CardHeader(class: "pb-2") do
            CardTitle(class: "text-sm font-medium") { "Left to Budget" }
          end
          CardContent do
            div(class: "text-2xl font-bold #{left.zero? ? 'text-green-600 dark:text-green-400' : left.positive? ? 'text-yellow-600 dark:text-yellow-400' : 'text-destructive'}") do
              plain format_currency(left)
            end
          end
        end

        summary_card("Total Income", format_currency(@period.total_income))
        summary_card("Total Planned", format_currency(@period.total_planned))
        summary_card("Total Spent", format_currency(@period.total_spent))
      end

      # Copy previous month button
      div(class: "flex gap-2") do
        form_with(url: helpers.copy_budget_path(year: @period.year, month: @period.month), method: :post, class: "inline") do |f|
          f.submit "Copy Previous Month", class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent cursor-pointer"
        end
      end

      # Income section
      Card do
        CardHeader do
          CardTitle { "Income" }
          CardDescription { "Expected and received income for this period." }
        end
        CardContent do
          if @incomes.any?
            Table do
              TableHeader do
                TableRow do
                  TableHead { "Source" }
                  TableHead { "Expected" }
                  TableHead { "Received" }
                  TableHead { "Frequency" }
                  TableHead { "Pay Date" }
                  TableHead { "Start Date" }
                end
              end
              TableBody do
                @incomes.each do |income|
                  TableRow do
                    TableCell(class: "font-medium") { income.source_name }
                    TableCell { format_currency(income.expected_amount) }
                    TableCell { income.received_amount ? format_currency(income.received_amount) : "-" }
                    TableCell do
                      plain income.frequency.titleize
                      if income.custom? && income.custom_interval_value.present?
                        span(class: "text-xs text-muted-foreground ml-1") do
                          unit = Schedulable::INTERVAL_UNITS[income.custom_interval_unit]
                          plain "(every #{income.custom_interval_value} #{unit})"
                        end
                      end
                    end
                    TableCell { income.pay_date&.strftime("%b %d") || "-" }
                    TableCell { income.start_date&.strftime("%b %d") || "-" }
                  end
                end
              end
            end
          else
            p(class: "text-muted-foreground text-sm") { "No income entries yet." }
          end

          # Add income form
          div(class: "mt-4 pt-4 border-t") do
            income_form
          end
        end
      end

      # Budget categories
      @categories.each do |category|
        items = @items_by_category[category.id] || []
        category_section(category, items)
      end
    end
  end

  private

  def category_section(category, items)
    Card do
      CardHeader do
        div(class: "flex items-center justify-between") do
          div(class: "flex items-center gap-2") do
            if category.color.present?
              div(class: "h-3 w-3 rounded-full", style: "background-color: #{category.color}")
            end
            CardTitle { category.name }
          end
          category_total = items.sum(&:planned_amount)
          span(class: "text-sm text-muted-foreground") { "Planned: #{format_currency(category_total)}" }
        end
      end
      CardContent do
        if items.any?
          div(class: "space-y-3") do
            items.each do |item|
              budget_item_row(item)
            end
          end
        else
          p(class: "text-sm text-muted-foreground") { "No budget items in this category." }
        end

        # Add item form
        div(class: "mt-4 pt-4 border-t") do
          form_with(model: BudgetItem.new, url: helpers.budget_items_path, class: "flex flex-wrap gap-2 items-end") do |f|
            f.hidden_field :budget_period_id, value: @period.id
            f.hidden_field :budget_category_id, value: category.id
            div(class: "flex-1 min-w-[120px]") do
              f.text_field :name, placeholder: "Item name", class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            end
            div(class: "w-32") do
              f.number_field :planned_amount, step: 0.01, placeholder: "Amount", class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            end
            f.submit "+ Add", class: "inline-flex items-center justify-center rounded-md bg-primary px-3 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
          end
        end
      end
    end
  end

  def budget_item_row(item)
    pct = item.percentage_spent
    div(class: "flex flex-col gap-1") do
      div(class: "flex items-center justify-between") do
        div(class: "flex items-center gap-2") do
          span(class: "text-sm font-medium") { item.name }
          if item.rollover?
            Badge(variant: :secondary) { "Sinking Fund" }
          end
        end
        div(class: "flex items-center gap-4 text-sm") do
          span { "#{format_currency(item.spent_amount)} / #{format_currency(item.planned_amount)}" }
          span(class: "w-20 text-right #{item.over_budget? ? 'text-destructive font-medium' : 'text-muted-foreground'}") do
            plain "#{format_currency(item.remaining)} left"
          end
        end
      end
      # Progress bar
      div(class: "h-2 rounded-full bg-muted overflow-hidden") do
        bar_pct = [pct, 100].min
        color = pct > 100 ? "bg-destructive" : pct > 80 ? "bg-yellow-500" : "bg-primary"
        div(class: "h-full rounded-full #{color}", style: "width: #{bar_pct}%")
      end
    end
  end

  def summary_card(title, value)
    Card do
      CardHeader(class: "pb-2") do
        CardTitle(class: "text-sm font-medium") { title }
      end
      CardContent do
        div(class: "text-2xl font-bold") { value }
      end
    end
  end

  def prev_year
    @period.month == 1 ? @period.year - 1 : @period.year
  end

  def prev_month
    @period.month == 1 ? 12 : @period.month - 1
  end

  def next_year
    @period.month == 12 ? @period.year + 1 : @period.year
  end

  def next_month
    @period.month == 12 ? 1 : @period.month + 1
  end

  def income_form
    frequency_options = Income.frequencies.keys.map { |freq| [freq.titleize, freq] }
    interval_unit_options = Schedulable::INTERVAL_UNITS.map { |k, v| [v.to_s.titleize, k] }

    form_with(model: Income.new, url: helpers.incomes_path, class: "space-y-3", data: { controller: "frequency-toggle", action: "change->frequency-toggle#toggle" }) do |f|
      f.hidden_field :budget_period_id, value: @period.id

      div(class: "flex flex-wrap gap-2 items-end") do
        div(class: "flex-1 min-w-[120px]") do
          label(for: "income_source_name", class: "text-xs font-medium text-muted-foreground") { "Source" }
          f.text_field :source_name, placeholder: "Income source", class: input_class
        end
        div(class: "w-28") do
          label(for: "income_expected_amount", class: "text-xs font-medium text-muted-foreground") { "Expected" }
          f.number_field :expected_amount, step: 0.01, placeholder: "Amount", class: input_class
        end
        div(class: "w-36") do
          label(for: "income_frequency", class: "text-xs font-medium text-muted-foreground") { "Frequency" }
          f.select :frequency, frequency_options, { selected: "monthly" }, class: input_class, data: { frequency_select: true }
        end
        div(class: "w-32") do
          label(for: "income_pay_date", class: "text-xs font-medium text-muted-foreground") { "Pay Date" }
          f.date_field :pay_date, class: input_class
        end
        div(class: "w-32") do
          label(for: "income_start_date", class: "text-xs font-medium text-muted-foreground") { "Start Date" }
          f.date_field :start_date, class: input_class
        end
      end

      # Custom interval fields (shown only when "Custom" is selected)
      div(class: "flex flex-wrap gap-2 items-end hidden", data: { frequency_toggle_target: "customFields" }) do
        div(class: "w-28") do
          label(for: "income_custom_interval_value", class: "text-xs font-medium text-muted-foreground") { "Every" }
          f.number_field :custom_interval_value, min: 1, placeholder: "e.g. 6", class: input_class
        end
        div(class: "w-28") do
          label(for: "income_custom_interval_unit", class: "text-xs font-medium text-muted-foreground") { "Unit" }
          f.select :custom_interval_unit, interval_unit_options, {}, class: input_class
        end
      end

      # Recurring checkbox + submit
      div(class: "flex items-center gap-3") do
        div(class: "flex items-center gap-1") do
          f.check_box :recurring, class: "rounded border-input"
          label(for: "income_recurring", class: "text-sm font-medium leading-none") { "Recurring" }
        end
        f.submit "+ Add Income", class: "inline-flex items-center justify-center rounded-md bg-primary px-3 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer h-9"
      end
    end
  end

  def input_class
    "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
  end

  def format_currency(amount)
    "$#{'%.2f' % (amount || 0)}"
  end
end
