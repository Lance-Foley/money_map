# frozen_string_literal: true

class CsvImportsController < ApplicationController
  def new
    @current_page = "Transactions"
    render Views::CsvImports::NewView.new(accounts: Account.active)
  end

  def create
    @current_page = "Transactions"
    @import = CsvImport.new(
      account_id: params[:csv_import][:account_id],
      file_name: params[:csv_import][:file]&.original_filename,
      column_mapping: {
        "date" => params[:csv_import][:date_column].presence || "Date",
        "amount" => params[:csv_import][:amount_column].presence || "Amount",
        "description" => params[:csv_import][:description_column].presence || "Description"
      }
    )
    @import.file.attach(params[:csv_import][:file]) if params[:csv_import][:file]

    if @import.save
      ProcessCsvImportJob.perform_later(@import)
      redirect_to csv_import_path(@import), notice: "Import queued for processing."
    else
      render Views::CsvImports::NewView.new(accounts: Account.active), status: :unprocessable_entity
    end
  end

  def show
    @current_page = "Transactions"
    @import = CsvImport.find(params[:id])
    render Views::CsvImports::ShowView.new(import: @import)
  end
end
