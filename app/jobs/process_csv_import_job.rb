class ProcessCsvImportJob < ApplicationJob
  queue_as :default

  def perform(csv_import)
    csv_import.process!
  end
end
