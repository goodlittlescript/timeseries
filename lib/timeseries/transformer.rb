class Timeseries
  class Transformer
    attr_reader :period
    attr_reader :start_time
    attr_reader :stop_time
    attr_reader :current_time
    attr_reader :last_time

    def initialize(period, start_time = nil, stop_time = nil)
      @period       = period
      @start_time   = start_time
      @stop_time    = stop_time
      @current_time = start_time
    end

    def each_to(input_time)
      if current_time.nil?
        @current_time = input_time
      end

      while (stop_time.nil? || current_time <= stop_time) && current_time <= input_time
        yield(current_time)
        @current_time = current_time.advance(period.data)
      end
    end
  end
end