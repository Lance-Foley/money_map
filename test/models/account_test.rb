require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "valid account" do
    account = Account.new(name: "Test Account", account_type: :checking)
    assert account.valid?
  end

  test "requires name" do
    account = Account.new(account_type: :checking)
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "requires account_type" do
    account = Account.new(name: "Test")
    assert_not account.valid?
    assert_includes account.errors[:account_type], "can't be blank"
  end

  test "balance defaults to zero" do
    account = Account.create!(name: "New Account", account_type: :checking)
    assert_equal 0.0, account.balance.to_f
  end

  test "active defaults to true" do
    account = Account.create!(name: "New Account", account_type: :checking)
    assert account.active?
  end

  test "validates balance is a number" do
    account = Account.new(name: "Test", account_type: :checking, balance: "abc")
    assert_not account.valid?
    assert_includes account.errors[:balance], "is not a number"
  end

  test "validates interest_rate is not negative" do
    account = Account.new(name: "Test", account_type: :checking, interest_rate: -0.05)
    assert_not account.valid?
    assert_includes account.errors[:interest_rate], "must be greater than or equal to 0"
  end

  test "validates minimum_payment is not negative" do
    account = Account.new(name: "Test", account_type: :checking, minimum_payment: -10)
    assert_not account.valid?
    assert_includes account.errors[:minimum_payment], "must be greater than or equal to 0"
  end

  test "debt? returns true for credit_card" do
    assert accounts(:visa_card).debt?
  end

  test "debt? returns true for loan" do
    assert accounts(:car_loan).debt?
  end

  test "debt? returns true for mortgage" do
    assert accounts(:home_mortgage).debt?
  end

  test "debt? returns false for checking" do
    assert_not accounts(:chase_checking).debt?
  end

  test "asset? returns true for checking" do
    assert accounts(:chase_checking).asset?
  end

  test "asset? returns true for savings" do
    assert accounts(:ally_savings).asset?
  end

  test "asset? returns false for credit_card" do
    assert_not accounts(:visa_card).asset?
  end

  test "active scope returns only active accounts" do
    active = Account.active
    assert active.include?(accounts(:chase_checking))
    assert_not active.include?(accounts(:inactive_account))
  end

  test "debts scope returns debt accounts" do
    debts = Account.debts
    assert debts.include?(accounts(:visa_card))
    assert debts.include?(accounts(:car_loan))
    assert debts.include?(accounts(:home_mortgage))
    assert_not debts.include?(accounts(:chase_checking))
  end

  test "assets scope returns asset accounts" do
    assets = Account.assets
    assert assets.include?(accounts(:chase_checking))
    assert assets.include?(accounts(:ally_savings))
    assert_not assets.include?(accounts(:visa_card))
  end

  test "by_type scope filters by type" do
    checking_accounts = Account.by_type(:checking)
    assert checking_accounts.include?(accounts(:chase_checking))
    assert_not checking_accounts.include?(accounts(:ally_savings))
  end

  test "enum values are correct" do
    assert_equal "checking", Account.new(account_type: 0).account_type
    assert_equal "savings", Account.new(account_type: 1).account_type
    assert_equal "credit_card", Account.new(account_type: 2).account_type
    assert_equal "loan", Account.new(account_type: 3).account_type
    assert_equal "mortgage", Account.new(account_type: 4).account_type
    assert_equal "investment", Account.new(account_type: 5).account_type
  end
end
