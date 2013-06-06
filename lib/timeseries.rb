require 'active_support/time'
require "timeseries/version"

# Use like 
#
#   now = Time.parse("09:00")
#   series = TimeSeries.new(:start_time => now, :n_steps => 10, :period => {:minutes => 15})
#   series.each {|time| puts time }
#
# options
#
#   start_time
#   stop_time
#   n_steps = 1             # stop_time or n_steps may be specified
#   period = 1              # {:years, :months, :weeks, :days, :hours, :minutes, :seconds} - number defaults to {:seconds => number}
#   offset = 0              # {:years, :months, :weeks, :days, :hours, :minutes, :seconds} - number defaults to {:seconds => number}
#   include_start = false   # >
#   include_stop  = true    # <=
#
class Timeseries
  include Enumerable

  attr_reader :start_time
  attr_reader :period
  attr_reader :offset
  attr_reader :include_start
  attr_reader :include_stop

  def initialize(options={})
    period  = options.fetch(:period, 1)
    @period = to_advance_options(period) or raise "invalid period: #{options[:period]}"

    offset  = options.fetch(:offset, 0)
    @offset = to_advance_options(offset) or raise "invalid period: #{options[:offset]}"

    @start_time = options.fetch(:start_time, Time.now)
    case
    when !options[:stop_time].present?
      @n_steps   = options.fetch(:n_steps, 1)
    when !options[:n_steps].present?
      @stop_time = options.fetch(:stop_time)
    else
      raise "cannot specify both stop_time and n_steps"
    end

    @increasing = @start_time.advance(@period) > @start_time ? true : false
    if @stop_time && (@increasing ? @start_time > @stop_time : @start_time < @stop_time)
      if @increasing
        raise "invalid start/stop times: #{start_time} > #{stop_time}"
      else
        raise "invalid start/stop times: #{start_time} < #{stop_time} (decreasing series)"
      end
    end

    @include_stop  = options.fetch(:include_stop, false)
    @include_start = options.fetch(:include_start, true)
  end

  def n_steps
    derive_values unless @n_steps
    @n_steps
  end
  alias length n_steps
  alias size n_steps

  def stop_time
    derive_values unless @stop_time
    @stop_time
  end

  def increasing?
    @increasing
  end

  def decreasing?
    !increasing?
  end

  def after_start?(time)
    if increasing?
      include_start ? time >= start_time : time > start_time
    else
      include_start ? time <= start_time : time < start_time
    end
  end

  def before_start?(time)
    !after_start?(time)
  end

  def before_end?(time)
    if increasing?
      include_stop ? time <= stop_time  : time < stop_time
    else
      include_stop ? time >= stop_time  : time > stop_time
    end
  end

  def after_end?(time)
    !before_end?(time)
  end

  def include?(time)
    after_start?(time) && before_end?(time)
  end

  # Returns an array of time steps
  def steps
    map.to_a
  end

  # Yields each step to the block.
  def each
    current = start_time.advance(offset)

    while before_start?(current)
      current = current.advance(period)
    end

    if @n_steps
      @n_steps.times do
        yield current
        current = current.advance(period)
      end
    else
      until after_end?(current)
        yield current
        current = current.advance(period)
      end
    end
  end

  private

  def derive_values
    size = 0
    last = nil
    each do |value|
      size += 1
      last = value
    end
    @n_steps   ||= size
    @stop_time ||= include_stop ? last : last.advance(period)
  end

  def to_advance_options(value)
    case value
    when Hash    then value
    when Numeric then {:seconds => value}
    else nil
    end
  end
end
