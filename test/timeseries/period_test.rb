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
end
