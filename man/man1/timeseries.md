timeseries(1) -- generate periodic time series data
=============================================

## SYNOPSIS

`timeseries` [options] INPUT_FILES...

## DESCRIPTION

**timeseries** generates logically periodic time series data in any time zone
while accounting for irregularities like daylight savings and leap years. This
type of series is useful to drive the creation of simulated datasets,
especially log data.

As an example a 'logical' end-of-month series accounts for the irregular
number of days in a month, especially in a leap year.

    $ timeseries -s 2012-01-31 -p 1month -n 3
    2012-01-31T00:00:00Z
    2012-02-29T00:00:00Z
    2012-03-31T00:00:00Z

The time format of the series can be changed using options (-f and -i) and the
print format can be set using arguments. See the Modes and Formats sections
for more details.

    $ timeseries -f

## OPTIONS

These options control how `timeseries` operates:

* `-A`, `--attributes-input`:

  Sets the input mode such that each input line sets the format attributes.
  Each line is expected to be a JSON object.

* `-a`, `--attributes JSON`:

  Set format attributes from a JSON object.

* `-b`, `--boundary-type TYPE`

  Set the boundary type indicating which direction to snap start/stop times
  that do not land on an even period/step boundary when solving for unknowns.
  For example given a period of 1 day and time 2010-01-01T01:00:00Z:

    previous -> 2010-01-01T00:00:00Z
    next     -> 2010-01-02T00:00:00Z

  Boundary types:

    pp            (previous-previous)
    pn, outer     (previous-next)
    np, inner     (next-previous)
    nn            (next-next)
    none

* `--debug`

  Turns on debugging mode.

* `-e`, `--time-format TIME_FORMAT`

  A strftime format indicating how to render times. If format is an integer
  then times will be rendered as iso8601 with the specified precision.

* `-F`, `--format-input`:

  Sets the input mode such that each input line sets the format.

* `-f`, `--format LINE_FORMAT`

  A sprintf format string defining how to render the current step. The fields
  available are the input attributes merged with the step attributes (such
  that the step attributes have precedence). See below.

* `-G`, `--gate-input [TIME_FORMAT]`

  In gate mode **timeseries** treats the specified input attribute as a 'gate'
  whereby all times up to the gate will be printed (ie < for positive periods
  or > for negative periods). The format of the input can be specified as an
  argument, without which **timeseries** will guess according to the input.

  Gate mode assumes `-k`.

* `-g`, `--sync-gate-input [TIME_FORMAT]`

  Same as `-G` but synchronizes the series start time with the first input
  time (other series parameters `-pns` are all respected).

* `-h`, `--help`

  Prints help.

* `-i`, `--iso8601 [PRECSION]`

  Use iso8601 format with the specified precision, by default 0. The `-e` and
  `-i` options are mutually exclusive.

* `-k`, `--blocking`

  In blocking mode **timeseries** only prints when a line is received on
  stdin. The content of the line does not matter unless combined with one of
  the input modes.

* `-l`, `--throttle PERIOD`

  Sleep for PERIOD between each print.

* `-m`, `--stream`

  In stream mode **timeseries** generates times indefinitely.

* `-n`, `--n-steps N`

  Number of steps.

* `-p`, `--period PERIOD`

  The period of the timeseries. Periods can be specified as a number of
  seconds, or using a logical description like '1 month 15 days'. Available
  periods are:

    s sec secs second seconds
    m min minute minutes
    h hr hrs hour hours
    d day days
    w week weeks
    mon month months
    y yr yrs year years

* `-r`, `--realtime`

  In realtime mode **timeseries** throttles to period.

* `-s`, `--start-time TIME`

  Sets the start time for the series.

* `-t`, `--stop-time TIME`

  Sets the stop time for the series.

* `-u`, `--[no-]unbuffer`

  Unbuffer output (default: false).

* `-v`, `--intervals`

  Only print steps where :last_time is present.

* `-W`, `--period-input`

  Treats each input line as a new period for the series (this can be used to
  speed up, slow down, or rewind the series).

* `-z`, `--time-zone ZONE`

  Sets the time zone (default: UTC).
