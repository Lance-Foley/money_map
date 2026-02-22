# frozen_string_literal: true

class CsvImportsController < ApplicationController
  def new
    @current_page = "Transactions"
    render Views::CsvImports::NewView.new(accounts: Account.active)
  end

  def create
    @current_page = "Transactions"

    @import = CsvImport.new(
      file_name: params[:csv_import][:file]&.original_filename,
      column_mapping: {}
    )

    # Optional account_id for backwards compatibility
    if params[:csv_import][:account_id].present?
      @import.account_id = params[:csv_import][:account_id]
    end

    @import.file.attach(params[:csv_import][:file]) if params[:csv_import][:file]

    unless @import.file.attached?
      @import.errors.add(:file, "must be attached")
      render Views::CsvImports::NewView.new(accounts: Account.active), status: :unprocessable_entity
      return
    end

    if @import.save
      @import.analyze!
      redirect_to preview_csv_import_path(@import)
    else
      render Views::CsvImports::NewView.new(accounts: Account.active), status: :unprocessable_entity
    end
  end

  def show
    @current_page = "Transactions"
    @import = CsvImport.find(params[:id])
    render Views::CsvImports::ShowView.new(import: @import)
  end

  def preview
    @current_page = "Transactions"
    @import = CsvImport.find(params[:id])

    unless @import.analyzed? || @import.pending?
      redirect_to csv_import_path(@import), alert: "This import has already been processed."
      return
    end

    analysis = @import.parsed_analysis
    unless analysis
      redirect_to csv_import_path(@import), alert: "No analysis results found."
      return
    end

    render Views::CsvImports::PreviewView.new(
      import: @import,
      analysis: analysis,
      categories: BudgetCategory.ordered
    )
  end

  def confirm
    @current_page = "Transactions"
    @import = CsvImport.find(params[:id])

    unless @import.analyzed?
      redirect_to csv_import_path(@import), alert: "This import cannot be confirmed."
      return
    end

    analysis = @import.parsed_analysis
    selections = params[:selections]&.permit!&.to_h || {}

    executor = SmartImportExecutor.new(@import, analysis, selections)
    result = executor.execute!

    if result[:success]
      redirect_to csv_import_path(@import), notice: result[:message]
    else
      redirect_to preview_csv_import_path(@import), alert: result[:message]
    end
  end
end
