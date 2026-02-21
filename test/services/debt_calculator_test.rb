require "test_helper"

class DebtCalculatorTest < ActiveSupport::TestCase
  setup do
    @debts = [
      { name: "Credit Card", balance: 3500.0, rate: 0.1999, min_payment: 75.0 },
      { name: "Car Loan", balance: 15000.0, rate: 0.0499, min_payment: 350.0 },
      { name: "Mortgage", balance: 250000.0, rate: 0.0425, min_payment: 1250.0 }
    ]
    @extra_payment = 500.0
  end

  # Strategy ordering tests
  test "snowball orders by balance ascending" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :snowball)
    result = calc.calculate
    assert_equal "Credit Card", result[:payoff_order].first[:name]
    assert_equal "Mortgage", result[:payoff_order].last[:name]
  end

  test "avalanche orders by interest rate descending" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche)
    result = calc.calculate
    assert_equal "Credit Card", result[:payoff_order].first[:name]
  end

  # Interest comparison
  test "avalanche saves more or equal interest than snowball" do
    snowball = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :snowball).calculate
    avalanche = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche).calculate
    assert avalanche[:total_interest] <= snowball[:total_interest],
      "Avalanche (#{avalanche[:total_interest]}) should save more than snowball (#{snowball[:total_interest]})"
  end

  # Comparison method
  test "compare returns both strategies with savings difference" do
    result = DebtCalculator.compare(@debts, extra_payment: @extra_payment)
    assert result.key?(:snowball)
    assert result.key?(:avalanche)
    assert result.key?(:savings_difference)
    assert result.key?(:months_difference)
    assert result[:savings_difference] >= 0
  end

  # Debt free date
  test "calculates debt free date" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche)
    result = calc.calculate
    assert result[:debt_free_date].is_a?(Date)
    assert result[:months_to_freedom] > 0
    assert result[:debt_free_date] > Date.current
  end

  # Extra payment impact
  test "extra payment reduces months and interest" do
    base = DebtCalculator.new(@debts, extra_payment: 0, strategy: :avalanche).calculate
    extra = DebtCalculator.new(@debts, extra_payment: 500, strategy: :avalanche).calculate
    assert extra[:months_to_freedom] < base[:months_to_freedom]
    assert extra[:total_interest] < base[:total_interest]
  end

  test "extra_payment_impact shows savings" do
    result = DebtCalculator.extra_payment_impact(@debts, base_extra: 0, new_extra: 500)
    assert result[:months_saved] > 0
    assert result[:interest_saved] > 0
  end

  # Schedule
  test "generates monthly payment schedule" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche)
    result = calc.calculate
    assert result[:schedule].is_a?(Array)
    assert result[:schedule].length > 0

    first_month = result[:schedule].first
    assert first_month.key?(:month)
    assert first_month.key?(:payments)
    assert first_month.key?(:remaining_balance)
    assert first_month.key?(:date)
    assert_equal 1, first_month[:month]
  end

  test "schedule shows declining balance" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche)
    result = calc.calculate
    balances = result[:schedule].map { |s| s[:remaining_balance] }
    # Balance should generally decrease (it always does with positive payments)
    assert balances.last < balances.first
  end

  test "last schedule entry has zero or near-zero balance" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche)
    result = calc.calculate
    last_balance = result[:schedule].last[:remaining_balance]
    assert last_balance <= 0.01, "Final balance should be near zero, got #{last_balance}"
  end

  # Edge cases
  test "handles single debt" do
    single_debt = [{ name: "Card", balance: 1000.0, rate: 0.15, min_payment: 50.0 }]
    calc = DebtCalculator.new(single_debt, strategy: :avalanche)
    result = calc.calculate
    assert result[:months_to_freedom] > 0
    assert result[:total_interest] > 0
  end

  test "handles zero interest debt" do
    zero_rate = [{ name: "Friend Loan", balance: 5000.0, rate: 0.0, min_payment: 200.0 }]
    calc = DebtCalculator.new(zero_rate, strategy: :avalanche)
    result = calc.calculate
    assert_equal 25, result[:months_to_freedom]
    assert_equal 0.0, result[:total_interest]
  end

  test "handles empty debts array" do
    calc = DebtCalculator.new([], strategy: :avalanche)
    result = calc.calculate
    assert_equal 0, result[:months_to_freedom] # breaks immediately
    assert_equal 0.0, result[:total_interest]
  end

  test "does not mutate input debts" do
    original_balance = @debts.first[:balance]
    DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche).calculate
    assert_equal original_balance, @debts.first[:balance]
  end

  # Total paid
  test "total_paid equals principal plus interest" do
    calc = DebtCalculator.new(@debts, extra_payment: @extra_payment, strategy: :avalanche)
    result = calc.calculate
    original_total = @debts.sum { |d| d[:balance] }
    expected_total = (original_total + result[:total_interest]).round(2)
    assert_equal expected_total, result[:total_paid]
  end
end
