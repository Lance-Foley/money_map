# frozen_string_literal: true

require "test_helper"

class SmartImportFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @csv_content = File.read(Rails.root.join("test/fixtures/files/sample_bank_transactions.csv"))
  end

  test "full smart import flow: upload -> preview -> confirm" do
    # Step 1: Visit new import page
    get new_csv_import_path
    assert_response :success

    # Step 2: Upload CSV
    file = Rack::Test::UploadedFile.new(
      StringIO.new(@csv_content),
      "text/csv",
      original_filename: "betterment_transactions.csv"
    )

    assert_difference("CsvImport.count") do
      post csv_imports_path, params: { csv_import: { file: file } }
    end

    import = CsvImport.last
    assert import.analyzed?, "Import should be in analyzed state, was: #{import.status}"
    assert_redirected_to preview_csv_import_path(import)

    # Step 3: View preview
    get preview_csv_import_path(import)
    assert_response :success

    # Step 4: Confirm import with all selections
    initial_transaction_count = Transaction.count
    initial_account_count = Account.count

    post confirm_csv_import_path(import), params: {
      selections: {
        accounts: { "0" => "1", "1" => "1", "2" => "1", "3" => "1" },
        income: { "0" => "1", "1" => "1", "2" => "1" },
        bills: { "0" => "1", "1" => "1", "2" => "1" },
        import_transactions: "1"
      }
    }

    assert_redirected_to csv_import_path(import)
    follow_redirect!
    assert_response :success

    # Verify data was created
    import.reload
    assert import.completed?, "Import should be completed, was: #{import.status}"
    assert import.records_imported > 50, "Should import 50+ transactions, got: #{import.records_imported}"

    # Verify accounts created
    assert Account.count > initial_account_count, "Should create new accounts"
    assert Account.exists?(name: "Emergency Fund"), "Should create Emergency Fund account"

    # Verify transactions created
    assert Transaction.count > initial_transaction_count, "Should create transactions"

    # Verify recurring transactions created (expenses)
    assert RecurringTransaction.expenses.exists?(name: "Netflix Subscription"), "Should create Netflix recurring expense"

    # Verify action plan was generated (future periods exist)
    future = Date.current.beginning_of_month.next_month
    assert BudgetPeriod.exists?(year: future.year, month: future.month), "Should generate future budget periods"
  end

  test "upload without file shows error" do
    post csv_imports_path, params: { csv_import: { account_id: nil } }
    assert_response :unprocessable_entity
  end

  test "preview redirects for completed import" do
    import = csv_imports(:completed_import)
    get preview_csv_import_path(import)
    assert_redirected_to csv_import_path(import)
  end

  test "confirm redirects for non-analyzed import" do
    import = csv_imports(:completed_import)
    post confirm_csv_import_path(import)
    assert_redirected_to csv_import_path(import)
  end

  test "show page displays completed import with action links" do
    import = csv_imports(:completed_import)
    get csv_import_path(import)
    assert_response :success
  end

  test "show page displays analyzed import with preview link" do
    import = csv_imports(:analyzed_import)
    get csv_import_path(import)
    assert_response :success
  end
end
