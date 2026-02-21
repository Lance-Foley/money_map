module Schedulable
  extend ActiveSupport::Concern

  FREQUENCY_MAP = {
    0 => :weekly,
    1 => :biweekly,
    2 => :semimonthly,
    3 => :monthly,
    4 => :quarterly,
    5 => :semi_annual,
    6 => :annual,
    7 => :custom
  }.freeze

  INTERVAL_UNITS = { 0 => :days, 1 => :weeks, 2 => :months, 3 => :years }.freeze

  def next_occurrence_after(date)
    case frequency_name
    when :weekly
      advance_by_days(date, 7)
    when :biweekly
      advance_by_days(date, 14)
    when :semimonthly
      next_semimonthly(date)
    when :monthly
      advance_by_months(date, 1)
    when :quarterly
      advance_by_months(date, 3)
    when :semi_annual
      advance_by_months(date, 6)
    when :annual
      advance_by_months(date, 12)
    when :custom
      advance_by_custom(date)
    end
  end

  def occurrences_in_range(range_start, range_end)
    dates = []
    current = next_occurrence_on_or_after(range_start)
    while current && current <= range_end
      dates << current
      current = next_occurrence_after(current)
    end
    dates
  end

  def schedule_description
    case frequency_name
    when :weekly then "Weekly on #{start_date.strftime('%A')}s"
    when :biweekly then "Every 2 weeks on #{start_date.strftime('%A')}s"
    when :semimonthly then "1st and 15th of each month"
    when :monthly then "Monthly on the #{start_date.day.ordinalize}"
    when :quarterly then "Quarterly on the #{start_date.day.ordinalize}"
    when :semi_annual then "Every 6 months on the #{start_date.day.ordinalize}"
    when :annual then "Annually on #{start_date.strftime('%B %d')}"
    when :custom
      unit = INTERVAL_UNITS[custom_interval_unit]
      "Every #{custom_interval_value} #{unit} starting #{start_date.strftime('%b %d, %Y')}"
    end
  end

  private

  def frequency_name
    FREQUENCY_MAP[frequency]
  end

  def next_occurrence_on_or_after(date)
    candidate = next_occurrence_after(date - 1.day)
    candidate && candidate >= date ? candidate : next_occurrence_after(date)
  end

  def advance_by_days(after_date, interval)
    return start_date if start_date > after_date
    days_since = (after_date - start_date).to_i
    cycles = (days_since / interval) + 1
    start_date + (cycles * interval).days
  end

  def advance_by_months(after_date, interval)
    candidate = start_date
    while candidate <= after_date
      candidate = candidate >> interval
    end
    candidate
  end

  def next_semimonthly(after_date)
    day1 = [start_date.day, 1].max
    day2 = [day1 + 14, 28].min

    candidates = []
    (-1..2).each do |month_offset|
      ref = after_date >> month_offset
      [day1, day2].each do |d|
        safe_day = [d, Date.new(ref.year, ref.month, -1).day].min
        candidates << Date.new(ref.year, ref.month, safe_day)
      end
    end

    candidates.sort.find { |d| d > after_date }
  end

  def advance_by_custom(after_date)
    unit = INTERVAL_UNITS[custom_interval_unit]
    candidate = start_date
    loop do
      return candidate if candidate > after_date
      case unit
      when :days then candidate += custom_interval_value.days
      when :weeks then candidate += (custom_interval_value * 7).days
      when :months then candidate = candidate >> custom_interval_value
      when :years then candidate = candidate >> (custom_interval_value * 12)
      end
      break candidate if candidate > after_date
    end
  end
end
