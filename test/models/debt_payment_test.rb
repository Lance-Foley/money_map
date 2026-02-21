require "test_helper"

class DebtPaymentTest < ActiveSupport::TestCase
  test "valid debt payment" do
    payment = DebtPayment.new(
      account: accounts(:visa_card),
      amount: 200.00,
      payment_date: Date.current
    )
    assert payment.valid?
  end

  test "requires amount" do
    payment = DebtPayment.new(
      account: accounts(:visa_card),
      payment_date: Date.current
    )
    assert_not payment.valid?
    assert_includes payment.errors[:amount], "can't be blank"
  end

  test "amount must be greater than 0" do
    payment = DebtPayment.new(
      account: accounts(:visa_card),
      amount: 0,
      payment_date: Date.current
    )
    assert_not payment.valid?
    assert_includes payment.errors[:amount], "must be greater than 0"
  end

  test "requires payment_date" do
    payment = DebtPayment.new(
      account: accounts(:visa_card),
      amount: 200.00
    )
    assert_not payment.valid?
    assert_includes payment.errors[:payment_date], "can't be blank"
  end

  test "requires account" do
    payment = DebtPayment.new(amount: 200.00, payment_date: Date.current)
    assert_not payment.valid?
    assert_includes payment.errors[:account], "must exist"
  end

  test "budget_period is optional" do
    payment = DebtPayment.new(
      account: accounts(:visa_card),
      amount: 200.00,
      payment_date: Date.current
    )
    assert payment.valid?
  end

  test "for_account scope filters by account" do
    visa = accounts(:visa_card)
    payments = DebtPayment.for_account(visa)
    payments.each do |payment|
      assert_equal visa.id, payment.account_id
    end
  end

  test "chronological scope orders by payment_date" do
    payments = DebtPayment.chronological
    dates = payments.map(&:payment_date)
    assert_equal dates, dates.sort
  end
end
