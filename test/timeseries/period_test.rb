require File.expand_path("../../helper", __FILE__)
require "timeseries/period"

class PeriodTest < Test::Unit::TestCase
  Period = Timeseries::Period

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

  def test_parse_raises_error_for_invalid_period_string
    err = assert_raises(RuntimeError) { Period.parse("invalid") }
    assert_equal 'invalid period string: "invalid"', err.message
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
