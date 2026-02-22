# frozen_string_literal: true

class Views::CsvImports::NewView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(accounts:)
    @accounts = accounts
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-8 p-4 max-w-2xl mx-auto") do
      # Breadcrumb
      div(class: "flex items-center gap-2") do
        a(href: helpers.transactions_path, class: "text-sm text-muted-foreground hover:text-foreground transition-colors") { "< Back to Transactions" }
      end

      # Header
      div(class: "space-y-2") do
        h1(class: "text-3xl font-bold tracking-tight") { "Smart Import" }
        p(class: "text-muted-foreground text-base") do
          "Upload your bank statement CSV and we'll automatically detect your accounts, income, bills, and spending categories."
        end
      end

      Card do
        CardContent(class: "pt-6") do
          form_with(url: helpers.csv_imports_path, scope: :csv_import, multipart: true, class: "space-y-6") do |f|
            # File upload - hero area
            div(class: "border-2 border-dashed border-muted-foreground/25 rounded-lg p-8 text-center hover:border-primary/50 transition-colors") do
              div(class: "space-y-3") do
                # Upload icon
                div(class: "mx-auto w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center") do
                  svg(
                    xmlns: "http://www.w3.org/2000/svg",
                    class: "h-6 w-6 text-primary",
                    fill: "none",
                    viewBox: "0 0 24 24",
                    stroke: "currentColor",
                    stroke_width: "2"
                  ) do |s|
                    s.path(
                      stroke_linecap: "round",
                      stroke_linejoin: "round",
                      d: "M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
                    )
                  end
                end

                div do
                  label(for: "csv_import_file", class: "text-sm font-semibold text-primary cursor-pointer hover:underline") { "Choose a CSV file" }
                  span(class: "text-sm text-muted-foreground") { " or drag and drop" }
                end

                p(class: "text-xs text-muted-foreground") { "Supports bank exports from Betterment, Chase, Wells Fargo, and most banks" }

                f.file_field :file, accept: ".csv", class: "sr-only", id: "csv_import_file"
              end
            end

            # File name display
            div(class: "text-sm text-muted-foreground", id: "file-display", data: { controller: "file-upload" }) do
              # JavaScript will show selected filename
            end

            # Optional: specify account
            div(class: "space-y-2") do
              label(for: "csv_import_account_id", class: "text-sm font-medium leading-none") do
                plain "Link to existing account "
                span(class: "text-muted-foreground font-normal") { "(optional)" }
              end
              f.select :account_id,
                @accounts.map { |a| [a.name, a.id] },
                { prompt: "Auto-detect from CSV..." },
                class: input_class
              p(class: "text-xs text-muted-foreground") { "Leave blank to let Smart Import create the account for you." }
            end

            Separator()

            # What Smart Import does
            div(class: "space-y-3") do
              h3(class: "text-sm font-semibold uppercase tracking-wider text-muted-foreground") { "What Smart Import detects" }
              div(class: "grid grid-cols-2 gap-3") do
                feature_item("Recurring Income", "Paychecks, rent deposits, freelance payments")
                feature_item("Recurring Bills", "Subscriptions, utilities, mortgage payments")
                feature_item("Other Accounts", "Savings, credit cards from transfers")
                feature_item("Budget Categories", "Auto-maps spending to your budget")
              end
            end

            # Submit
            div(class: "flex gap-3 pt-2") do
              f.submit "Analyze & Preview",
                class: "inline-flex items-center justify-center rounded-md bg-primary px-6 py-2.5 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer transition-colors"
              a(
                href: helpers.transactions_path,
                class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2.5 text-sm font-medium shadow-sm hover:bg-accent transition-colors"
              ) { "Cancel" }
            end
          end
        end
      end
    end
  end

  private

  def feature_item(title, description)
    div(class: "flex gap-3 items-start p-3 rounded-lg bg-muted/50") do
      div(class: "w-1.5 h-1.5 rounded-full bg-primary mt-2 shrink-0") {}
      div do
        p(class: "text-sm font-medium") { title }
        p(class: "text-xs text-muted-foreground") { description }
      end
    end
  end

  def input_class
    "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
  end
end
