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

  test "should create import with valid params" do
    file = Rack::Test::UploadedFile.new(
      StringIO.new("Date,Amount,Description\n2026-02-01,50.00,Test"),
      "text/csv",
      original_filename: "test.csv"
    )

    assert_difference("CsvImport.count") do
      post csv_imports_url, params: {
        csv_import: {
          account_id: @account.id,
          file: file,
          date_column: "Date",
          amount_column: "Amount",
          description_column: "Description"
        }
      }
    end
    assert_redirected_to csv_import_path(CsvImport.last)
  end

  test "should not create import without account" do
    post csv_imports_url, params: {
      csv_import: { account_id: nil }
    }
    assert_response :unprocessable_entity
  end
end
