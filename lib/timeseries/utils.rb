class Timeseries
  module Utils
    module_function

    CONFIG_FILE_OPTIONS = %w{start_time period n_steps stop_time}

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

    def load_options(config_file, options)
      settings = File.readlines(config_file).map {|line| line.strip.split("\s", 2) }
      settings.map do |key, value|
        if CONFIG_FILE_OPTIONS.include?(key)
          [key.to_sym, value]
        else
          raise "unknown option in config file: #{key.inspect} (#{config_file.inspect})"
        end
      end
    end
  end
end
