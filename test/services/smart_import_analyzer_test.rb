# frozen_string_literal: true

require "test_helper"

class SmartImportAnalyzerTest < ActiveSupport::TestCase
  setup do
    @csv_content = File.read(Rails.root.join("test/fixtures/files/sample_bank_transactions.csv"))
    @analyzer = SmartImportAnalyzer.new(@csv_content, account_name: "Betterment Checking", institution_name: "Betterment")
    @results = @analyzer.analyze
  end

  # --- Column Detection ---

  test "detects date column" do
    assert_equal "Settled Date", @results[:detected_columns][:date]
  end

  test "detects amount column" do
    assert_equal "Amount", @results[:detected_columns][:amount]
  end

  test "detects description column" do
    assert_equal "Description", @results[:detected_columns][:description]
  end

  test "detects category column" do
    assert_equal "Category", @results[:detected_columns][:category]
  end

  test "handles CSV with non-standard column names" do
    csv = "Trans Date,Total,Memo,Type\n2026-01-01,50.00,Test Payment,Shopping\n"
    analyzer = SmartImportAnalyzer.new(csv)
    results = analyzer.analyze
    assert_equal "Trans Date", results[:detected_columns][:date]
    assert_equal "Total", results[:detected_columns][:amount]
    assert_equal "Memo", results[:detected_columns][:description]
    assert_equal "Type", results[:detected_columns][:category]
  end

  # --- Transaction Parsing ---

  test "parses all transactions" do
    assert @results[:transactions].size > 60
  end

  test "classifies income transactions correctly" do
    income = @results[:transactions].select { |t| t[:transaction_type] == :income }
    assert income.size > 10
    assert income.all? { |t| t[:amount] > 0 }
  end

  test "classifies expense transactions correctly" do
    expenses = @results[:transactions].select { |t| t[:transaction_type] == :expense }
    assert expenses.size > 20
    assert expenses.all? { |t| t[:amount] < 0 }
  end

  test "classifies transfer transactions correctly" do
    transfers = @results[:transactions].select { |t| t[:transaction_type] == :transfer }
    assert transfers.size > 5
  end

  # --- Account Detection ---

  test "detects primary account" do
    assert_equal "Betterment Checking", @results[:account][:name]
    assert_equal :checking, @results[:account][:type]
    assert_equal "Betterment", @results[:account][:institution]
  end

  test "detects accounts from internal transfers" do
    account_names = @results[:detected_accounts].map { |a| a[:name] }
    assert_includes account_names, "Emergency Fund"
    assert_includes account_names, "General Savings"
  end

  test "detects credit card accounts from payments" do
    account_names = @results[:detected_accounts].map { |a| a[:name] }
    assert_includes account_names, "Apple Credit Card"
    assert_includes account_names, "Chase Credit Card"
  end

  test "detected savings accounts have correct type" do
    ef = @results[:detected_accounts].find { |a| a[:name] == "Emergency Fund" }
    assert_equal :savings, ef[:type]
  end

  test "detected credit card accounts have correct type" do
    cc = @results[:detected_accounts].find { |a| a[:name] == "Apple Credit Card" }
    assert_equal :credit_card, cc[:type]
  end

  test "deduplicates detected accounts" do
    names = @results[:detected_accounts].map { |a| a[:name] }
    assert_equal names.uniq.size, names.size
  end

  # --- Recurring Income Detection ---

  test "detects Wescom payroll as recurring income" do
    wescom = @results[:recurring_income].find { |i| i[:source_name].include?("Wescom") }
    assert_not_nil wescom, "Should detect Wescom payroll"
    assert_equal :biweekly, wescom[:frequency]
    assert_in_delta 1728.30, wescom[:amount], 0.01
  end

  test "detects County of Meeker payroll as recurring income" do
    meeker = @results[:recurring_income].find { |i| i[:source_name].include?("Meeker") }
    assert_not_nil meeker, "Should detect Meeker payroll"
    assert_equal :biweekly, meeker[:frequency]
    assert_in_delta 1740.00, meeker[:amount], 0.01
  end

  test "detects Turbotenant rent as recurring income" do
    rent = @results[:recurring_income].find { |i| i[:source_name].include?("Turbotenant") }
    assert_not_nil rent, "Should detect Turbotenant rent deposit"
    assert_equal :monthly, rent[:frequency]
    assert_in_delta 1962.50, rent[:amount], 0.01
  end

  # --- Recurring Bill Detection ---

  test "detects AT&T as recurring bill" do
    att = @results[:recurring_bills].find { |b| b[:name].include?("AT&T") }
    assert_not_nil att, "Should detect AT&T"
    assert_equal :monthly, att[:frequency]
    assert_in_delta 52.00, att[:amount], 0.01
  end

  test "detects Netflix as recurring bill" do
    netflix = @results[:recurring_bills].find { |b| b[:name].include?("Netflix") }
    assert_not_nil netflix, "Should detect Netflix"
    assert_equal :monthly, netflix[:frequency]
    assert_in_delta 15.99, netflix[:amount], 0.01
  end

  test "detects State Farm as recurring bill" do
    sf = @results[:recurring_bills].find { |b| b[:name].include?("State Farm") }
    assert_not_nil sf, "Should detect State Farm"
    assert_equal :monthly, sf[:frequency]
    assert_in_delta 189.00, sf[:amount], 0.01
  end

  test "detects mortgage payments as recurring bills" do
    mt = @results[:recurring_bills].find { |b| b[:name].include?("M&T") }
    assert_not_nil mt, "Should detect M&T Mortgage"
    assert_equal :monthly, mt[:frequency]
    assert_in_delta 2662.18, mt[:amount], 0.01
  end

  # --- Recurring Transfer Detection ---

  test "detects Emergency Fund transfer as recurring" do
    ef = @results[:recurring_transfers].find { |t| t[:to_account] == "Emergency Fund" }
    assert_not_nil ef, "Should detect Emergency Fund transfer"
    assert_equal :biweekly, ef[:frequency]
    assert_in_delta 150.00, ef[:amount], 0.01
  end

  test "detects General Savings in detected accounts even if not recurring" do
    # General Savings has irregular timing (biweekly + month-end), so it may not
    # be detected as recurring, but it should appear in detected_accounts
    account_names = @results[:detected_accounts].map { |a| a[:name] }
    assert_includes account_names, "General Savings"
  end

  # --- Category Mapping ---

  test "maps CSV categories to budget categories" do
    mapping = @results[:category_mapping]
    assert_equal "Lifestyle", mapping["Shopping"]
    assert_equal "Food", mapping["Food & Dining"]
    assert_equal "Transportation", mapping["Auto & Transport"]
    assert_equal "Utilities", mapping["Bills & Utilities"]
    assert_equal "Housing", mapping["Housing"]
    assert_equal "Debt", mapping["Credit Card Payment"]
    assert_equal "Savings", mapping["Internal Transfer"]
    assert_nil mapping["External Deposit"]
    assert_equal "Insurance", mapping["Financial"]
    assert_equal "Health", mapping["Health & Fitness"]
  end

  # --- Budget Suggestions ---

  test "generates budget suggestions" do
    assert @results[:budget_suggestions].any?
  end

  test "budget suggestions include housing category" do
    housing = @results[:budget_suggestions].find { |s| s[:category] == "Housing" }
    assert_not_nil housing
    assert housing[:monthly_total] > 0
    assert housing[:items].any?
  end

  test "budget suggestions are sorted by monthly total descending" do
    totals = @results[:budget_suggestions].map { |s| s[:monthly_total] }
    assert_equal totals, totals.sort.reverse
  end

  # --- Summary ---

  test "builds accurate summary" do
    summary = @results[:summary]
    assert summary[:total_transactions] > 60
    assert summary[:months_covered] >= 3
    assert summary[:total_income] > 0
    assert summary[:total_expenses] > 0
    assert summary[:categories_found] > 5
    assert summary[:monthly_income_avg] > 0
    assert summary[:monthly_expense_avg] > 0
  end

  # --- Edge Cases ---

  test "handles empty CSV gracefully" do
    analyzer = SmartImportAnalyzer.new("Settled Date,Amount,Description\n")
    results = analyzer.analyze
    assert results[:error].present?
  end

  test "handles CSV without category column" do
    csv = "Date,Amount,Description\n2026-01-01,-50.00,Test Payment\n2026-02-01,-50.00,Test Payment\n2026-03-01,-50.00,Test Payment\n"
    analyzer = SmartImportAnalyzer.new(csv)
    results = analyzer.analyze
    assert_nil results[:detected_columns][:category]
    assert results[:transactions].any?
  end

  test "handles malformed CSV" do
    assert_raises(ArgumentError) do
      SmartImportAnalyzer.new("not,a\nvalid\"csv\"file\n\"unclosed").analyze
    end
  end

  # --- Frequency Detection ---

  test "detects weekly frequency" do
    dates = (0..5).map { |i| Date.new(2026, 1, 1) + (i * 7) }
    analyzer = SmartImportAnalyzer.new("")
    freq = analyzer.send(:detect_frequency, dates)
    assert_equal :weekly, freq
  end

  test "detects biweekly frequency" do
    dates = (0..3).map { |i| Date.new(2026, 1, 1) + (i * 14) }
    analyzer = SmartImportAnalyzer.new("")
    freq = analyzer.send(:detect_frequency, dates)
    assert_equal :biweekly, freq
  end

  test "detects monthly frequency" do
    dates = [Date.new(2025, 12, 1), Date.new(2026, 1, 1), Date.new(2026, 2, 1)]
    analyzer = SmartImportAnalyzer.new("")
    freq = analyzer.send(:detect_frequency, dates)
    assert_equal :monthly, freq
  end
end
