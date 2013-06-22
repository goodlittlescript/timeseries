# Timeseries

Generate logically periodic time series data.

## Description

Timeseries generates logically periodic time steps in any time zone, and
accounts for irregularities like daylight-saving time and leap years. As an
example, a 1-month period at the beginning of a month preserves the numeric
day and time at each step.

    2010-01-01 09:05:00
    2010-02-01 09:05:00
    2010-03-01 09:05:00

An end-of-month series can also be generated; the series automatically maps
non-existent times (ex: Feb 31, 02:00 across a DST transition, etc) to their
logical equivalents.

    2010-01-31 09:05:00
    2010-02-28 09:05:00
    2010-03-31 09:05:00

Timeseries provides methods to work with these series too, for example to
collate data at each time step into intervals.

## Usage

From the command line:

    # start, n_steps, period
    $ timeseries 2010-01-31 -n 3 -p 1month
    2010-01-31 00:00:00 UTC
    2010-02-28 00:00:00 UTC
    2010-03-31 00:00:00 UTC

    # start, stop, period, format
    $ timeseries "00:00:00" "01:00:00" -p 15m -f "%H:%M"
    00:00
    00:15
    00:30
    00:45
    01:00

In code:

    Time.zone = "UTC"
    series = Timeseries.new(
      :start_time => Time.zone.parse("2010-01-31"),
      :n_steps    => 3,
      :period     => {:months => 1}
    )
    series.map {|time| time.iso8601 }
    # => [
    # "2010-01-31T00:00:00Z",
    # "2010-02-28T00:00:00Z",
    # "2010-03-31T00:00:00Z"
    # ]

Use `Timeseries.create` for more flexible initialization (coerces, parses,
solves for unknowns).

    series = Timeseries.create(
      :start_time => "00:00:00",
      :stop_time  => "01:00:00",
      :period     => "15m"
    )
    series.map {|time| time.strftime("%H:%M") }
    # => [
    # "00:00",
    # "00:15",
    # "00:30",
    # "00:45",
    # "01:00"
    # ]

To collate interval-ending intervals from data corresponding to each step:

    series.collate([:a, :b, :c, :d, :e], :format => "%H:%M")
    # => {
    # "00:15" => [:a, :b],
    # "00:30" => [:b, :c],
    # "00:45" => [:c, :d],
    # "01:00" => [:d, :e]
    # }

## Bugs

Leap seconds are not supported.

## Installation

Timeseries is available as a gem:

    $ gem install timeseries
