# frozen_string_literal: true

require "test_helper"

class CsvImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @account = accounts(:chase_checking)
  end

  test "should get new" do
    get new_csv_import_url
    assert_response :success
  end

  test "should show import" do
    import = csv_imports(:completed_import)
    get csv_import_url(import)
    assert_response :success
  end

  test "should create import and redirect to preview" do
    file = Rack::Test::UploadedFile.new(
      StringIO.new("Date,Amount,Description\n2026-02-01,-50.00,Test Payment\n2026-03-01,-50.00,Test Payment\n2026-04-01,-50.00,Test Payment\n"),
      "text/csv",
      original_filename: "test.csv"
    )

    assert_difference("CsvImport.count") do
      post csv_imports_url, params: {
        csv_import: {
          file: file
        }
      }
    end

    import = CsvImport.last
    assert_redirected_to preview_csv_import_path(import)
    assert import.analyzed? || import.failed?
  end

  test "should not create import without file" do
    post csv_imports_url, params: {
      csv_import: { account_id: nil }
    }
    assert_response :unprocessable_entity
  end

  test "should show preview for analyzed import" do
    import = csv_imports(:analyzed_import)
    get preview_csv_import_url(import)
    assert_response :success
  end

  test "should redirect from preview for completed import" do
    import = csv_imports(:completed_import)
    get preview_csv_import_url(import)
    assert_redirected_to csv_import_path(import)
  end

  test "should confirm import and redirect to show" do
    import = csv_imports(:analyzed_import)
    post confirm_csv_import_url(import), params: {
      selections: {
        income: { "0" => "1" },
        bills: { "0" => "1" },
        accounts: { "0" => "1" },
        import_transactions: "1"
      }
    }
    assert_redirected_to csv_import_path(import)
  end
end
