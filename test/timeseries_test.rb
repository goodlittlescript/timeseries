require File.expand_path("../helper", __FILE__)
require "timeseries"

class TimeseriesTest < Test::Unit::TestCase

  def setup
    @current_zone = Time.zone
    Time.zone = nil
  end

  def teardown
    Time.zone = @current_zone
  end

  #
  # Timeseries.normalize
  # start,period,n_steps

  def test_normalize_with_start_period_n_steps_snaps_start_time_to_previous_if_specified
    options = Timeseries.normalize(
      :start_time => Time.parse("2010-01-01 00:23:00"),
      :period     => {:minutes => 15},
      :n_steps    => 1,
      :snap_start_time => :previous
    )
    assert_equal("2010-01-01 00:15:00", options[:start_time].strftime("%Y-%m-%d %H:%M:%S"))
  end

  def test_normalize_with_start_period_n_steps__snaps_start_time_to_next_if_specified
    options = Timeseries.normalize(
      :start_time => Time.parse("2010-01-01 00:23:00"),
      :period     => {:minutes => 15},
      :n_steps    => 1,
      :snap_start_time => :next
    )
    assert_equal("2010-01-01 00:30:00", options[:start_time].strftime("%Y-%m-%d %H:%M:%S"))
  end

  #
  # Timeseries.normalize
  # start,stop,period

  def test_normalize_sets_n_steps_from_start_stop_time_and_period_inclusive
    options = Timeseries.normalize(
      :start_time => Time.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.parse("2010-01-01 01:00:00"),
      :period     => {:minutes => 15}
    )
    assert_equal(5, options[:n_steps])
  end

  def test_normalize_snaps_start_time_to_previous_if_specified
    options = Timeseries.normalize(
      :start_time => Time.parse("2010-01-01 00:23:00"),
      :stop_time  => Time.parse("2010-01-01 01:00:00"),
      :period     => {:minutes => 15},
      :snap_start_time => :previous
    )
    assert_equal("2010-01-01 00:15:00", options[:start_time].strftime("%Y-%m-%d %H:%M:%S"))
    assert_equal(4, options[:n_steps])
  end

  def test_normalize_snaps_start_time_to_next_if_specified
    options = Timeseries.normalize(
      :start_time => Time.parse("2010-01-01 00:23:00"),
      :stop_time  => Time.parse("2010-01-01 01:00:00"),
      :period     => {:minutes => 15},
      :snap_start_time => :next
    )
    assert_equal("2010-01-01 00:30:00", options[:start_time].strftime("%Y-%m-%d %H:%M:%S"))
    assert_equal(3, options[:n_steps])
  end

  def test_normalize_snaps_stop_time_to_previous_if_specified
    options = Timeseries.normalize(
      :start_time => Time.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.parse("2010-01-01 00:56:00"),
      :period     => {:minutes => 15},
      :snap_stop_time => :previous
    )
    assert_equal("2010-01-01 00:45:00", options[:stop_time].strftime("%Y-%m-%d %H:%M:%S"))
    assert_equal(4, options[:n_steps])
  end

  def test_normalize_snaps_stop_time_to_next_if_specified
    options = Timeseries.normalize(
      :start_time => Time.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.parse("2010-01-01 00:56:00"),
      :period     => {:minutes => 15},
      :snap_stop_time => :next
    )
    assert_equal("2010-01-01 01:00:00", options[:stop_time].strftime("%Y-%m-%d %H:%M:%S"))
    assert_equal(5, options[:n_steps])
  end

  #
  # Timeseries.n_steps special cases
  #

  def test_n_steps_does_not_count_step_that_exceeds_stop_time
    n_steps = Timeseries.n_steps(
      :start_time => Time.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.parse("2010-01-01 00:00:05"),
      :period     => {:seconds => 2}
    )
    assert_equal(3, n_steps)
  end
  
  def test_n_steps_returns_1_for_equal_start_stop_times
    n_steps = Timeseries.n_steps(
      :start_time => Time.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.parse("2010-01-01 00:00:00"),
      :period     => {:seconds => 1}
    )
    assert_equal(1, n_steps)
  end
  
  def test_n_steps_returns_1_for_equal_start_stop_times_and_negative_period
    n_steps = Timeseries.n_steps(
      :start_time => Time.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.parse("2010-01-01 00:00:00"),
      :period     => {:seconds => -1}
    )
    assert_equal(1, n_steps)
  end
  
  def test_n_steps_returns_0_for_start_time_equal_stop_time_and_empty_period
    n_steps = Timeseries.n_steps(
      :start_time => Time.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.parse("2010-01-01 00:00:00"),
      :period     => {}
    )
    assert_equal(0, n_steps)
  end
  
  def test_n_steps_returns_0_for_start_time_greater_than_stop_time_and_positive_period
    n_steps = Timeseries.n_steps(
      :start_time => Time.parse("2010-01-01 00:00:01"),
      :stop_time  => Time.parse("2010-01-01 00:00:00"),
      :period     => {:seconds => 1}
    )
    assert_equal(0, n_steps)
  end
  
  def test_n_steps_returns_0_for_stop_time_greater_than_start_time_and_negative_period
    n_steps = Timeseries.n_steps(
      :start_time => Time.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.parse("2010-01-01 00:00:01"),
      :period     => {:seconds => -1}
    )
    assert_equal(0, n_steps)
  end

  def test_n_steps_raises_error_for_start_time_not_equal_stop_time_and_empty_period
    options = {
      :start_time => Time.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.parse("2010-01-01 00:00:01"),
      :period     => {}
    }
    err = assert_raises(RuntimeError) { Timeseries.n_steps(options) }
    assert_equal "empty period", err.message
  end
  
  def test_n_steps_raises_error_for_start_time_not_equal_stop_time_and_logically_empty_period
    options = {
      :start_time => Time.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.parse("2010-01-01 00:00:01"),
      :period     => {:months => 12, :years => -1}
    }
    err = assert_raises(RuntimeError) { Timeseries.n_steps(options) }
    assert_equal "empty period", err.message
  end

  def test_n_steps_where_first_step_is_smaller_than_average_step
    # first step is february in a leap year
    n_steps = Timeseries.n_steps(
      :start_time => Time.parse("2012-02-01 00:00:00"),
      :stop_time  => Time.parse("2042-01-01 00:00:00"),
      :period     => {:months => 1}
    )
    assert_equal(360, n_steps)
  end

  def test_n_steps_where_first_step_is_larger_than_average_step
    # first step is a 31-day month
    n_steps = Timeseries.n_steps(
      :start_time => Time.parse("2012-01-01 00:00:00"),
      :stop_time  => Time.parse("2041-12-01 00:00:00"),
      :period     => {:months => 1}
    )
    assert_equal(360, n_steps)
  end

  def test_n_steps_ignores_period_types_with_zero_value
    n_steps = Timeseries.n_steps(
      :start_time => Time.parse("2012-01-01 00:00:00"),
      :stop_time  => Time.parse("2012-03-01 00:00:00"),
      :period     => {:months => 1, :days => 0}
    )
    assert_equal(3, n_steps)
  end

  ###################################################
  # Series Tests
  ###################################################

  def self.series_tests(desc, series, &block)
    setup_method = "#{desc}_setup".gsub(/\W/, "_")

    block = lambda {} unless block_given?
    define_method(setup_method, &block)

    series.each_pair do |period_str, steps|
      start_time = steps.first
      stop_time  = steps.last
      n_steps    = steps.length
      period = Timeseries::Period.parse(period_str).data

      test_suffix  = "#{desc}_#{period_str}".gsub(/\W/, "_")
      class_eval %{
        def test_n_steps_for_#{test_suffix}
          #{setup_method}
          n_steps = Timeseries.n_steps(
            :start_time => Time.parse("#{start_time}"),
            :stop_time  => Time.parse("#{stop_time}"),
            :period     => #{period.inspect}
          )
          assert_equal(#{n_steps}, n_steps)
        end

        def test_series_for_#{test_suffix}
          #{setup_method}
          series = Timeseries.new(
            :start_time => Time.parse("#{start_time}"),
            :n_steps    => #{n_steps},
            :period     => #{period.inspect}
          )
          steps = series.map {|step| step.strftime("%Y-%m-%d %H:%M:%S %Z") }
          assert_equal(#{steps.inspect}, steps)
        end

        def test_reverse_series_for_#{test_suffix}
          #{setup_method}
          series = Timeseries.new(
            :start_time => Time.parse("#{stop_time}"),
            :n_steps    => -#{n_steps},
            :period     => #{period.inspect}
          )
          steps = series.map {|step| step.strftime("%Y-%m-%d %H:%M:%S %Z") }
          assert_equal(#{steps.reverse.inspect}, steps)
        end
      }
    end
  end

  #
  # UTC
  #

  UTC_SERIES = {
    "1sec"    => ["2010-01-01 00:00:00 UTC", "2010-01-01 00:00:01 UTC", "2010-01-01 00:00:02 UTC"],
    "1min"    => ["2010-01-01 00:00:00 UTC", "2010-01-01 00:01:00 UTC", "2010-01-01 00:02:00 UTC"],
    "1hr"     => ["2010-01-01 00:00:00 UTC", "2010-01-01 01:00:00 UTC", "2010-01-01 02:00:00 UTC"],
    "1day"    => ["2010-01-01 00:00:00 UTC", "2010-01-02 00:00:00 UTC", "2010-01-03 00:00:00 UTC"],
    "1week"   => ["2010-01-01 00:00:00 UTC", "2010-01-08 00:00:00 UTC", "2010-01-15 00:00:00 UTC"],
    "1mon"    => ["2010-01-01 00:00:00 UTC", "2010-02-01 00:00:00 UTC", "2010-03-01 00:00:00 UTC"],
    "1yr"     => ["2010-01-01 00:00:00 UTC", "2011-01-01 00:00:00 UTC", "2012-01-01 00:00:00 UTC"],

    "2day1h"  => ["2010-01-01 00:00:00 UTC", "2010-01-03 01:00:00 UTC", "2010-01-05 02:00:00 UTC"],
    "-2day1h" => ["2010-01-05 00:00:00 UTC", "2010-01-03 01:00:00 UTC", "2010-01-01 02:00:00 UTC"]
  }
  series_tests("utc", UTC_SERIES) { Time.zone = "UTC" }

  #
  # Daylight Savings Zone
  #

  DST_SERIES = {}
  UTC_SERIES.each_pair do |period_str, steps|
    DST_SERIES[period_str] = steps.map {|step| step.sub("UTC", "MST") }
  end
  series_tests("dst", DST_SERIES) { Time.zone = "MST7MDT" }

  #
  # Spring Daylight Savings (2010-03-14 02:00)
  # Consider gap a part of following (DST) period.
  #
  #   ex: 1-day period
  #   1MST-1MST   (24 hrs), 1MST-1MDT   (23hrs)
  #   2MST-"2MST" (24 hrs), "2MST"-2MDT (23hrs)
  #   3MST-3MDT   (23 hrs), 3MDT-3MDT   (24hrs)
  #

  DST_SPRING_FIXED_PERIOD_SERIES = {
    "1sec"    => ["2010-03-14 01:59:59 MST", "2010-03-14 03:00:00 MDT", "2010-03-14 03:00:01 MDT"],
    "1min"    => ["2010-03-14 01:59:00 MST", "2010-03-14 03:00:00 MDT", "2010-03-14 03:01:00 MDT"],
    "1hr"     => ["2010-03-14 01:00:00 MST", "2010-03-14 03:00:00 MDT", "2010-03-14 04:00:00 MDT"],
  }
  series_tests("dst_spring_fixed_period", DST_SPRING_FIXED_PERIOD_SERIES) { Time.zone = "MST7MDT" }

  LEFT_DST_SPRING_VARIABLE_PERIOD_SERIES = {
    "1day"    => ["2010-03-13 01:00:00 MST", "2010-03-14 01:00:00 MST", "2010-03-15 01:00:00 MDT"],
    "1week"   => ["2010-03-07 01:00:00 MST", "2010-03-14 01:00:00 MST", "2010-03-21 01:00:00 MDT"],
    "1mon"    => ["2010-02-14 01:00:00 MST", "2010-03-14 01:00:00 MST", "2010-04-14 01:00:00 MDT"],
    "1year"   => ["2009-03-14 01:00:00 MDT", "2010-03-14 01:00:00 MST", "2011-03-14 01:00:00 MDT"],

    "2day1h"  => ["2010-03-12 00:00:00 MST", "2010-03-14 01:00:00 MST", "2010-03-16 02:00:00 MDT"],
    "-2day1h" => ["2010-03-16 00:00:00 MDT", "2010-03-14 01:00:00 MST", "2010-03-12 02:00:00 MST"],
  }
  series_tests("left_dst_spring_variable_period", LEFT_DST_SPRING_VARIABLE_PERIOD_SERIES) { Time.zone = "MST7MDT" }

  # See https://github.com/rails/rails/issues/10938
  DST_SPRING_VARIABLE_PERIOD_SERIES = {
    "1day"    => ["2010-03-13 02:00:00 MST", "2010-03-14 03:00:00 MDT", "2010-03-15 02:00:00 MDT"],
    "1week"   => ["2010-03-07 02:00:00 MST", "2010-03-14 03:00:00 MDT", "2010-03-21 02:00:00 MDT"],
    "1mon"    => ["2010-02-14 02:00:00 MST", "2010-03-14 03:00:00 MDT", "2010-04-14 02:00:00 MDT"],
    "1year"   => ["2009-03-14 02:00:00 MDT", "2010-03-14 03:00:00 MDT", "2011-03-14 02:00:00 MDT"],
    
    "2day1h"  => ["2010-03-12 01:00:00 MST", "2010-03-14 03:00:00 MDT", "2010-03-16 03:00:00 MDT"],
    "-2day1h" => ["2010-03-16 01:00:00 MDT", "2010-03-14 03:00:00 MDT", "2010-03-12 03:00:00 MST"],
  }
  series_tests("dst_spring_variable_period", DST_SPRING_VARIABLE_PERIOD_SERIES) { Time.zone = "MST7MDT"; }

  RIGHT_DST_SPRING_VARIABLE_PERIOD_SERIES = {
    "1day"    => ["2010-03-13 03:00:00 MST", "2010-03-14 03:00:00 MDT", "2010-03-15 03:00:00 MDT"],
    "1week"   => ["2010-03-07 03:00:00 MST", "2010-03-14 03:00:00 MDT", "2010-03-21 03:00:00 MDT"],
    "1mon"    => ["2010-02-14 03:00:00 MST", "2010-03-14 03:00:00 MDT", "2010-04-14 03:00:00 MDT"],
    "1year"   => ["2009-03-14 03:00:00 MDT", "2010-03-14 03:00:00 MDT", "2011-03-14 03:00:00 MDT"],

    "2day1h"  => ["2010-03-12 02:00:00 MST", "2010-03-14 03:00:00 MDT", "2010-03-16 04:00:00 MDT"],
    "-2day1h" => ["2010-03-16 02:00:00 MDT", "2010-03-14 03:00:00 MDT", "2010-03-12 04:00:00 MST"],
  }
  series_tests("right_dst_spring_variable_period", RIGHT_DST_SPRING_VARIABLE_PERIOD_SERIES) { Time.zone = "MST7MDT" }

  #
  # Fall Daylight Savings (2010-11-07 02:00)
  # Consider pad a part of following (non-DST) period.
  #
  #   ex: 1-day period
  #   1MDT-1MDT   (24 hrs),  1MDT-1MST  (25hrs)
  #

  DST_FALL_FIXED_PERIOD_SERIES = {
    "1sec"    => ["2010-11-07 01:59:59 MDT", "2010-11-07 01:00:00 MST", "2010-11-07 01:00:01 MST"],
    "1min"    => ["2010-11-07 01:59:00 MDT", "2010-11-07 01:00:00 MST", "2010-11-07 01:01:00 MST"],
    "1hr"     => ["2010-11-07 00:00:00 MDT", "2010-11-07 01:00:00 MDT", "2010-11-07 01:00:00 MST", "2010-11-07 02:00:00 MST", "2010-11-07 03:00:00 MST"],
  }
  series_tests("dst_fall_fixed_period", DST_FALL_FIXED_PERIOD_SERIES) { Time.zone = "MST7MDT" }

  DST_FALL_VARIABLE_PERIOD_SERIES = {
    "1day"    => ["2010-11-06 01:00:00 MDT", "2010-11-07 01:00:00 MDT", "2010-11-08 01:00:00 MST"],
    "1week"   => ["2010-10-31 01:00:00 MDT", "2010-11-07 01:00:00 MDT", "2010-11-14 01:00:00 MST"],
    "1mon"    => ["2010-10-07 01:00:00 MDT", "2010-11-07 01:00:00 MDT", "2010-12-07 01:00:00 MST"],
    "1year"   => ["2009-11-07 01:00:00 MST", "2010-11-07 01:00:00 MDT", "2011-11-07 01:00:00 MST"],

    "2day1h"  => ["2010-11-05 00:00:00 MDT", "2010-11-07 01:00:00 MDT", "2010-11-09 02:00:00 MST"],
    "-2day1h" => ["2010-11-09 00:00:00 MST", "2010-11-07 01:00:00 MDT", "2010-11-05 02:00:00 MDT"],
  }
  series_tests("dst_fall_variable_period", DST_FALL_VARIABLE_PERIOD_SERIES) { Time.zone = "MST7MDT" }

  #
  # Leap Year
  #

  NON_LEAP_YEAR_SERIES = {
    "1sec"    => ["2010-02-28 23:59:59 UTC", "2010-03-01 00:00:00 UTC"],
    "1min"    => ["2010-02-28 23:59:00 UTC", "2010-03-01 00:00:00 UTC"],
    "1hr"     => ["2010-02-28 23:00:00 UTC", "2010-03-01 00:00:00 UTC"],
    "1day"    => ["2010-02-28 00:00:00 UTC", "2010-03-01 00:00:00 UTC"],
    "1week"   => ["2010-02-22 00:00:00 UTC", "2010-03-01 00:00:00 UTC"],
    "1mon"    => ["2010-01-29 00:00:00 UTC", "2010-02-28 00:00:00 UTC", "2010-03-29 00:00:00 UTC"],
    "1yr"     => ["2010-02-28 00:00:00 UTC", "2011-02-28 00:00:00 UTC"],
  }
  series_tests("non_leap_year", NON_LEAP_YEAR_SERIES) { Time.zone = "UTC" }

  LEFT_LEAP_YEAR_FIXED_SERIES = {
    "1sec"    => ["2012-02-28 23:59:59 UTC", "2012-02-29 00:00:00 UTC"],
    "1min"    => ["2012-02-28 23:59:00 UTC", "2012-02-29 00:00:00 UTC"],
    "1hr"     => ["2012-02-28 23:00:00 UTC", "2012-02-29 00:00:00 UTC"]
  }
  series_tests("left_leap_year_fixed", LEFT_LEAP_YEAR_FIXED_SERIES) { Time.zone = "UTC" }

  RIGHT_LEAP_YEAR_FIXED_SERIES = {
    "1sec"    => ["2012-02-29 23:59:59 UTC", "2012-03-01 00:00:00 UTC"],
    "1min"    => ["2012-02-29 23:59:00 UTC", "2012-03-01 00:00:00 UTC"],
    "1hr"     => ["2012-02-29 23:00:00 UTC", "2012-03-01 00:00:00 UTC"]
  }
  series_tests("right_leap_year_fixed", RIGHT_LEAP_YEAR_FIXED_SERIES) { Time.zone = "UTC" }

  LEAP_YEAR_SERIES = {
    "1day"    => ["2012-02-28 00:00:00 UTC", "2012-02-29 00:00:00 UTC", "2012-03-01 00:00:00 UTC"],
    "1week"   => ["2012-02-22 00:00:00 UTC", "2012-02-29 00:00:00 UTC", "2012-03-07 00:00:00 UTC"],
    "1mon"    => ["2012-01-29 00:00:00 UTC", "2012-02-29 00:00:00 UTC", "2012-03-29 00:00:00 UTC"],
    "1yr"     => ["2012-02-29 00:00:00 UTC", "2013-02-28 00:00:00 UTC", "2014-02-28 00:00:00 UTC", "2015-02-28 00:00:00 UTC", "2016-02-29 00:00:00 UTC"]
  }
  series_tests("leap_year", NON_LEAP_YEAR_SERIES) { Time.zone = "UTC" }

  #
  # Leap Second
  # Not supported I guess...
  #
  # LEAP_SECOND_SERIES = {
  #   "1sec"    => ["2012-06-30 23:59:59 UTC", "2012-06-30 23:59:60 UTC", "2012-07-01 00:00:00 UTC"],
  # }
  # series_tests("leap_second", LEAP_SECOND_SERIES) { Time.zone = "UTC" }

  #
  # each test
  #

  def test_each_without_n_steps_loops_quote_indefinitely_unquote
    series = Timeseries.new({})
    count = 100
    series.each do |time|
      break if count == 0
      count -= 1
    end
    assert_equal 0, count
  end

  #
  # collate test
  #

  def quarter_hour_series
    Timeseries.new(
      :start_time => Time.parse("2010-01-01 00:00:00 UTC"),
      :period     => {:minutes => 15},
      :n_steps    => 5
    )
  end

  def quarter_hour_data
    [:a, :b, :c, :d, :e]
  end

  def test_collate_data_into_interval_ending_intervals
    intervals = {}
    quarter_hour_series.collate(quarter_hour_data).each_pair do |time, interval|
      intervals[time.strftime("%Y-%m-%d %H:%M:%S %Z")] = interval
    end

    assert_equal({
      "2010-01-01 00:15:00 UTC" => [:a, :b],
      "2010-01-01 00:30:00 UTC" => [:b, :c],
      "2010-01-01 00:45:00 UTC" => [:c, :d],
      "2010-01-01 01:00:00 UTC" => [:d, :e]
    }, intervals)
  end

  def test_collate_allows_format
    intervals = quarter_hour_series.collate(quarter_hour_data, :format => "%H:%M")
    assert_equal({
      "00:15" => [:a, :b],
      "00:30" => [:b, :c],
      "00:45" => [:c, :d],
      "01:00" => [:d, :e]
    }, intervals)
  end

  def test_collate_yields_intervals_to_block_if_given
    intervals = quarter_hour_series.collate(quarter_hour_data, :format => "%Y-%m-%d %H:%M:%S %Z") do |previous, current|
      [previous.to_s, current.to_s.upcase]
    end
    assert_equal({
      "2010-01-01 00:15:00 UTC" => ["a", "B"],
      "2010-01-01 00:30:00 UTC" => ["b", "C"],
      "2010-01-01 00:45:00 UTC" => ["c", "D"],
      "2010-01-01 01:00:00 UTC" => ["d", "E"]
    }, intervals)
  end

  def test_collate_allows_interval_beginning_collation
    intervals = quarter_hour_series.collate(quarter_hour_data, :interval_type => :beginning, :format => "%Y-%m-%d %H:%M:%S %Z")
    assert_equal({
      "2010-01-01 00:00:00 UTC" => [:a, :b],
      "2010-01-01 00:15:00 UTC" => [:b, :c],
      "2010-01-01 00:30:00 UTC" => [:c, :d],
      "2010-01-01 00:45:00 UTC" => [:d, :e]
    }, intervals)
  end

  def test_collate_raises_error_for_invalid_interval_type
    err = assert_raises(RuntimeError) { quarter_hour_series.collate(quarter_hour_data, :interval_type => :invalid) }
    assert_equal "invalid interval_type: :invalid", err.message
  end

  #
  # intervals
  #

  def test_intervals_returns_array_of_intervals
    intervals = []
    quarter_hour_series.intervals.each do |previous, current|
      intervals << [previous, current].map {|time| time.strftime("%Y-%m-%d %H:%M:%S %Z") }
    end

    assert_equal([
      ["2010-01-01 00:00:00 UTC", "2010-01-01 00:15:00 UTC"],
      ["2010-01-01 00:15:00 UTC", "2010-01-01 00:30:00 UTC"],
      ["2010-01-01 00:30:00 UTC", "2010-01-01 00:45:00 UTC"],
      ["2010-01-01 00:45:00 UTC", "2010-01-01 01:00:00 UTC"]
    ], intervals)
  end

  def test_intervals_accepts_format
    intervals = quarter_hour_series.intervals(:format => "%Y-%m-%d %H:%M:%S %Z")

    assert_equal([
      ["2010-01-01 00:00:00 UTC", "2010-01-01 00:15:00 UTC"],
      ["2010-01-01 00:15:00 UTC", "2010-01-01 00:30:00 UTC"],
      ["2010-01-01 00:30:00 UTC", "2010-01-01 00:45:00 UTC"],
      ["2010-01-01 00:45:00 UTC", "2010-01-01 01:00:00 UTC"]
    ], intervals)
  end

  def test_intervals_returns_empty_intervals_for_single_step_series
    series = Timeseries.new(:n_steps => 1)
    assert_equal 1, series.count
    assert_equal [], series.intervals
  end

  def test_intervals_returns_empty_intervals_for_empty_series
    series = Timeseries.new(:n_steps => 0)
    assert_equal 0, series.count
    assert_equal [], series.intervals
  end
end
