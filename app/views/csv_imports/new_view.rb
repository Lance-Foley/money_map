# frozen_string_literal: true

class Views::CsvImports::NewView < Views::Base
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith

  def initialize(accounts:)
    @accounts = accounts
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Breadcrumb
      div(class: "flex items-center gap-2") do
        a(href: helpers.transactions_path, class: "text-sm text-muted-foreground hover:text-foreground") { "< Back to Transactions" }
      end

      h1(class: "text-2xl font-bold tracking-tight") { "Import Transactions from CSV" }
      p(class: "text-muted-foreground") { "Upload a CSV file to import transactions into an account." }

      Card(class: "max-w-2xl") do
        CardContent(class: "pt-6") do
          form_with(url: helpers.csv_imports_path, scope: :csv_import, multipart: true, class: "space-y-6") do |f|
            # Account
            div(class: "space-y-2") do
              label(for: "csv_import_account_id", class: "text-sm font-medium leading-none") { "Account" }
              f.select :account_id, @accounts.map { |a| [a.name, a.id] }, { prompt: "Select account..." }, class: input_class
            end

            # File upload
            div(class: "space-y-2") do
              label(for: "csv_import_file", class: "text-sm font-medium leading-none") { "CSV File" }
              f.file_field :file, accept: ".csv", class: "flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm file:border-0 file:bg-transparent file:text-sm file:font-medium"
            end

            Separator()

            # Column mapping
            h3(class: "text-lg font-medium") { "Column Mapping" }
            p(class: "text-sm text-muted-foreground") { "Specify the column names in your CSV file. Leave blank for defaults (Date, Amount, Description)." }

            div(class: "grid gap-4 sm:grid-cols-3") do
              div(class: "space-y-2") do
                label(for: "csv_import_date_column", class: "text-sm font-medium leading-none") { "Date Column" }
                f.text_field :date_column, placeholder: "Date", class: input_class
              end
              div(class: "space-y-2") do
                label(for: "csv_import_amount_column", class: "text-sm font-medium leading-none") { "Amount Column" }
                f.text_field :amount_column, placeholder: "Amount", class: input_class
              end
              div(class: "space-y-2") do
                label(for: "csv_import_description_column", class: "text-sm font-medium leading-none") { "Description Column" }
                f.text_field :description_column, placeholder: "Description", class: input_class
              end
            end

            # Submit
            div(class: "flex gap-3") do
              f.submit "Upload & Import", class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 cursor-pointer"
              a(href: helpers.transactions_path, class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent") { "Cancel" }
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
