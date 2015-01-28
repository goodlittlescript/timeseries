require File.expand_path("../helper", __FILE__)
require "timeseries"

class TimeseriesTest < Minitest::Test

  def setup
    @current_zone = Time.zone
    Time.zone = "UTC"
  end

  def teardown
    Time.zone = @current_zone
  end

  #
  # Timeseries.create
  #

  def test_create_creates_1s_unbounded_timeseries
    timeseries = Timeseries.create
    assert_equal({:seconds => 1}, timeseries.period.data)
    assert_equal(nil, timeseries.n_steps)
  end

  def test_create_uses_strings_or_symbols
    timeseries = Timeseries.create('n_steps' => 10, :period => {'seconds' => 10})
    assert_equal({:seconds => 10}, timeseries.period.data)
    assert_equal(10, timeseries.n_steps)
  end

  def test_create_interprets_string_as_period
    timeseries = Timeseries.create("10s")
    assert_equal({:seconds => 10}, timeseries.period.data)
  end

  #
  # Timeseries.normalize
  # 2 data points

  def test_normalize_with_start_time_assumes_period_1s_and_nil_n_steps
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:23:00")
    )
    assert_equal({:seconds => 1}, options[:period].data)
    assert_equal(nil, options[:n_steps])
  end

  def test_normalize_with_start_time_and_period_assumes_nil_n_steps
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:23:00"),
      :period     => {:minutes => 15},
    )
    assert_equal({:minutes => 15}, options[:period].data)
    assert_equal(nil, options[:n_steps])
  end

  def test_normalize_with_start_time_and_n_steps_assumes_period_1s
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:23:00"),
      :n_steps    => 10
    )
    assert_equal({:seconds => 1}, options[:period].data)
    assert_equal(10, options[:n_steps])
  end

  #
  # Timeseries.normalize
  # start,period,n_steps

  def test_normalize_with_start_period_n_steps_snaps_start_time_to_previous_if_specified
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:23:00"),
      :period     => {:minutes => 15},
      :n_steps    => 1,
      :snap_start_time => :previous
    )
    assert_equal("2010-01-01 00:15:00", options[:start_time].strftime("%Y-%m-%d %H:%M:%S"))
  end

  def test_normalize_with_start_period_n_steps_snaps_start_time_to_next_if_specified
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:23:00"),
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
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.zone.parse("2010-01-01 01:00:00"),
      :period     => {:minutes => 15}
    )
    assert_equal(5, options[:n_steps])
  end

  def test_normalize_snaps_start_time_to_previous_if_specified
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:23:00"),
      :stop_time  => Time.zone.parse("2010-01-01 01:00:00"),
      :period     => {:minutes => 15},
      :snap_start_time => :previous
    )
    assert_equal("2010-01-01 00:15:00", options[:start_time].strftime("%Y-%m-%d %H:%M:%S"))
    assert_equal(4, options[:n_steps])
  end

  def test_normalize_snaps_start_time_to_next_if_specified
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:23:00"),
      :stop_time  => Time.zone.parse("2010-01-01 01:00:00"),
      :period     => {:minutes => 15},
      :snap_start_time => :next
    )
    assert_equal("2010-01-01 00:30:00", options[:start_time].strftime("%Y-%m-%d %H:%M:%S"))
    assert_equal(3, options[:n_steps])
  end

  def test_normalize_snaps_stop_time_to_previous_if_specified
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.zone.parse("2010-01-01 00:56:00"),
      :period     => {:minutes => 15},
      :snap_stop_time => :previous
    )
    assert_equal("2010-01-01 00:45:00", options[:stop_time].strftime("%Y-%m-%d %H:%M:%S"))
    assert_equal(4, options[:n_steps])
  end

  def test_normalize_snaps_stop_time_to_next_if_specified
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.zone.parse("2010-01-01 00:56:00"),
      :period     => {:minutes => 15},
      :snap_stop_time => :next
    )
    assert_equal("2010-01-01 01:00:00", options[:stop_time].strftime("%Y-%m-%d %H:%M:%S"))
    assert_equal(5, options[:n_steps])
  end

  def test_normalize_ignores_nil_values
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :stop_time  => nil,
      :n_steps    => 2,
      :period     => {:minutes => 15}
    )
    assert_equal(nil, options[:stop_time])
  end

  def test_normalize_coerces_start_and_stop_time
    options = Timeseries.normalize(
    :start_time => "2010-01-01 00:00:00",
    :stop_time  => "2010-01-01 00:56:00",
    :period     => {:minutes => 15},
    )
    assert options[:start_time].kind_of?(ActiveSupport::TimeWithZone)
    assert options[:stop_time].kind_of?(ActiveSupport::TimeWithZone)
  end

  #
  # Timeseries.normalize
  # stop,period,n_steps

  def test_normalize_sets_start_time_from_n_steps_stop_time_and_period
    options = Timeseries.normalize(
      :stop_time  => Time.zone.parse("2010-01-01 01:00:00"),
      :period     => {:minutes => 15},
      :n_steps    => 5
    )
    assert_equal(Time.zone.parse("2010-01-01 00:00:00"), options[:start_time])
  end

  def test_normalize_assumes_one_second_period_for_stop_time_and_n_steps
    options = Timeseries.normalize(
      :stop_time  => Time.zone.parse("2010-01-01 00:00:05"),
      :n_steps    => 6
    )
    assert_equal(Time.zone.parse("2010-01-01 00:00:00"), options[:start_time])
  end

  #
  # Timeseries.normalize
  # start,stop,n_steps

  def test_normalize_sets_period_from_start_stop_time_and_n_steps
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.zone.parse("2010-01-01 01:00:00"),
      :n_steps    => 5
    )
    assert_equal({:seconds => 900.0}, options[:period])
  end

  def test_normalize_sets_period_from_start_stop_time_and_n_steps_where_stop_is_less_than_start
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 01:00:00"),
      :stop_time  => Time.zone.parse("2010-01-01 00:00:00"),
      :n_steps    => 5
    )
    assert_equal({:seconds => -900.0}, options[:period])
  end

  def test_normalize_sets_empty_period_for_n_steps_0
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.zone.parse("2010-01-01 01:00:00"),
      :n_steps    => 0
    )
    assert_equal({}, options[:period])
  end

  #
  # Timeseries.normalize
  # with signatures

  def test_normalize_uses_signature_as_specified
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.zone.parse("2010-01-01 01:00:00"),
      :period     => {:minutes => 15},
      :n_steps    => 100,
      :signature  => [:start_time, :stop_time, :period]
    )
    assert_equal(5, options[:n_steps])
  end

  def test_normalize_fills_out_signature_in_signature_key_order
    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :stop_time  => Time.zone.parse("2010-01-01 01:00:00"),
      :period     => {:minutes => 15},
      :n_steps    => 100,
      :signature  => [:start_time]
    )
    assert_equal(5, options[:n_steps])

    options = Timeseries.normalize(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :period     => {:minutes => 15},
      :n_steps    => 100,
      :signature  => [:start_time]
    )
    assert_equal(100, options[:n_steps])
  end

  # initialize test
  #

  def test_new_raises_error_if_start_time_is_not_a_TimeWithZone
    time = Time.now
    err = assert_raises(RuntimeError) { Timeseries.new(:start_time => time) }
    assert_equal "invalid start_time: #{time.inspect} (must be a TimeWithZone)", err.message
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

      forward_steps = steps.map {|step| [*step].first }
      reverse_steps = steps.map {|step| [*step].last }.reverse

      test_suffix  = "#{desc}_#{period_str}".gsub(/\W/, "_")
      class_eval %{
        def test_n_steps_to_for_#{test_suffix}
          #{setup_method}
          series = Timeseries.new(
            :start_time => Time.zone.parse("#{start_time}"),
            :period     => #{period.inspect}
          )
          stop_time = Time.zone.parse("#{stop_time}")
          assert_equal(#{n_steps}, series.n_steps_to(stop_time))
        end

        def test_series_for_#{test_suffix}
          #{setup_method}
          series = Timeseries.new(
            :start_time => Time.zone.parse("#{start_time}"),
            :n_steps    => #{n_steps},
            :period     => #{period.inspect}
          )
          steps = series.map {|step| step.strftime("%Y-%m-%d %H:%M:%S %Z") }
          assert_equal(#{forward_steps.inspect}, steps)
        end

        def test_reverse_series_for_#{test_suffix}
          #{setup_method}
          series = Timeseries.new(
            :start_time => Time.zone.parse("#{stop_time}"),
            :n_steps    => -#{n_steps},
            :period     => #{period.inspect}
          )
          steps = series.map {|step| step.strftime("%Y-%m-%d %H:%M:%S %Z") }
          assert_equal(#{reverse_steps.inspect}, steps)
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

  # MST/MDT transitions are variable in the forward and back direction... as
  # justification if you are Jan 31 and you want to go forward 1 month then
  # you end up at Feb 28 or Feb 29, but if you go foward 2 months you end up
  # at March 31. Point being that if you can advance one digit in the time
  # without changing any of the others then you do it. It's only when you
  # can't go there exactly that you start munging other digits. Insofar as
  # MST/MDT is a "digit" it should not be munged unless needed. That means:
  #
  #   MDT -> MDT -> MST  # forward
  #   MDT <- MST <- MST  # reverse
  #
  # Note that in the 1year case the transition happens to be symmetric because
  # daylight savings happens on different days in each of those years.

  DST_FALL_VARIABLE_PERIOD_SERIES = {
    "1day"    => ["2010-11-06 01:00:00 MDT", ["2010-11-07 01:00:00 MDT", "2010-11-07 01:00:00 MST"], "2010-11-08 01:00:00 MST"],
    "1week"   => ["2010-10-31 01:00:00 MDT", ["2010-11-07 01:00:00 MDT", "2010-11-07 01:00:00 MST"], "2010-11-14 01:00:00 MST"],
    "1mon"    => ["2010-10-07 01:00:00 MDT", ["2010-11-07 01:00:00 MDT", "2010-11-07 01:00:00 MST"], "2010-12-07 01:00:00 MST"],
    "1year"   => ["2009-11-07 01:00:00 MST", "2010-11-07 01:00:00 MDT", "2011-11-07 01:00:00 MST"],

    "2day1h"  => ["2010-11-05 00:00:00 MDT", ["2010-11-07 01:00:00 MDT", "2010-11-07 01:00:00 MST"], "2010-11-09 02:00:00 MST"],
    "-2day1h" => ["2010-11-09 00:00:00 MST", ["2010-11-07 01:00:00 MST", "2010-11-07 01:00:00 MDT"], "2010-11-05 02:00:00 MDT"],
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

  def test_each_returns_Enumerator
    series = Timeseries.new({})
    assert series.each.kind_of?(Enumerator)
  end

  #
  # stop_time test
  #

  def test_stop_time_returns_stop_time_as_calculated_by_inputs
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :period     => {:seconds => 2},
      :n_steps    => 3
    )
    assert_equal Time.zone.parse("2010-01-01 00:00:04"), series.stop_time
    assert_equal series.each.to_a.last, series.stop_time
  end

  def test_stop_time_works_with_negative_steps
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:06"),
      :period     => {:seconds => 2},
      :n_steps    => -3
    )
    assert_equal Time.zone.parse("2010-01-01 00:00:02"), series.stop_time
    assert_equal series.each.to_a.last, series.stop_time
  end

  def test_stop_time_returns_start_time_for_zero_steps
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :period     => {:seconds => 2},
      :n_steps    => 0
    )
    assert_equal Time.zone.parse("2010-01-01 00:00:00"), series.stop_time
  end

  def test_stop_time_returns_nil_when_n_steps_is_nil
    series = Timeseries.new :n_steps => nil
    assert_equal nil, series.stop_time
  end

  #
  # n_steps_to special cases
  #

  def test_n_steps_to_does_not_count_step_that_exceeds_stop_time
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :period     => {:seconds => 2}
    )
    stop_time = Time.zone.parse("2010-01-01 00:00:05")
    assert_equal 3, series.n_steps_to(stop_time)
  end

  def test_n_steps_to_returns_1_for_equal_start_stop_times
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :period     => {:seconds => 1}
    )
    stop_time = Time.zone.parse("2010-01-01 00:00:00")
    assert_equal 1, series.n_steps_to(stop_time)
  end

  def test_n_steps_to_returns_1_for_equal_start_stop_times_and_negative_period
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :period     => {:seconds => -1}
    )
    stop_time = Time.zone.parse("2010-01-01 00:00:00")
    assert_equal 1, series.n_steps_to(stop_time)
  end

  def test_n_steps_to_returns_0_for_start_time_equal_stop_time_and_empty_period
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :period     => {}
    )
    stop_time = Time.zone.parse("2010-01-01 00:00:00")
    assert_equal 0, series.n_steps_to(stop_time)
  end

  def test_n_steps_to_raises_error_for_start_time_greater_than_stop_time_and_positive_period
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:01"),
      :period     => {:seconds => 1}
    )
    stop_time = Time.zone.parse("2010-01-01 00:00:00")
    err = assert_raises(RuntimeError) { series.n_steps_to(stop_time) }
    assert_equal "cannot solve for n_steps (start_time > stop_time with positive period)", err.message
  end

  def test_n_steps_to_raises_error_for_stop_time_greater_than_start_time_and_negative_period
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :period     => {:seconds => -1}
    )
    stop_time = Time.zone.parse("2010-01-01 00:00:01")
    err = assert_raises(RuntimeError) { series.n_steps_to(stop_time) }
    assert_equal "cannot solve for n_steps (stop_time > start_time with negative period)", err.message
  end

  def test_n_steps_to_raises_error_for_start_time_not_equal_stop_time_and_empty_period
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :period     => {}
    )
    stop_time = Time.zone.parse("2010-01-01 00:00:01")

    err = assert_raises(RuntimeError) { series.n_steps_to(stop_time) }
    assert_equal "empty period", err.message
  end

  def test_n_steps_to_raises_error_for_start_time_not_equal_stop_time_and_logically_empty_period
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00"),
      :period     => {:months => 12, :years => -1}
    )
    stop_time = Time.zone.parse("2010-01-01 00:00:01")

    err = assert_raises(RuntimeError) { series.n_steps_to(stop_time) }
    assert_equal "empty period", err.message
  end

  def test_n_steps_to_where_first_step_is_smaller_than_average_step
    # first step is february in a leap year
    series = Timeseries.new(
      :start_time => Time.zone.parse("2012-02-01 00:00:00"),
      :period     => {:months => 1}
    )
    stop_time = Time.zone.parse("2042-01-01 00:00:00")
    assert_equal 360, series.n_steps_to(stop_time)
  end

  def test_n_steps_to_where_first_step_is_larger_than_average_step
    # first step is a 31-day month
    series = Timeseries.new(
      :start_time => Time.zone.parse("2012-01-01 00:00:00"),
      :period     => {:months => 1}
    )
    stop_time = Time.zone.parse("2041-12-01 00:00:00")
    assert_equal 360, series.n_steps_to(stop_time)
  end

  def test_n_steps_to_ignores_period_types_with_zero_value
    series = Timeseries.new(
      :start_time => Time.zone.parse("2012-01-01 00:00:00"),
      :period     => {:months => 1, :days => 0}
    )
    stop_time = Time.zone.parse("2012-03-01 00:00:00")
    assert_equal 3, series.n_steps_to(stop_time)
  end

  #
  # collate test
  #

  def quarter_hour_series
    Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00 UTC"),
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

  def test_collate_data_collates_only_as_many_pairs_as_possible
    insufficient_data = quarter_hour_data
    insufficient_data.pop

    intervals = quarter_hour_series.collate(insufficient_data, :format => "%H:%M")
    assert_equal({
      "00:15" => [:a, :b],
      "00:30" => [:b, :c],
      "00:45" => [:c, :d]
    }, intervals)
  end

  def test_collate_data_for_infinite_series
    infinite_series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00 UTC"),
      :period     => {:minutes => 15}
    )

    intervals = infinite_series.collate(quarter_hour_data, :format => "%H:%M")
    assert_equal({
      "00:15" => [:a, :b],
      "00:30" => [:b, :c],
      "00:45" => [:c, :d],
      "01:00" => [:d, :e]
    }, intervals)
  end

  def test_collate_interval_beginning_data_for_infinite_series
    infinite_series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00 UTC"),
      :period     => {:minutes => 15}
    )

    intervals = infinite_series.collate(quarter_hour_data, :interval_type => :beginning, :format => "%H:%M")
    assert_equal({
      "00:00" => [:a, :b],
      "00:15" => [:b, :c],
      "00:30" => [:c, :d],
      "00:45" => [:d, :e]
    }, intervals)
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

  def test_intervals_for_infinite_series_raises_error
    infinite_series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-01 00:00:00 UTC"),
      :period     => {:minutes => 15}
    )

    err = assert_raises(RuntimeError) { infinite_series.intervals }
    assert_equal "unavailable for infinie series", err.message
  end
end
