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

  def test_snap_documentation
    time = Time.parse("2011-02-03 04:23:55")
    period = Period.new(:minutes => 15)
    assert_equal Time.parse("2011-02-03 04:15:00"), period.snap(time)
  end

  def self.snap_tests(desc, snap_pairs)
    snap_pairs.each_pair do |period_str, snap_time_str|
      test_suffix  = "#{desc}_#{period_str}".gsub(/\W/, "_")
      class_eval %{
        def test_snap_for_#{test_suffix}
          period = Period.parse("#{period_str}")
          snap_time = period.snap(arbitrary_time)
          assert_equal("#{snap_time_str}", snap_time.strftime("%Y-%m-%d %H:%M:%S"))
        end
      }
    end
  end

  # Ok, not quite arbitrary.  This is a time that is not at the beginning of a
  # year, month, week, day, hour, or minute.
  def arbitrary_time
    Time.parse("2011-02-03 04:05:06")
  end

  SNAP_TIMES = {
    "1sec"    => "2011-02-03 04:05:06",
    "1min"    => "2011-02-03 04:05:00",
    "1hr"     => "2011-02-03 04:00:00",
    "15sec"   => "2011-02-03 04:05:00",
    "15min"   => "2011-02-03 04:00:00",
    "15hr"    => "2011-02-03 00:00:00"
  }
  snap_tests("basic", SNAP_TIMES)
end
