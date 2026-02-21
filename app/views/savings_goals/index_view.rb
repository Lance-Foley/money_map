# frozen_string_literal: true

class Views::SavingsGoals::IndexView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(goals:)
    @goals = goals
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "text-2xl font-bold tracking-tight") { "Savings Goals" }
          p(class: "text-muted-foreground") { "Track progress toward your financial goals." }
        end
        a(href: helpers.new_savings_goal_path, class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90") do
          plain "+ New Goal"
        end
      end

      # Summary
      div(class: "grid gap-4 md:grid-cols-3") do
        summary_card("Total Saved", format_currency(@goals.sum(&:current_amount)), "Across all goals")
        summary_card("Total Target", format_currency(@goals.sum(&:target_amount)), "Combined goal targets")
        active = @goals.reject(&:completed?)
        summary_card("Active Goals", active.size.to_s, "#{@goals.select(&:completed?).size} completed")
      end

      # Goals grouped by category
      categories = {
        "Emergency Fund" => @goals.select(&:emergency_fund?),
        "Sinking Funds" => @goals.select(&:sinking_fund?),
        "General Goals" => @goals.select(&:general?)
      }

      categories.each do |category_name, category_goals|
        next if category_goals.empty?
        div(class: "space-y-3") do
          h2(class: "text-lg font-semibold") { category_name }
          div(class: "grid gap-4 md:grid-cols-2 lg:grid-cols-3") do
            category_goals.each do |goal|
              goal_card(goal)
            end
          end
        end
      end

      if @goals.empty?
        Card do
          CardContent(class: "pt-6") do
            div(class: "flex h-[100px] items-center justify-center text-muted-foreground") do
              plain "No savings goals yet. Create one to start tracking your progress."
            end
          end
        end
      end
    end
  end

  private

  def goal_card(goal)
    Card(class: goal.completed? ? "border-green-500/50" : "") do
      CardHeader(class: "pb-2") do
        div(class: "flex items-center justify-between") do
          CardTitle(class: "text-base") { goal.name }
          if goal.completed?
            Badge(variant: :default) { "Completed" }
          else
            Badge(variant: :secondary) { goal.category.titleize }
          end
        end
        if goal.target_date
          CardDescription { "Target: #{goal.target_date.strftime('%b %d, %Y')}" }
        end
      end
      CardContent do
        div(class: "space-y-3") do
          # Progress
          div(class: "flex justify-between text-sm") do
            span { format_currency(goal.current_amount) }
            span(class: "text-muted-foreground") { "of #{format_currency(goal.target_amount)}" }
          end
          div(class: "h-3 rounded-full bg-muted overflow-hidden") do
            pct = goal.progress_percentage
            div(class: "h-full rounded-full #{pct >= 100 ? 'bg-green-500' : 'bg-primary'}", style: "width: #{[pct, 100].min}%")
          end
          div(class: "flex justify-between text-xs text-muted-foreground") do
            span { "#{goal.progress_percentage}% complete" }
            span { "#{format_currency(goal.remaining)} remaining" }
          end
        end
      end
      CardFooter(class: "pt-2") do
        div(class: "flex gap-2") do
          a(href: helpers.edit_savings_goal_path(goal), class: "text-sm text-primary hover:underline") { "Edit" }
          a(href: helpers.savings_goal_path(goal), data: { turbo_method: :delete, turbo_confirm: "Delete this goal?" }, class: "text-sm text-destructive hover:underline") { "Delete" }
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
