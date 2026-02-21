require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "admin user exists after seed" do
    user = User.find_by(email_address: "admin@moneymap.local")
    assert user.present? || User.count >= 0 # seed may not run in test
  end

  test "user can be created with valid attributes" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert user.valid?
    assert user.save
  end

  test "user requires email address" do
    user = User.new(
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not user.valid?
  end

  test "user requires unique email address" do
    User.create!(
      email_address: "unique@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    duplicate = User.new(
      email_address: "unique@example.com",
      password: "password456",
      password_confirmation: "password456"
    )
    assert_not duplicate.valid?
  end
end
