require File.expand_path("../helper", __FILE__)
require "timeseries"
require "chronic"

class ReadmeTest < Test::Unit::TestCase

  def setup
    @current_zone = Time.zone
    Time.zone = nil
  end

  def teardown
    Time.zone = @current_zone
  end

  def test_command_line_usage
    output = `timeseries 2010-01-31 -n 3 -p 1month`
    assert_equal(%{
2010-01-31 12:00:00 UTC
2010-02-28 12:00:00 UTC
2010-03-31 12:00:00 UTC
}.lstrip, output)

    output = `timeseries "00:00:00" "01:00:00" -p 15m -f "%H:%M"`
    assert_equal(%{
00:00
00:15
00:30
00:45
01:00
}.lstrip, output)
  end

  def test_usage_in_code
    Time.zone = "UTC"
    Chronic.time_class = Time.zone
    series = Timeseries.new(
      :start_time => Chronic.parse("2010-01-31"),
      :n_steps    => 3,
      :period     => {:months => 1}
    )
    expected = [
    "2010-01-31T12:00:00Z",
    "2010-02-28T12:00:00Z",
    "2010-03-31T12:00:00Z"
    ]
    assert_equal(expected, series.map {|time| time.iso8601 })

    series = Timeseries.create(
      :start_time => Chronic.parse("00:00:00"),
      :stop_time  => Chronic.parse("01:00:00"),
      :period     => "15m"
    )
    expected = [
    "00:00",
    "00:15",
    "00:30",
    "00:45",
    "01:00"
    ]
    assert_equal(expected, series.map {|time| time.strftime("%H:%M") })

    expected = {
    "00:15" => [:a, :b],
    "00:30" => [:b, :c],
    "00:45" => [:c, :d],
    "01:00" => [:d, :e]
    }
    assert_equal(expected, series.collate([:a, :b, :c, :d, :e], :key_format => "%H:%M"))
  end
end