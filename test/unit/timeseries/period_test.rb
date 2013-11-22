require File.expand_path("../../helper", __FILE__)
require "timeseries/period"

class PeriodTest < Test::Unit::TestCase
  Period = Timeseries::Period

  #
  # Period.coerce

  def test_coerce_returns_period_unchanges
    period = Period.new({})
    assert_equal(period.object_id, Period.coerce(period).object_id)
  end

  def test_coerce_creates_period_from_hash
    period = Period.coerce({:weeks => 1})
    assert_equal(Period, period.class)
    assert_equal({:weeks => 1}, period.data)
  end

  def test_coerce_parses_period_string
    assert_equal({:weeks => 1, :days => -2}, Period.coerce("1w-2d").data)
  end

  def test_coerce_treats_number_as_seconds
    assert_equal({:seconds => 2}, Period.coerce(2).data)
  end

  def test_coerce_treats_normal_period_key_as_one_of_that_period_type
    assert_equal({:weeks => 1}, Period.coerce(:weeks).data)
  end

  def test_coerce_raises_error_if_obj_cannot_be_coerced
    obj = Object.new
    err = assert_raises(RuntimeError) { Period.coerce(obj) }
    assert_equal "cannot coerce to Period: #{obj.inspect}", err.message
  end

  #
  #
  # Period.period_type
  #

  def test_period_type_maps_short_versions_to_standard_type
    assert_equal :seconds, Period.period_type("s")
    assert_equal :seconds, Period.period_type("secs")
    assert_equal :seconds, Period.period_type("seconds")
  end

  def test_period_type_raises_error_for_unknown_type
    err = assert_raises(RuntimeError) { Period.period_type("invalid") }
    assert_equal 'invalid period type: "invalid"', err.message
  end

  #
  # Period.parse
  #

  def test_parse_documentation
    expected = {:seconds => 1, :weeks => 2}
    assert_equal(expected, Period.parse("1s2w").data)
    expected = {:seconds => 1, :weeks => 2}
    assert_equal(expected, Period.parse("1sec2weeks").data)
  end

  def test_parse_returns_period_hash_for_string
    expected = {:seconds => 1}
    assert_equal(expected, Period.parse("s").data)
  end

  def test_parse_allows_integer_modifier
    expected = {:seconds => 1001}
    assert_equal(expected, Period.parse("1001s").data)
  end

  def test_parse_allows_float_modifier
    expected = {:seconds => 10.01}
    assert_equal(expected, Period.parse("10.01s").data)
  end

  def test_parse_allows_negative_modifier
    expected = {:seconds => -10.01}
    assert_equal(expected, Period.parse("-10.01s").data)
  end

  def test_parse_allows_multiple_units
    expected = {:seconds => 1, :weeks => 2}
    assert_equal(expected, Period.parse("1s2w").data)
  end

  def test_parse_allows_whitespace
    expected = {:seconds => 1, :weeks => 2}
    assert_equal(expected, Period.parse(" 1s 2w ").data)
  end

  def test_parse_uses_last_period_value
    expected = {:seconds => 3}
    assert_equal(expected, Period.parse("1s2s3s").data)
  end

  def test_parse_allows_period_aliases
    expected = {:seconds => 1, :weeks => 2}
    assert_equal(expected, Period.parse("1sec2weeks").data)
  end

  def test_parse_treats_bare_number_as_seconds
    expected = {:seconds => 1}
    assert_equal(expected, Period.parse("1").data)
  end

  def test_parse_raises_error_for_invalid_period_string
    err = assert_raises(RuntimeError) { Period.parse("invalid") }
    assert_equal 'invalid period string: "invalid"', err.message
  end

  #
  # Period.format
  #

  def test_format_formats_period_as_period_string
    period = Period.new(:seconds => 1, :weeks => 2)
    assert_equal("1s2w", Period.format(period))
  end

  #
  # reverse tests
  #

  def test_reverse_returns_new_period_with_reverse_period
    period = Period.new(:minutes => 15, :seconds => -1)
    result = period.reverse
    assert_equal({:minutes => 15, :seconds => -1}, period.data)
    assert_equal({:minutes => -15, :seconds => 1}, result.data)
  end

  def test_reverse_bang_reverses_period_in_self
    period = Period.new(:minutes => 15)
    assert_equal period, period.reverse!
    assert_equal({:minutes => -15}, period.data)
  end

  #
  # multiply tests
  #

  def test_multiply_returns_new_period_with_each_period_component_multiplied_by_factor
    period = Period.new(:minutes => 15, :seconds => -1)
    result = period.multiply(2)
    assert_equal({:minutes => 15, :seconds => -1}, period.data)
    assert_equal({:minutes => 30, :seconds => -2}, result.data)
  end

  def test_multiply_bang_multiplies_period_in_self
    period = Period.new(:minutes => 15)
    assert_equal period, period.multiply!(2)
    assert_equal({:minutes => 30}, period.data)
  end

  #
  # ref_size tests
  #

  def test_ref_size_returns_seconds_in_seconds_period
    period  = Period.new(:seconds => 1)
    seconds = 1
    assert_equal(seconds, period.ref_size)
  end

  def test_ref_size_assumes_60_seconds_per_minute
    period  = Period.new(:minutes => 1)
    seconds = 60
    assert_equal(seconds, period.ref_size)
  end

  def test_ref_size_assumes_60_minutes_per_hour
    period  = Period.new(:hours => 1)
    seconds = 60 * 60
    assert_equal(seconds, period.ref_size)
  end

  def test_ref_size_assumes_24_hours_per_day
    period  = Period.new(:days => 1)
    seconds = 24 * 60 * 60
    assert_equal(seconds, period.ref_size)
  end

  def test_ref_size_assumes_7_days_per_week
    period  = Period.new(:weeks => 1)
    seconds = 7 * 24 * 60 * 60
    assert_equal(seconds, period.ref_size)
  end

  def test_ref_size_assumes_30_days_per_month
    period  = Period.new(:months => 1)
    seconds = 30 * 24 * 60 * 60
    assert_equal(seconds, period.ref_size)
  end

  def test_ref_size_assumes_365_point_25_days_per_year
    period  = Period.new(:years => 1)
    seconds = 365.25 * 24 * 60 * 60
    assert_equal(seconds, period.ref_size)
  end

  def test_ref_size_sums_over_all_components
    period  = Period.new(:weeks => 1, :days => 2, :seconds => 2)
    seconds = (7 * 24 * 60 * 60) + (2 * 24 * 60 * 60) + 2
    assert_equal(seconds, period.ref_size)
  end

  ###################################################
  # Snap Tests
  ###################################################

  def test_snap_previous_documentation
    time = Time.parse("2010-01-01 01:23:55")
    period = Period.new(:minutes => 15)
    assert_equal(Time.parse("2010-01-01 01:15:00"), period.snap_previous(time))
  end

  def test_snap_next_documentation
    time = Time.parse("2010-01-01 01:23:55")
    period = Period.new(:minutes => 15)
    assert_equal(Time.parse("2010-01-01 01:30:00"), period.snap_next(time))
  end

  def test_snap_previous_ignores_period_types_with_zero_value
    time = Time.parse("2010-01-01 01:23:55")
    period = Period.new(:minutes => 15, :seconds => 0, :hours => 0)
    assert_equal(Time.parse("2010-01-01 01:15:00"), period.snap_previous(time))
  end

  def test_snap_next_ignores_period_types_with_zero_value
    time = Time.parse("2010-01-01 01:23:55")
    period = Period.new(:minutes => 15, :seconds => 0, :hours => 0)
    assert_equal(Time.parse("2010-01-01 01:30:00"), period.snap_next(time))
  end

  def self.snap_tests(desc, current_time, snap_pairs)
    snap_pairs.each_pair do |period_str, (previous_time, next_time)|
      test_suffix  = "#{desc}_#{period_str}".gsub(/\W/, "_")
      class_eval %{
        def test_snap_previous_for_#{test_suffix}
          period = Period.parse("#{period_str}")
          current_time = Time.parse("#{current_time}")
          assert_equal("#{previous_time}", period.snap_previous(current_time).strftime("%Y-%m-%d %H:%M:%S.%3N"))
        end

        def test_snap_next_for_#{test_suffix}
          period = Period.parse("#{period_str}")
          current_time = Time.parse("#{current_time}")
          assert_equal("#{next_time}", period.snap_next(current_time).strftime("%Y-%m-%d %H:%M:%S.%3N"))
        end
      }
    end
  end

  OFF_GRID_TIMES = {
    "1sec"    => ["2011-02-03 04:05:06.000", "2011-02-03 04:05:07.000"],
    "1min"    => ["2011-02-03 04:05:00.000", "2011-02-03 04:06:00.000"],
    "1hr"     => ["2011-02-03 04:00:00.000", "2011-02-03 05:00:00.000"],
    "15sec"   => ["2011-02-03 04:05:00.000", "2011-02-03 04:05:15.000"],
    "15min"   => ["2011-02-03 04:00:00.000", "2011-02-03 04:15:00.000"],
    "15hr"    => ["2011-02-03 00:00:00.000", "2011-02-03 15:00:00.000"]
  }
  snap_tests("off_grid", "2011-02-03 04:05:06.789", OFF_GRID_TIMES)

  ON_GRID_TIMES = {
    "1sec"    => ["2010-01-01 00:00:00.000", "2010-01-01 00:00:00.000"],
    "1min"    => ["2010-01-01 00:00:00.000", "2010-01-01 00:00:00.000"],
    "1hr"     => ["2010-01-01 00:00:00.000", "2010-01-01 00:00:00.000"],
    "15sec"   => ["2010-01-01 00:00:00.000", "2010-01-01 00:00:00.000"],
    "15min"   => ["2010-01-01 00:00:00.000", "2010-01-01 00:00:00.000"],
    "15hr"    => ["2010-01-01 00:00:00.000", "2010-01-01 00:00:00.000"]
  }
  snap_tests("on_grid", "2010-01-01 00:00:00.000", ON_GRID_TIMES)
end
