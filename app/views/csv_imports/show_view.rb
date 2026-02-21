# frozen_string_literal: true

class Views::CsvImports::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(import:)
    @import = import
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4") do
      # Breadcrumb
      div(class: "flex items-center gap-2") do
        a(href: helpers.transactions_path, class: "text-sm text-muted-foreground hover:text-foreground") { "< Back to Transactions" }
      end

      h1(class: "text-2xl font-bold tracking-tight") { "Import Status" }

      Card(class: "max-w-2xl") do
        CardHeader do
          div(class: "flex items-center justify-between") do
            CardTitle { @import.file_name || "CSV Import" }
            status_badge
          end
          CardDescription { "Account: #{@import.account.name}" }
        end
        CardContent do
          div(class: "space-y-4") do
            # Status details
            div(class: "grid gap-4 sm:grid-cols-3") do
              stat_item("Status", @import.status.titleize)
              stat_item("Records Imported", @import.records_imported.to_s)
              stat_item("Records Skipped", @import.records_skipped.to_s)
            end

            # Column mapping
            if @import.column_mapping.present?
              div(class: "pt-4 border-t") do
                h3(class: "text-sm font-medium mb-2") { "Column Mapping" }
                div(class: "grid gap-2 sm:grid-cols-3") do
                  @import.column_mapping.each do |key, value|
                    div(class: "text-sm") do
                      span(class: "text-muted-foreground") { "#{key.titleize}: " }
                      span(class: "font-medium") { value }
                    end
                  end
                end
              end
            end

            # Error log
            if @import.error_log.present?
              div(class: "pt-4 border-t") do
                h3(class: "text-sm font-medium mb-2 text-destructive") { "Errors" }
                pre(class: "rounded-md bg-muted p-4 text-sm overflow-auto max-h-60") { @import.error_log }
              end
            end

            # Actions
            div(class: "pt-4 border-t flex gap-3") do
              a(href: helpers.transactions_path, class: "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90") { "View Transactions" }
              a(href: helpers.new_csv_import_path, class: "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent") { "Import Another" }
            end
          end
        end
      end
    end
  end

  private

  def status_badge
    variant = case @import.status
    when "completed" then :default
    when "processing" then :secondary
    when "failed" then :destructive
    else :outline
    end
    Badge(variant: variant) { @import.status.titleize }
  end

  def stat_item(label, value)
    div do
      p(class: "text-sm text-muted-foreground") { label }
      p(class: "text-lg font-semibold") { value }
    end
  end
end
