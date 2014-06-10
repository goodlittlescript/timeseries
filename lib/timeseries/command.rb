require 'timeseries/iterator'
require 'thread'
require 'json'
require 'yaml'

class Timeseries
  class Command
    class << self
      def load_attrs(str)
        attributes = {}
        # keys must be symbolized for sprintf
        JSON.load(str).each_pair do |key, value|
          attributes[key.to_sym] = value
        end
        attributes
      end

      def load_cycle_file(file)
        lines = []
        settings_lines = []
        parsing_settings = false

        File.open(file) do |io|
          while line = io.gets
            if line.strip == '---'
              parsing_settings = !parsing_settings
              next
            end

            if parsing_settings
              settings_lines << line
            else
              line = line.strip.sub(/#.*/, '')
              lines << line unless line.empty?
            end
          end
        end

        settings = YAML.load(settings_lines.join("\n")) || {}
        valid_keys = %w{options headers fields}
        invalid_keys = valid_keys - valid_keys
        unless invalid_keys.empty?
          raise "invalid keys in settings: #{invalid_keys.inspect} (#{file.inspect})"
        end

        options = settings.fetch('options', {})
        header_keys = settings.fetch('headers', []).map(&:to_sym)
        substitutes = {"-" => nil, "." => {:field => ""}}
        # because YAML might load non-string values
        settings.fetch('fields', {}).each_pair do |key, value|
          substitutes[key.to_s] = \
          case value
          when Hash
            attrs = {:field => key.to_s}
            value.each_pair do |k, v|
              attrs[k.to_sym] = v.to_s
            end
            attrs
          else {:field => value.to_s}
          end
        end

        headers = []
        lines.map! do |line|
          fields = line.split(/\s+/)
          header_values = fields.shift(header_keys.length)
          headers << Hash[header_keys.zip(header_values)]
          fields
        end

        attributes = []
        lines.transpose.each do |fields|
          attributes << parse_attributes(fields, headers, substitutes)
        end

        overrides = {}
        options.each_pair do |key, value|
          overrides[key.to_sym] = value
        end
        overrides[:attributes] = attributes
        overrides
      end

      def parse_attributes(fields, headers = [], substitutes = {})
        attributes = []
        fields.each_with_index do |field, index|
          attrs = substitutes.fetch(field) { {:field => field} }
          next if attrs.nil?

          base_attrs = headers[index] || {}
          data_attrs = {:field_index => index}.merge(attrs)

          attributes << base_attrs.merge(data_attrs)
        end
        attributes
      end

      def io_queue(io)
        queue = Queue.new

        Thread.new do
          while line = io.gets
            queue.push line
          end
          queue.push nil
        end

        queue.instance_eval %{
          def gets
            line = NODATA
            line = pop until empty?
            line
          end
        }
        queue
      end
    end

    EOF = Object.new
    NODATA = Object.new

    attr_reader :attributes
    attr_reader :blocking
    attr_reader :input_mode
    attr_reader :input_time_format
    attr_reader :output_time_format
    attr_reader :format
    attr_reader :throttle
    attr_reader :series_options

    def initialize(options = {})
      @attributes     = options.fetch(:attributes, nil)
      @blocking       = options.fetch(:blocking, options.has_key?(:input_mode))
      @input_mode     = options.fetch(:input_mode, nil)
      @input_time_format = options.fetch(:input_time_format, nil)
      @output_time_format = options.fetch(:output_time_format, 0)
      @format    = options.fetch(:format, "%{time}")
      @throttle       = options.fetch(:throttle, nil)
      @series_options = options
    end

    def process(stdin, stdout)
      iterator = \
      case
      when input_mode == :sync_gate
        line = NODATA
        until line != NODATA
          line = read_line(stdin)
        end
        if line == EOF
          return
        end
        start_time = parse_time(line)
        Iterator.new(series_options.merge(:start_time => start_time))
      when input_mode == :cycle_data || input_mode == :sync_cycle_data
        stdin = input_mode == :sync_cycle_data ? (Array.new(attributes.length, NODATA) + [EOF]).each : [NODATA].cycle
        stdin.instance_eval %{
          def gets
            self.next
          end
        }
        @attributes = attributes.cycle
        Iterator.new(series_options)
      else
        Iterator.new(series_options)
      end

      unless blocking || (input_mode == :cycle_data || input_mode == :sync_cycle_data)
        stdin = self.class.io_queue(stdin)
      end

      while gate_time = iterator.time

        line ||= read_line(stdin)
        case
        when line == NODATA
          # do nothing
        when line == EOF
          break if blocking || input_mode
        when input_mode == :attributes
          @attributes = self.class.load_attrs(line)
        when input_mode == :format
          @format = line
        when input_mode == :period
          iterator.set_period(line)
          gate_time = iterator.time
        when input_mode == :gate || input_mode == :sync_gate 
          gate_time = parse_time(line)
        end

        iterator.each_until(gate_time) do |last_time, time, index|
          each_attrs(last_time, time, index) do |attrs|
            stdout.puts(format % attrs)
          end

          if throttle
            sleep(throttle == :realtime ? iterator.step_size : throttle)
          end
        end

        line = nil
      end

      self
    end

    def read_line(io)
      line = io.gets
      case line
      when /\A\s*\z/ then NODATA
      when nil then EOF
      else line
      end
    end

    # Implementes ActiveSupport::TimeZone#parse but using Date._strptime
    # instead of Date._parse, to give the analagous behavior.
    #
    #   require 'timeseries/command' => true
    #   Time.zone = 'MST7MDT' => "MST7MDT"
    #   Time.zone.parse('2010-11-07 01:00') => Sun, 07 Nov 2010 01:00:00 MDT -06:00
    #   Time.zone.parse('2010-11-07 02:00') => Sun, 07 Nov 2010 02:00:00 MST -07:00
    #   command = Timeseries::Command.new
    #   command.time_zone_strptime('01:00 2010-11-07', '%H:%M %Y-%m-%d') => Sun, 07 Nov 2010 01:00:00 MDT -06:00
    #   command.time_zone_strptime('02:00 2010-11-07', '%H:%M %Y-%m-%d') => Sun, 07 Nov 2010 02:00:00 MST -07:00
    #
    # Motivated by this not working:
    #
    #   Time.strptime('01:00 2010-11-07', '%H:%M %Y-%m-%d').in_time_zone => Sun, 07 Nov 2010 01:00:00 MST -07:00
    #   Time.strptime('02:00 2010-11-07', '%H:%M %Y-%m-%d').in_time_zone => Sun, 07 Nov 2010 02:00:00 MST -07:00
    #
    # This should be made into a patch for ActiveSupport.
    def time_zone_strptime(str, format, now = Time.zone.now)
      parts = Date._strptime(str, format)
      return if parts.empty?

      # https://www.ruby-forum.com/topic/4591844
      if parts.has_key?(:seconds)
        time = Time.zone.at(parts[:seconds])
      elsif parts.has_key?(:leftover)
        seconds = (parts.fetch(:sec, "0").to_s + parts.fetch(:leftover, "0")).to_i
        time = Time.zone.at(seconds)
      else
        time = Time.new(
          parts.fetch(:year, now.year),
          parts.fetch(:mon, now.month),
          parts.fetch(:mday, now.day),
          parts.fetch(:hour, 0),
          parts.fetch(:min, 0),
          parts.fetch(:sec, 0) + parts.fetch(:sec_fraction, 0),
          parts.fetch(:offset, 0)
        )
      end

      if parts[:offset]
        ActiveSupport::TimeWithZone.new(time.utc, Time.zone)
      else
        ActiveSupport::TimeWithZone.new(nil, Time.zone, time)
      end
    end

    def parse_time(str)
      case input_time_format
      when Integer
        # as of this date using %3N (for example) raises an invalid strptime
        # format but the default should be fine in all cases as it represents
        # the max available
        time_zone_strptime(str, "%Y-%m-%dT%H:%M:%S.%N%z")
      when nil
        Time.zone.parse(str)
      else
        time_zone_strptime(str, input_time_format)
      end
    end

    def format_time(time)
      return nil if time.nil?

      case output_time_format
      when Integer
        time.iso8601(output_time_format)
      when nil
        time.to_s
      else
        time.strftime(output_time_format)
      end
    end

    def each_attrs(last_time, time, index)
      if last_time == @time
        @last_time_str = @time_str
      else
        @last_time_str = format_time(last_time)
      end

      @time_str = format_time(time)
      @time = time

      base_attrs = {
        :last_time => @last_time_str,
        :time      => @time_str,
        :index     => index,
      }

      case attributes
      when nil
        yield base_attrs
      when Hash
        yield attributes.merge(base_attrs)
      when Array
        attributes.each do |attrs|
          yield attrs.merge(base_attrs)
        end
      when Enumerator
        next_attrs = attributes.next || []
        next_attrs.each do |attrs|
          yield attrs.merge(base_attrs)
        end
      end
    end
  end
end
