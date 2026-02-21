# frozen_string_literal: true

class Views::SavingsGoals::FormView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(goal:)
    @goal = goal
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Breadcrumb
      div(class: "flex items-center gap-2") do
        a(href: helpers.savings_goals_path, class: "text-sm text-muted-foreground hover:text-foreground") { "< Back to Savings Goals" }
      end

      h1(class: "text-2xl font-bold tracking-tight") do
        plain @goal.persisted? ? "Edit Savings Goal" : "New Savings Goal"
      end

      Card(class: "max-w-2xl") do
        CardContent(class: "pt-6") do
          form_with(model: @goal, class: "space-y-6") do |f|
            # Errors
            if @goal.errors.any?
              div(class: "rounded-lg border border-destructive/20 bg-destructive/5 p-4 text-sm text-destructive") do
                ul(class: "list-disc pl-4 space-y-1") do
                  @goal.errors.full_messages.each do |msg|
                    li { msg }
                  end
                end
              end
            end

            # Name
            div(class: "space-y-2") do
              label(for: "savings_goal_name", class: "text-sm font-medium leading-none") { "Goal Name" }
              f.text_field :name, class: input_class, placeholder: "e.g. Emergency Fund"
            end

            # Category
            div(class: "space-y-2") do
              label(for: "savings_goal_category", class: "text-sm font-medium leading-none") { "Category" }
              f.select :category, SavingsGoal.categories.keys.map { |c| [c.titleize, c] }, { prompt: "Select category..." }, class: input_class
            end

            # Target amount
            div(class: "space-y-2") do
              label(for: "savings_goal_target_amount", class: "text-sm font-medium leading-none") { "Target Amount" }
              f.number_field :target_amount, step: 0.01, class: input_class, placeholder: "0.00"
            end

            # Current amount
            div(class: "space-y-2") do
              label(for: "savings_goal_current_amount", class: "text-sm font-medium leading-none") { "Current Amount" }
              f.number_field :current_amount, step: 0.01, class: input_class, placeholder: "0.00"
            end

            # Target date
            div(class: "space-y-2") do
              label(for: "savings_goal_target_date", class: "text-sm font-medium leading-none") { "Target Date" }
              f.date_field :target_date, class: input_class
            end

            # Priority
            div(class: "space-y-2") do
              label(for: "savings_goal_priority", class: "text-sm font-medium leading-none") { "Priority (1 = highest)" }
              f.number_field :priority, step: 1, min: 1, class: input_class, placeholder: "1"
            end

            # Submit
            div(class: "flex gap-3") do
              f.submit(@goal.persisted? ? "Update Goal" : "Create Goal", class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer")
              a(href: helpers.savings_goals_path, class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent") { "Cancel" }
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
end
