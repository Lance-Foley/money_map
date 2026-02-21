class DebtCalculator
  attr_reader :strategy, :extra_payment

  def initialize(debts, extra_payment: 0, strategy: :avalanche)
    @debts = debts.map { |d| d.dup }
    @extra_payment = extra_payment.to_f
    @strategy = strategy
  end

  def calculate
    working_debts = sort_debts(@debts.map { |d| d.dup })
    schedule = []
    total_interest = 0.0
    month = 0
    original_balances = working_debts.map { |d| [d[:name], d[:balance]] }.to_h

    loop do
      break if working_debts.all? { |d| d[:balance] <= 0 }
      month += 1
      break if month > 600 # safety: 50 years max

      month_payments = []
      extra_remaining = @extra_payment

      working_debts.each do |debt|
        next if debt[:balance] <= 0

        # Calculate monthly interest
        monthly_interest = debt[:balance] * (debt[:rate].to_f / 12.0)
        total_interest += monthly_interest

        # Determine payment amount
        payment = debt[:min_payment].to_f

        # First non-zero-balance debt in sorted order gets the extra payment
        if extra_remaining > 0 && debt == working_debts.find { |d| d[:balance] > 0 }
          payment += extra_remaining
          extra_remaining = 0
        end

        # Can't pay more than balance + interest
        payment = [payment, debt[:balance] + monthly_interest].min

        principal = payment - monthly_interest
        principal = [principal, 0].max  # Ensure non-negative
        debt[:balance] = [debt[:balance] - principal, 0].max

        month_payments << {
          name: debt[:name],
          payment: payment.round(2),
          principal: principal.round(2),
          interest: monthly_interest.round(2),
          remaining: debt[:balance].round(2)
        }
      end

      schedule << {
        month: month,
        date: (Date.current + month.months).strftime("%Y-%m"),
        payments: month_payments,
        remaining_balance: working_debts.sum { |d| d[:balance] }.round(2)
      }
    end

    total_original = original_balances.values.sum

    {
      strategy: @strategy,
      payoff_order: sort_debts(@debts.map(&:dup)).map { |d| { name: d[:name], balance: d[:balance] } },
      months_to_freedom: month,
      debt_free_date: Date.current + month.months,
      total_interest: total_interest.round(2),
      total_paid: (total_original + total_interest).round(2),
      schedule: schedule
    }
  end

  def self.compare(debts, extra_payment: 0)
    snowball = new(debts, extra_payment: extra_payment, strategy: :snowball).calculate
    avalanche = new(debts, extra_payment: extra_payment, strategy: :avalanche).calculate

    {
      snowball: snowball,
      avalanche: avalanche,
      savings_difference: (snowball[:total_interest] - avalanche[:total_interest]).round(2),
      months_difference: snowball[:months_to_freedom] - avalanche[:months_to_freedom]
    }
  end

  # Calculate impact of adding extra payment
  def self.extra_payment_impact(debts, base_extra: 0, new_extra: 500)
    base = new(debts, extra_payment: base_extra, strategy: :avalanche).calculate
    with_extra = new(debts, extra_payment: new_extra, strategy: :avalanche).calculate

    {
      months_saved: base[:months_to_freedom] - with_extra[:months_to_freedom],
      interest_saved: (base[:total_interest] - with_extra[:total_interest]).round(2),
      base_result: base,
      extra_result: with_extra
    }
  end

  private

  def sort_debts(debts)
    case @strategy
    when :snowball
      debts.sort_by { |d| d[:balance] }
    when :avalanche
      debts.sort_by { |d| -(d[:rate] || 0).to_f }
    else
      debts
    end
  end
end
