# frozen_string_literal: true

class Views::Settings::IndexView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(user:, categories:)
    @user = user
    @categories = categories
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Page header
      div do
        h1(class: "text-2xl font-bold tracking-tight") { "Settings" }
        p(class: "text-muted-foreground") { "Manage your profile and budget categories." }
      end

      # Profile section
      profile_section

      # Budget categories section
      categories_section
    end
  end

  private

  def profile_section
    Card do
      CardHeader do
        CardTitle { "Profile" }
        CardDescription { "Update your email and password." }
      end
      CardContent do
        form_with(model: @user, url: helpers.update_profile_settings_path, method: :patch, class: "space-y-4") do |f|
          if @user.errors.any?
            div(class: "rounded-lg border border-destructive/20 bg-destructive/5 p-4 text-sm text-destructive") do
              ul(class: "list-disc pl-4 space-y-1") do
                @user.errors.full_messages.each do |msg|
                  li { msg }
                end
              end
            end
          end

          div(class: "space-y-2") do
            label(for: "user_email_address", class: "text-sm font-medium leading-none") { "Email Address" }
            f.email_field :email_address, class: input_class, placeholder: "you@example.com"
          end

          div(class: "grid gap-4 md:grid-cols-2") do
            div(class: "space-y-2") do
              label(for: "user_password", class: "text-sm font-medium leading-none") { "New Password" }
              f.password_field :password, class: input_class, placeholder: "Leave blank to keep current"
            end

            div(class: "space-y-2") do
              label(for: "user_password_confirmation", class: "text-sm font-medium leading-none") { "Confirm Password" }
              f.password_field :password_confirmation, class: input_class, placeholder: "Confirm new password"
            end
          end

          div do
            f.submit "Save Profile", class: btn_primary_class
          end
        end
      end
    end
  end

  def categories_section
    Card do
      CardHeader do
        CardTitle { "Budget Categories" }
        CardDescription { "Customize your budget categories." }
      end
      CardContent do
        div(class: "space-y-3") do
          @categories.each do |category|
            category_row(category)
          end
        end

        # Add new category form
        div(class: "mt-6 pt-6 border-t") do
          h3(class: "text-sm font-medium mb-3") { "Add New Category" }
          form_with(model: BudgetCategory.new, url: helpers.create_category_settings_path, method: :post, class: "flex flex-wrap gap-3 items-end") do |f|
            div(class: "space-y-1 flex-1 min-w-[150px]") do
              label(for: "budget_category_name", class: "text-xs font-medium text-muted-foreground") { "Name" }
              f.text_field :name, class: input_class, placeholder: "Category name", required: true
            end
            div(class: "space-y-1 w-24") do
              label(for: "budget_category_icon", class: "text-xs font-medium text-muted-foreground") { "Icon" }
              f.text_field :icon, class: input_class, placeholder: "e.g. star"
            end
            div(class: "space-y-1 w-24") do
              label(for: "budget_category_color", class: "text-xs font-medium text-muted-foreground") { "Color" }
              f.color_field :color, class: "h-9 w-full rounded-md border border-input cursor-pointer", value: "#6366f1"
            end
            div do
              f.submit "Add", class: btn_primary_class
            end
          end
        end
      end
    end
  end

  def category_row(category)
    div(class: "flex items-center gap-3 py-2 px-3 rounded-lg border bg-card hover:bg-accent/50 transition-colors") do
      # Color indicator
      div(class: "h-4 w-4 rounded-full shrink-0", style: "background-color: #{category.color || '#6366f1'}")

      # Name and icon
      div(class: "flex-1 min-w-0") do
        span(class: "text-sm font-medium") { category.name }
        if category.icon.present?
          span(class: "text-xs text-muted-foreground ml-2") { "(#{category.icon})" }
        end
      end

      # Edit form (inline)
      form_with(model: category, url: helpers.update_category_settings_path(id: category.id), method: :patch, class: "flex items-center gap-2") do |f|
        f.text_field :name, value: category.name, class: "h-7 w-28 rounded border border-input bg-transparent px-2 text-xs hidden md:block", title: "Edit name"
        f.color_field :color, value: category.color || "#6366f1", class: "h-7 w-7 rounded border border-input cursor-pointer hidden md:block", title: "Edit color"
        f.submit "Save", class: "h-7 rounded bg-primary px-2 text-xs font-medium text-primary-foreground hover:bg-primary/90 cursor-pointer hidden md:inline-block"
      end

      # Delete
      form_with(url: helpers.destroy_category_settings_path(id: category.id), method: :delete, class: "inline") do |f|
        f.submit "Remove", class: "h-7 rounded border border-input bg-background px-2 text-xs font-medium text-destructive hover:bg-destructive/10 cursor-pointer", data: { turbo_confirm: "Remove \"#{category.name}\"?" }
      end
    end
  end

  def input_class
    "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
  end

  def btn_primary_class
    "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer"
  end
end
