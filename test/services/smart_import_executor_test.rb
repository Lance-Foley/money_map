# frozen_string_literal: true

require "test_helper"

class SmartImportExecutorTest < ActiveSupport::TestCase
  setup do
    @csv_content = File.read(Rails.root.join("test/fixtures/files/sample_bank_transactions.csv"))
    @analyzer = SmartImportAnalyzer.new(@csv_content, account_name: "Betterment Checking", institution_name: "Betterment")
    @analysis = @analyzer.analyze

    @import = CsvImport.create!(file_name: "test.csv")
    @import.file.attach(
      io: StringIO.new(@csv_content),
      filename: "test.csv",
      content_type: "text/csv"
    )
    @import.update!(status: :analyzed, analysis_results: serialize_for_storage(@analysis))
  end

  test "creates primary account when none linked" do
    selections = { import_transactions: "1" }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)

    initial_count = Account.count
    executor.execute!

    assert Account.count > initial_count
    assert Account.exists?(name: "Betterment Checking")
  end

  test "uses existing account when linked" do
    existing = accounts(:chase_checking)
    @import.update!(account: existing)

    selections = { import_transactions: "1" }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)
    result = executor.execute!

    assert result[:success]
    @import.reload
    assert_equal existing.id, @import.account_id
  end

  test "creates detected accounts" do
    selections = {
      accounts: { "0" => "1", "1" => "1", "2" => "1", "3" => "1" },
      import_transactions: "1"
    }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)

    initial_count = Account.count
    executor.execute!

    assert Account.count >= initial_count + 3, "Should create at least 3 new accounts"
    assert Account.exists?(name: "Emergency Fund")
  end

  test "skips unchecked accounts" do
    selections = {
      accounts: { "0" => "0" },
      import_transactions: "1"
    }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)
    executor.execute!

    # Primary account still created, but selected ones were skipped
    assert Account.exists?(name: "Betterment Checking")
  end

  test "creates recurring income as RecurringTransaction" do
    selections = {
      income: { "0" => "1", "1" => "1", "2" => "1" },
      import_transactions: "1"
    }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)

    initial_count = RecurringTransaction.incomes_only.count
    executor.execute!

    assert RecurringTransaction.incomes_only.count > initial_count, "Should create new recurring income transactions"
  end

  test "creates recurring bills as RecurringTransaction expenses" do
    selections = {
      bills: { "0" => "1", "1" => "1", "2" => "1", "3" => "1" },
      import_transactions: "1"
    }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)

    initial_count = RecurringTransaction.expenses.count
    executor.execute!

    assert RecurringTransaction.expenses.count > initial_count, "Should create new recurring expense transactions"
  end

  test "imports transactions" do
    selections = { import_transactions: "1" }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)

    initial_count = Transaction.count
    executor.execute!

    assert Transaction.count >= initial_count + 50, "Should import 50+ transactions"
  end

  test "skips transactions when not selected" do
    selections = { import_transactions: "0" }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)

    assert_no_difference("Transaction.count") do
      executor.execute!
    end
  end

  test "creates budget items from suggestions" do
    selections = { import_transactions: "1" }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)

    initial_count = BudgetItem.count
    executor.execute!

    assert BudgetItem.count > initial_count, "Should create new budget items"
  end

  test "marks import as completed on success" do
    selections = { import_transactions: "1" }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)
    result = executor.execute!

    assert result[:success]
    @import.reload
    assert @import.completed?
    assert @import.records_imported > 0
  end

  test "returns success message with counts" do
    selections = { import_transactions: "1" }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)
    result = executor.execute!

    assert result[:success]
    assert result[:message].include?("Imported")
    assert result[:message].include?("transactions")
  end

  test "runs ActionPlanGenerator after import" do
    selections = { import_transactions: "1" }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)
    executor.execute!

    future_month = Date.current.beginning_of_month.next_month
    assert BudgetPeriod.exists?(year: future_month.year, month: future_month.month)
  end

  test "does not create duplicate accounts" do
    Account.create!(name: "Emergency Fund", account_type: :savings, balance: 0)

    selections = {
      accounts: { "0" => "1", "1" => "1", "2" => "1", "3" => "1" },
      import_transactions: "1"
    }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)
    executor.execute!

    assert_equal 1, Account.where(name: "Emergency Fund").count
  end

  test "does not create duplicate recurring transactions" do
    RecurringTransaction.create!(
      name: "AT&T Wireless",
      amount: 52.00,
      frequency: :monthly,
      due_day: 12,
      start_date: Date.current,
      direction: :expense
    )

    selections = { import_transactions: "1" }
    executor = SmartImportExecutor.new(@import, @import.parsed_analysis, selections)
    executor.execute!
  end

  private

  def serialize_for_storage(results)
    serializable = results.deep_dup
    serializable[:transactions] = results[:transactions]&.map do |t|
      t.merge(date: t[:date].to_s)
    end
    if serializable.dig(:summary, :date_range)
      serializable[:summary][:date_range][:start] = serializable[:summary][:date_range][:start].to_s
      serializable[:summary][:date_range][:end] = serializable[:summary][:date_range][:end].to_s
    end
    serializable[:recurring_income]&.each { |r| r[:start_date] = r[:start_date].to_s if r[:start_date] }
    serializable
  end
end
