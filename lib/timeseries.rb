require "timeseries/version"
require "active_support/time"
require "strscan"

class Timeseries
  class << self
    # Returns the period type for the period string, as per PERIOD_TYPES.
    def period_type(str)
      PERIOD_TYPES.each_pair do |period_type, variations|
        if variations.include?(str)
          return period_type
        end
      end

      raise "invalid period type: #{str.inspect}"
    end

    # Parse a period string into a period hash.
    #
    #   Timeseries.parse_period("1s2w")        # => {:seconds => 1, :weeks => 2}
    #   Timeseries.parse_period("1sec2weeks")  # => {:seconds => 1, :weeks => 2}
    #
    def parse_period(str)
      period = {}
      scanner = StringScanner.new(str)
  
      begin
        while scanner.skip(/\s*(-?\d+(?:\.\d+)?)?\s*([A-Za-z]+)\s*/)
          value, unit = scanner[1] || "1", scanner[2]

          type = period_type(unit)
          value = value.include?('.') ? Float(value) : Integer(value)

          period[type] = value
        end
        raise unless scanner.eos?
      rescue
        raise "invalid period string: #{str.inspect}"
      end

      period
    end

    # Returns the number of steps from start_time to stop_time (inclusive)
    # given period.  Returns nil if stop_time cannot be reached, for example
    # when stop_time < start_time for a positive period or if period is 0.
    def n_steps(options = {})
      start_time = options.fetch(:start_time, Time.now)
      stop_time  = options.fetch(:stop_time, start_time)
      period     = options.fetch(:period, :seconds => 1)
      zone       = options.fetch(:zone, Time.zone || "UTC")

      # the simple algorithm for n_steps is to start at start_time and advance
      # one-by-one until stop_time, which can be slow for large n.  instead,
      # get an average time-per-period and guess the number of steps in one
      # shot and correct from there.

      Time.use_zone(zone) do
        start_time  = start_time.in_time_zone
        future_time = start_time.advance multiply_period(10, period)
        avg_sec_per_step = (future_time - start_time) / 10

        if avg_sec_per_step == 0
          if start_time == stop_time
            return 0
          else
            raise "empty period"
          end
        end

        n_steps = ((stop_time - start_time) / avg_sec_per_step).to_i
        current = start_time.advance multiply_period(n_steps, period)

        increasing_series = future_time > start_time
        while increasing_series ? current > stop_time : current < stop_time
          current = current.advance reverse_period(period)
          n_steps -= 1
        end

        until increasing_series ? current > stop_time : current < stop_time
          current = current.advance period
          n_steps += 1
        end

        n_steps
      end
    end

    def reverse_period(period)
      multiply_period(-1, period)
    end
  
    def multiply_period(factor, period)
      result = {}
      period.each_pair {|key, value| result[key] = value * factor }
      result
    end
  end

  include Enumerable

  # http://docs.splunk.com/Documentation/Splunk/5.0.2/SearchReference/SearchTimeModifiers
  PERIOD_TYPES = {
    :seconds => %w{s sec secs second seconds},
    :minutes => %w{m min minute minutes},
    :hours   => %w{h hr hrs hour hours},
    :days    => %w{d day days},
    :weeks   => %w{w week weeks},
    :months  => %w{mon month months},
    :years   => %w{y yr yrs year years}
  }

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
  end

  # Yields each step to the block, as a UTC time.
  def each
    return to_enum(:each) unless block_given?

    Time.use_zone(zone) do
      current = start_time.in_time_zone

      offset_period = offset < 0 ? Timeseries.multiply_period(-1, period) : period
      offset.abs.times do
        current = current.advance(offset_period)
      end

      step_period = n_steps < 0 ? Timeseries.multiply_period(-1, period) : period
      n_steps.abs.times do
        yield current
        current = current.advance(step_period)
      end
    end
  end
end
