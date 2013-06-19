require "active_support/time"
require "strscan"

class Timeseries
  class Period
    class << self
      def coerce(obj)
        case obj
        when Period  then obj
        when Hash    then new(obj)
        when String  then parse(str)
        when Numeric then new(:seconds => obj)
        else raise "cannot coerce to Period: #{obj.inspect}"
        end
      end

      # Returns the period type for the period string, as per PERIOD_TYPES.
      def period_type(str)
        PERIOD_TYPES.each_pair do |type, variations|
          if variations.include?(str)
            return type
          end
        end

        raise "invalid period type: #{str.inspect}"
      end

      # Parse a period string into a period.
      #
      #   Timeseries.parse("1s2w").data        # => {:seconds => 1, :weeks => 2}
      #   Timeseries.parse("1sec2weeks").data  # => {:seconds => 1, :weeks => 2}
      #
      def parse(str)
        data = {}
        scanner = StringScanner.new(str)

        begin
          while scanner.skip(/\s*(-?\d+(?:\.\d+)?)?\s*([A-Za-z]+)\s*/)
            value, unit = scanner[1] || "1", scanner[2]

            type = period_type(unit)
            value = value.include?('.') ? Float(value) : Integer(value)

            data[type] = value
          end
          raise unless scanner.eos?
        rescue
          raise "invalid period string: #{str.inspect}"
        end

        new data
      end
    end

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

    attr_reader :data

    def initialize(data)
      @data = data
    end

    def initialize_copy(source)
      super
      @data = @data.dup
    end

    def reverse!
      multiply(-1)
    end

    def reverse
      dup.reverse!
    end

    def multiply!(factor)
      new_data = {}
      data.each_pair {|key, value| new_data[key] = value * factor }
      data.replace(new_data)
      self
    end

    def multiply(factor)
      dup.multiply!(factor)
    end
    alias * multiply

    # Backs up time to the previous grid boundary for a time series of the
    # current period.  Times already on a grid boundary are not changed.
    #
    #   time = Time.parse("2010-01-01 01:23:55")
    #   period = Period.new(:minutes => 15)
    #   period.snap_previous(time)  # => Time.parse("2010-01-01 01:15:00")
    #
    # Currently only works for hours/minutes/seconds.
    def snap_previous(time)
      time.advance(snap_delta(time).data).change(:usec => 0)
    end

    # Advances time to the next grid boundary for a time series of the current
    # period.  Times already on a grid boundary are not changed.
    #
    #   time = Time.parse("2010-01-01 01:23:55")
    #   period = Period.new(:minutes => 15)
    #   period.snap_next(time)  # => Time.parse("2010-01-01 01:30:00")
    #
    # Currently only works for hours/minutes/seconds.
    def snap_next(time)
      grid_time = snap_previous(time)
      grid_time == time ? grid_time : grid_time.advance(data)
    end

    # Returns a new period that would advance time to the previous natural
    # grid boundary, as per snap.
    def snap_delta(time)
      delta = self.class.new(
        :hours   => time.hour,
        :minutes => time.min,
        :seconds => time.sec
      )

      period_types = [:seconds, :minutes, :hours]
      while period_type = period_types.shift
        next unless data.has_key?(period_type)

        delta.data[period_type] = delta.data[period_type] % data[period_type]
        period_types.each {|pt| delta.data[pt] = 0 }
      end

      delta.reverse!
    end
  end
end
