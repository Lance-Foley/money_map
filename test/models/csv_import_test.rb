require "test_helper"

class CsvImportTest < ActiveSupport::TestCase
  test "valid csv import" do
    import = CsvImport.new(account: accounts(:chase_checking))
    assert import.valid?
  end

  test "account is optional" do
    import = CsvImport.new
    assert import.valid?
  end

  test "status defaults to pending" do
    import = CsvImport.create!(account: accounts(:chase_checking))
    assert import.pending?
  end

  test "records_imported defaults to 0" do
    import = CsvImport.create!(account: accounts(:chase_checking))
    assert_equal 0, import.records_imported
  end

  test "records_skipped defaults to 0" do
    import = CsvImport.create!(account: accounts(:chase_checking))
    assert_equal 0, import.records_skipped
  end

  test "enum values are correct" do
    assert_equal "pending", CsvImport.new(status: 0).status
    assert_equal "processing", CsvImport.new(status: 1).status
    assert_equal "completed", CsvImport.new(status: 2).status
    assert_equal "failed", CsvImport.new(status: 3).status
    assert_equal "analyzed", CsvImport.new(status: 4).status
  end

  test "process! imports valid CSV data" do
    import = CsvImport.create!(account: accounts(:chase_checking), file_name: "test.csv")

    csv_content = "Date,Amount,Description\n2026-02-01,-50.00,Grocery Store\n2026-02-02,1500.00,Paycheck\n"
    import.file.attach(
      io: StringIO.new(csv_content),
      filename: "test.csv",
      content_type: "text/csv"
    )

    assert_difference "Transaction.count", 2 do
      import.process!
    end

    import.reload
    assert import.completed?
    assert_equal 2, import.records_imported
    assert_equal 0, import.records_skipped
  end

  test "process! handles invalid rows gracefully" do
    import = CsvImport.create!(account: accounts(:chase_checking), file_name: "test.csv")

    csv_content = "Date,Amount,Description\ninvalid-date,-50.00,Grocery Store\n2026-02-02,1500.00,Paycheck\n"
    import.file.attach(
      io: StringIO.new(csv_content),
      filename: "test.csv",
      content_type: "text/csv"
    )

    import.process!
    import.reload

    assert import.completed?
    assert_equal 1, import.records_imported
    assert_equal 1, import.records_skipped
    assert_not_nil import.error_log
  end
end
