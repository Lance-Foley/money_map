require "test_helper"

class ProcessCsvImportJobTest < ActiveJob::TestCase
  test "job enqueues successfully" do
    import = csv_imports(:pending_import)
    assert_enqueued_with(job: ProcessCsvImportJob) do
      ProcessCsvImportJob.perform_later(import)
    end
  end

  test "job calls process! on csv_import" do
    import = CsvImport.create!(account: accounts(:chase_checking), file_name: "test.csv")
    csv_content = "Date,Amount,Description\n2026-02-01,-50.00,Grocery Store\n"
    import.file.attach(
      io: StringIO.new(csv_content),
      filename: "test.csv",
      content_type: "text/csv"
    )

    assert_difference "Transaction.count", 1 do
      ProcessCsvImportJob.perform_now(import)
    end

    import.reload
    assert import.completed?
  end
end
