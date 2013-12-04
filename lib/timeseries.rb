require "timeseries/period"
require "timeseries/utils"
require "timeseries/transformer"

# Use factory method `create` to build a new Timeseries, unless you truely know
# your arguments are complete
class Timeseries
  class << self
    def create(options = {})
      new(normalize(options))
    end

    def normalize(options)
      options = coerce_to_options(options)

      if start_time = options[:start_time]
        options[:start_time] = Utils.coerce(start_time)
      end

      if stop_time = options[:stop_time]
        options[:stop_time] = Utils.coerce(stop_time)
      end

      if period = options[:period]
        options[:period] = Period.coerce(period)
      end

      available_keys = options.keys.select {|key| options[key].present? }
      available_keys = SIGNATURE_KEYS & available_keys
      signature = options.fetch(:signature) { SIGNATURE_KEYS & available_keys }
      signature = SIGNATURE_KEYS & signature

      signature = normalize_signature(signature, available_keys)
      solver(signature).call(options)
    end

    def normalize_signature(signature, available_keys)
      # the goal here is to add to the signature available keys, in order, up
      # to the solvable level of 3.  this allows a partial signature to be
      # provided that will use default values in options, if available.
      if signature.length < 3
        prioritized_keys = (SIGNATURE_KEYS - signature) & available_keys
        SIGNATURE_KEYS & signature.concat(prioritized_keys)[0, 3]
      else
        signature
      end
    end

    def solver(signature)
      case signature
      when [                                          ] then method(:solve_stop_time)
      when [:start_time                               ] then method(:solve_stop_time)
      when [             :stop_time                   ] then
      when [                         :period          ] then method(:solve_stop_time)
      when [                                  :n_steps] then method(:solve_stop_time)
      when [:start_time, :stop_time,                  ] then method(:solve_n_steps)
      when [:start_time,             :period          ] then method(:solve_stop_time)
      when [:start_time,                      :n_steps] then method(:solve_stop_time)
      when [             :stop_time, :period          ] then
      when [             :stop_time,          :n_steps] then
      when [                         :period, :n_steps] then method(:solve_stop_time)
      when [:start_time, :stop_time, :period          ] then method(:solve_n_steps)
      when [:start_time, :stop_time,          :n_steps] then
      when [:start_time,             :period, :n_steps] then method(:solve_stop_time)
      when [             :stop_time, :period, :n_steps] then
      when [:start_time, :stop_time, :period, :n_steps] then raise "too much information"
      end or raise "unable to solve #{signature.join(',')}"
    end

    def default_start_time
      Time.zone.now
    end

    def default_period
      Period.new(:seconds => 1)
    end

    def default_n_steps
      nil
    end

    private

    def coerce_to_options(obj)
      case obj
      when Hash   then symbolize(obj)
      when String then {:period => obj}
      else raise "cannot coerce to options: #{obj.inspect}"
      end
    end

    def symbolize(hash)
      result = {}
      CREATE_KEYS.each do |key|
        value = hash[key] || hash[key.to_s]
        result[key] = value if value
      end
      result
    end

    def set_defaults(options)
      options[:start_time] ||= default_start_time
      options[:period]     ||= default_period
      options[:n_steps]    ||= default_n_steps
      options
    end

    def solve_n_steps(options)
      options = set_defaults(options)
      options[:start_time] = snap_time(*options.values_at(:period, :start_time, :snap_start_time))
      options[:stop_time]  = snap_time(*options.values_at(:period, :stop_time,  :snap_stop_time))
      options[:n_steps]    = new(options).n_steps_to(options[:stop_time])
      options
    end

    def solve_stop_time(options)
      options = set_defaults(options)
      options[:start_time] = snap_time(*options.values_at(:period, :start_time, :snap_start_time))
      options
    end

    def snap_time(period, time, snap_type)
      return nil if time.nil?

      case snap_type
      when :previous then period.snap_previous(time)
      when :next     then period.snap_next(time)
      when nil       then time
      else raise "invalid snap type: #{snap_type.inspect}"
      end
    end
  end

  SIGNATURE_KEYS = [:start_time, :stop_time, :period, :n_steps]
  CREATE_KEYS = SIGNATURE_KEYS + [:snap_start_time, :snap_stop_time, :signature]

  include Enumerable

  attr_reader :start_time
  attr_reader :n_steps
  attr_reader :period

  # http://www.timeanddate.com/library/abbreviations/timezones/
  def initialize(options = {})
    @start_time = options.fetch(:start_time) { self.class.default_start_time }
    @n_steps    = options.fetch(:n_steps)    { self.class.default_n_steps }
    @period     = options.fetch(:period)     { self.class.default_period }

    unless @start_time.kind_of?(ActiveSupport::TimeWithZone)
      raise "invalid start_time: #{@start_time.inspect} (must be a TimeWithZone)"
    end
    @period = Period.coerce(@period)
  end

  def zone
    start_time.time_zone
  end

  def at(index)
    period_hash = (period * index).data
    start_time.advance(period_hash)
  end

  def stop_time
    case
    when n_steps.nil? then nil
    when n_steps > 0  then at(n_steps - 1)
    when n_steps < 0  then at(n_steps + 1)
    when n_steps == 0 then start_time
    end
  end

  def avg_sec_per_step
    @avg_sec_per_step ||= (at(10) - start_time) / 10
  end

  def n_steps_to(stop_time)
    stop_time = stop_time.in_time_zone(zone)

    if avg_sec_per_step == 0
      if start_time == stop_time
        return 0
      else
        raise "empty period"
      end
    end

    # the simple algorithm for n_steps is to start at start_time and advance
    # one-by-one until stop_time, which can be slow for large n.  instead,
    # get an average time-per-period and guess the number of steps in one
    # shot and correct from there.

    n_steps = ((stop_time - start_time) / avg_sec_per_step).to_i
    if n_steps < 0
      if increasing?
        raise "cannot solve for n_steps (start_time > stop_time with positive period)"
      else
        raise "cannot solve for n_steps (stop_time > start_time with negative period)"
      end
    end
    current = at(n_steps)

    while increasing? ? current > stop_time : current < stop_time
      n_steps -= 1
      current = at(n_steps)
    end

    until increasing? ? current > stop_time : current < stop_time
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

    index = 0
    if n_steps
      step_size = n_steps < 0 ? -1 : 1
      n_steps.abs.times do
        yield at(index)
        index += step_size
      end
    else
      loop do
        yield at(index)
        index += 1
      end
    end
  end

  def transformer(options = {})
    start_time = options.fetch(:start_time, self.start_time)
    stop_time = options.fetch(:stop_time, self.stop_time)
    Transformer.new(period, start_time, stop_time)
  end

  def offset(n)
    self.class.new(:start_time => at(n), :period => period, :n_steps => n_steps)
  end

  def collate(data, options = {}) # :yields: previous, current
    format = options.fetch(:format, nil)
    interval_type = options.fetch(:interval_type, :ending)

    pairs = pair_data(data)

    case interval_type
    when :ending    then offset = 1
    when :beginning then offset = 0
    else raise "invalid interval_type: #{interval_type.inspect}"
    end

    intervals = {}
    pairs.each_with_index do |interval, index|
      step_time = at(index + offset)
      key = format ? step_time.strftime(format) : step_time
      intervals[key] = block_given? ? yield(*interval) : interval
    end
    intervals
  end

  def intervals(options = {})
    raise "unavailable for infinie series" if n_steps.nil?
    intervals = pair_data(self)

    if format = options.fetch(:format, nil)
      intervals.each do |times|
        times.map! do |time|
          time.strftime(format)
        end
      end
    end

    intervals
  end

  private

  def pair_data(data)
    pairs = []
    data.each_with_index do |datum, index|
      pairs[index] = [datum]
      pairs[index - 1] << datum if index > 0
    end
    pairs.pop
    pairs
  end
end
