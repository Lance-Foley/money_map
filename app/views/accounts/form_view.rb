# frozen_string_literal: true

class Views::Accounts::FormView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(account:)
    @account = account
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Breadcrumb
      div(class: "flex items-center gap-2") do
        a(href: helpers.accounts_path, class: "text-sm text-muted-foreground hover:text-foreground") { "< Back to Accounts" }
      end

      # Page header
      h1(class: "text-2xl font-bold tracking-tight") do
        plain @account.persisted? ? "Edit Account" : "New Account"
      end

      Card(class: "max-w-2xl") do
        CardContent(class: "pt-6") do
          form_with(model: @account, class: "space-y-6") do |f|
            # Errors
            if @account.errors.any?
              div(class: "rounded-lg border border-destructive/20 bg-destructive/5 p-4 text-sm text-destructive") do
                ul(class: "list-disc pl-4 space-y-1") do
                  @account.errors.full_messages.each do |msg|
                    li { msg }
                  end
                end
              end
            end

            # Name
            div(class: "space-y-2") do
              label(for: "account_name", class: "text-sm font-medium leading-none") { "Account Name" }
              f.text_field :name, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring", placeholder: "e.g. Chase Checking"
            end

            # Account type
            div(class: "space-y-2") do
              label(for: "account_account_type", class: "text-sm font-medium leading-none") { "Account Type" }
              f.select :account_type, Account.account_types.keys.map { |t| [t.titleize, t] }, { prompt: "Select type..." }, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
            end

            # Institution name
            div(class: "space-y-2") do
              label(for: "account_institution_name", class: "text-sm font-medium leading-none") { "Institution" }
              f.text_field :institution_name, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring", placeholder: "e.g. Chase Bank"
            end

            # Balance
            div(class: "space-y-2") do
              label(for: "account_balance", class: "text-sm font-medium leading-none") { "Current Balance" }
              f.number_field :balance, step: 0.01, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring", placeholder: "0.00"
            end

            # Interest rate
            div(class: "space-y-2") do
              label(for: "account_interest_rate", class: "text-sm font-medium leading-none") { "Interest Rate (decimal, e.g. 0.1999 for 19.99%)" }
              f.number_field :interest_rate, step: 0.0001, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring", placeholder: "0.0000"
            end

            # Minimum payment
            div(class: "space-y-2") do
              label(for: "account_minimum_payment", class: "text-sm font-medium leading-none") { "Minimum Payment" }
              f.number_field :minimum_payment, step: 0.01, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring", placeholder: "0.00"
            end

            # Credit limit
            div(class: "space-y-2") do
              label(for: "account_credit_limit", class: "text-sm font-medium leading-none") { "Credit Limit" }
              f.number_field :credit_limit, step: 0.01, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring", placeholder: "0.00"
            end

            # Original balance
            div(class: "space-y-2") do
              label(for: "account_original_balance", class: "text-sm font-medium leading-none") { "Original Balance" }
              f.number_field :original_balance, step: 0.01, class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring", placeholder: "0.00"
            end

            # Submit
            div(class: "flex gap-3") do
              f.submit(@account.persisted? ? "Update Account" : "Create Account", class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer")
              a(href: helpers.accounts_path, class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent") { "Cancel" }
            end
          end
        end
      end
    end
  end
end
