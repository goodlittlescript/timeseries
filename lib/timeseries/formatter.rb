require 'timeseries/utils'

class Timeseries
  class Formatter
    class << self
      def default_options
        @default_options ||= {}
      end

      protected

      def option(field, default = nil)
        default_options[field] = default
        class_eval %{
          def #{field}; options[:#{field}]; end
          def #{field}=(value); options[:#{field}] = value; end
        }
      end
    end

    option :step
    option :index, 0
    option :time
    option :last_index
    option :last_time
    option :continue_time
    option :range, false

    attr_reader :timeseries
    attr_reader :options
    attr_reader :limit
    attr_reader :queue

    def initialize(timeseries, options = {})
      @timeseries = timeseries
      @options = options.replace(self.class.default_options.merge(options))
      format = options[:format]
      @time_formatter = Timeseries::Utils.time_formatter(format)

      @limit = options.fetch(:limit, timeseries.n_steps)

      @queue = options[:queue]
    end

    def format_time(time)
      @time_formatter.call(time)
    end

    def advance_to(time, index)
      self.last_index = self.index
      self.last_time  = self.time
      self.index      = index
      self.time       = format_time(time)

      # note I think there is a race condition whereby if the program exits
      # abnormally after this is set but before any times are printed then, upon
      # restart, the continue time will never be printed.
      self.step       = time
    end

    def print_options
      if range
        last_time ? options : nil
      else
        options
      end
    end

    def each
      unless block_given?
        return enum_for(:each, limit)
      end

      while limit.nil? || index < limit
        step = timeseries.at(index)
        advance_to(step, index)

        if opts = print_options
          yield opts
        end

        if queue
          new_period = nil
          until queue.empty?
            new_period = queue.shift
          end

          if new_period
            timeseries.reconfigure(:period => new_period, :start_time => step)
            self.index = 1
          end
        else
          self.index += 1
        end
      end
    end
  end
end