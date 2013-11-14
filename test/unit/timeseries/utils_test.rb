#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)
require "timeseries/utils"

class UtilsTest < Test::Unit::TestCase
  include Timeseries::Utils

  def setup
    @current_zone = Time.zone
    Time.zone = "UTC"
  end

  def teardown
    Time.zone = @current_zone
  end

  #
  # coerce
  #

  def test_coerce_returns_TimeWithZone
    obj = Time.zone.parse "2010-01-01 00:00:00"
    time = coerce obj
    assert_equal obj.object_id, time.object_id
  end

  def test_coerce_String
    time = coerce "2010-01-01 00:00:00"
    assert time.kind_of?(ActiveSupport::TimeWithZone)
    assert_equal("2010-01-01 00:00:00 UTC", time.strftime("%Y-%m-%d %H:%M:%S %Z"))
  end

  def test_coerce_using_to_time
    obj = Object.new
    def obj.to_time
      Time.parse "2010-01-01 00:00:00 UTC"
    end
    time = coerce obj

    assert time.kind_of?(ActiveSupport::TimeWithZone)
    assert_equal(Time.zone, time.time_zone)
    assert_equal("2010-01-01 00:00:00 UTC", time.strftime("%Y-%m-%d %H:%M:%S %Z"))
  end

  def test_coerce_raises_error_if_obj_cannot_be_coerced
    obj = Object.new
    err = assert_raises(RuntimeError) { coerce(obj) }
    assert_equal "cannot coerce to TimeWithZone: #{obj.inspect}", err.message
  end

  #
  # time_parser/time_formatter
  #

  utc_time = Time.parse "2010-01-02 03:04:05.123456 UTC"
  tz_time  = utc_time.in_time_zone("MST7MDT")
  TIMES = [utc_time, tz_time]

  def test_time_format_parse_round_trip_with_integer
    parser    = time_parser(6)
    formatter = time_formatter(6)
    TIMES.each do |time|
      time_str = formatter.call(time)
      assert_equal time, parser.call(time_str)
    end
  end

  def test_time_format_parse_round_trip_with_format
    parser    = time_parser("%Y-%m-%d %Z")
    formatter = time_formatter("%Y-%m-%d %Z")
    TIMES.each do |time|
      time_str = formatter.call(time)
      expected = time.change(:hour => 0, :minute => 0, :second => 0, :usec => 0)
      assert_equal expected, parser.call(time_str)
    end
  end

  def test_time_format_parse_round_trip_with_no_format_does_not_preserve_usec
    parser    = time_parser
    formatter = time_formatter
    TIMES.each do |time|
      time_str = formatter.call(time)
      assert_equal time.change(:usec => 0), parser.call(time_str)
    end
  end
end
