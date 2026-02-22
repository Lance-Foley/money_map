# frozen_string_literal: true

class Views::CsvImports::ShowView < Views::Base
  include Phlex::Rails::Helpers::Routes

  def initialize(import:)
    @import = import
  end

  def view_template
    div(class: "flex flex-1 flex-col gap-6 p-4 max-w-2xl mx-auto") do
      # Breadcrumb
      div(class: "flex items-center gap-2") do
        a(href: helpers.transactions_path, class: "text-sm text-muted-foreground hover:text-foreground transition-colors") { "< Back to Transactions" }
      end

      h1(class: "text-3xl font-bold tracking-tight") { "Import Status" }

      Card do
        CardHeader do
          div(class: "flex items-center justify-between") do
            CardTitle { @import.file_name || "CSV Import" }
            status_badge
          end
          if @import.account
            CardDescription { "Account: #{@import.account.name}" }
          end
        end
        CardContent do
          div(class: "space-y-4") do
            # Status details
            div(class: "grid gap-4 sm:grid-cols-3") do
              stat_item("Status", @import.status.titleize)
              stat_item("Records Imported", @import.records_imported.to_s)
              stat_item("Records Skipped", @import.records_skipped.to_s)
            end

            # Success message for completed imports
            if @import.completed?
              div(class: "pt-4 border-t") do
                div(class: "rounded-lg bg-emerald-50 dark:bg-emerald-950/20 border border-emerald-200 dark:border-emerald-800 p-4") do
                  div(class: "flex gap-3") do
                    div(class: "w-5 h-5 rounded-full bg-emerald-500 flex items-center justify-center shrink-0 mt-0.5") do
                      span(class: "text-white text-xs font-bold") { "!" }
                    end
                    div do
                      p(class: "text-sm font-medium text-emerald-800 dark:text-emerald-200") { "Import completed successfully" }
                      p(class: "text-sm text-emerald-700 dark:text-emerald-300 mt-1") do
                        "#{@import.records_imported} transactions imported. Your action plan has been updated with recurring items."
                      end
                    end
                  end
                end
              end
            end

            # Analyzed state - show preview link
            if @import.analyzed?
              div(class: "pt-4 border-t") do
                div(class: "rounded-lg bg-blue-50 dark:bg-blue-950/20 border border-blue-200 dark:border-blue-800 p-4") do
                  div(class: "flex gap-3 items-center") do
                    div do
                      p(class: "text-sm font-medium text-blue-800 dark:text-blue-200") { "Analysis complete" }
                      p(class: "text-sm text-blue-700 dark:text-blue-300 mt-1") { "Review the preview and confirm your import." }
                    end
                    a(
                      href: helpers.preview_csv_import_path(@import),
                      class: "ml-auto inline-flex items-center rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white shadow hover:bg-blue-700 transition-colors shrink-0"
                    ) { "View Preview" }
                  end
                end
              end
            end

            # Column mapping
            if @import.column_mapping.present? && @import.column_mapping.values.any?(&:present?)
              div(class: "pt-4 border-t") do
                h3(class: "text-sm font-medium mb-2") { "Column Mapping" }
                div(class: "grid gap-2 sm:grid-cols-3") do
                  @import.column_mapping.each do |key, value|
                    next unless value.present?
                    div(class: "text-sm") do
                      span(class: "text-muted-foreground") { "#{key.to_s.titleize}: " }
                      span(class: "font-medium") { value.to_s }
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
              if @import.completed?
                a(href: helpers.transactions_path, class: btn_primary_class) { "View Transactions" }
                a(href: helpers.action_plan_path, class: btn_secondary_class) { "View Action Plan" }
              end
              a(href: helpers.new_csv_import_path, class: btn_secondary_class) { "Import Another" }
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
    when "analyzed" then :secondary
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

  def btn_primary_class
    "inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground shadow hover:bg-primary/90 transition-colors"
  end

  def btn_secondary_class
    "inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium shadow-sm hover:bg-accent transition-colors"
  end
end
