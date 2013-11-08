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

    def time_formatter(format)
      if format.kind_of?(Integer)
        lambda {|time| time.iso8601(format) }
      else
        lambda {|time| time.strftime(format) }
      end
    end
  end
end
