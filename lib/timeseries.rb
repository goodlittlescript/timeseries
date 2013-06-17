require "active_support/time"
require "timeseries/period"

class Timeseries
  class << self
    # Returns the number of steps from start_time to stop_time (inclusive)
    # given period.  Returns nil if stop_time cannot be reached, for example
    # when stop_time < start_time for a positive period or if period is 0.
    def n_steps(options = {})
      series = new options
      stop_time = options.fetch(:stop_time, series.start_time)
      series.n_steps_to(stop_time)
    end

    def normalize(options)
      options[:n_steps] ||= n_steps(options)
      options
    end
  end

  include Enumerable

  attr_reader :start_time_in_zone
  attr_reader :start_time
  attr_reader :n_steps
  attr_reader :period
  attr_reader :offset
  attr_reader :zone

  # http://www.timeanddate.com/library/abbreviations/timezones/
  def initialize(options = {})
    @start_time = options.fetch(:start_time, Time.now)
    @n_steps    = options.fetch(:n_steps, 0)
    @period     = options.fetch(:period, {})
    @offset     = options.fetch(:offset, 0)
    @zone       = options.fetch(:zone, Time.zone || "UTC")

    @period     = Period.coerce(@period)
    @start_time_in_zone = @start_time.in_time_zone(@zone)
  end

  def at(index)
    Time.use_zone(zone) do
      period_hash = (period * index).data
      start_time_in_zone.advance(period_hash)
    end
  end

  def avg_sec_per_step
    @avg_sec_per_step ||= (at(10) - start_time_in_zone) / 10
  end

  def n_steps_to(stop_time)
    stop_time_in_zone = stop_time.in_time_zone(zone)

    if avg_sec_per_step == 0
      if start_time_in_zone == stop_time_in_zone
        return 0
      else
        raise "empty period"
      end
    end

    # the simple algorithm for n_steps is to start at start_time and advance
    # one-by-one until stop_time, which can be slow for large n.  instead,
    # get an average time-per-period and guess the number of steps in one
    # shot and correct from there.

    n_steps = ((stop_time_in_zone - start_time_in_zone) / avg_sec_per_step).to_i
    current = at(n_steps)

    while increasing? ? current > stop_time_in_zone : current < stop_time_in_zone
      n_steps -= 1
      current = at(n_steps)
    end

    until increasing? ? current > stop_time_in_zone : current < stop_time_in_zone
      n_steps += 1
      current = at(n_steps)
    end

    n_steps
  end

  def increasing?
    @increasing_series ||= at(0) <= at(1)
  end

  # Yields each step to the block, as a UTC time.
  def each
    return to_enum(:each) unless block_given?

    index = offset
    step_size = n_steps < 0 ? -1 : 1

    n_steps.abs.times do
      yield at(index)
      index += step_size
    end
  end
end
