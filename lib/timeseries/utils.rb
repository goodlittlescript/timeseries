require "active_support/time"

class Timeseries
  module Utils
    module_function

    def coerce(obj)
      case obj
      when ActiveSupport::TimeWithZone then obj
      when String then Time.zone.parse(obj)
      else
        if obj.respond_to?(:to_time)
          obj.to_time.in_time_zone
        else
          raise "cannot coerce to TimeWithZone: #{obj.inspect}"
        end
      end
    end

    def time_parser(format = nil)
      case format
      when Integer
        # as of this date using %3N (for example) raises an invalid strptime
        # format but the default should be fine in all cases as it represents
        # the max available
        lambda {|str| Time.strptime(str, "%Y-%m-%dT%H:%M:%S.%N%z") }
      when nil
        lambda {|str| Time.zone.parse(str) }
      else
        lambda {|str| Time.strptime(str, format) }
      end
    end

    def time_formatter(format = nil)
      case format
      when Integer
        lambda {|time| time.iso8601(format) }
      when nil
        lambda {|time| time.to_s }
      else
        lambda {|time| time.strftime(format) }
      end
    end
  end
end
