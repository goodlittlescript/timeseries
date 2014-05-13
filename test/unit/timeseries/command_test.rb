#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)
require "timeseries/command"

class CommandTest < Test::Unit::TestCase
  Command = Timeseries::Command

  def setup
    @current_zone = Time.zone
    Time.zone = "UTC"
  end

  def teardown
    Time.zone = @current_zone
  end

  #
  # format_time/parse_time
  #

  utc_time = Time.parse "2010-01-02 03:04:05.123456 UTC"
  tz_time  = utc_time.in_time_zone("MST7MDT")
  TIMES = [utc_time, tz_time]

  def test_time_format_parse_round_trip_with_integer
    command = Command.new(:input_time_format => 6, :time_format => 6)
    TIMES.each do |time|
      time_str = command.format_time(time)
      assert_equal time, command.parse_time(time_str)
    end
  end

  def test_time_format_parse_round_trip_with_format
    format  = "%Y-%m-%d %Z"
    command = Command.new(:input_time_format => format, :time_format => format)
    TIMES.each do |time|
      time_str = command.format_time(time)
      expected = time.change(:hour => 0, :minute => 0, :second => 0, :usec => 0)
      assert_equal expected, command.parse_time(time_str)
    end
  end

  def test_time_format_parse_round_trip_with_no_format_does_not_preserve_usec
    command = Command.new
    TIMES.each do |time|
      time_str = command.format_time(time)
      assert_equal time.change(:usec => 0), command.parse_time(time_str)
    end
  end
end
