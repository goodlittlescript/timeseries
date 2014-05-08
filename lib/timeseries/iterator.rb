require 'timeseries'

class Timeseries
  class Iterator
    attr_reader :timeseries
    attr_reader :index
    attr_reader :offset
    attr_reader :time
    attr_reader :last_time

    attr_reader :require_last_time
    attr_reader :stream_forever

    def initialize(options = {})
      @timeseries     = Timeseries.create(options)
      @index          = 0
      @offset         = 0
      @time           = timeseries.at(index)
      @last_time      = nil

      @require_last_time = options.fetch(:require_last_time, false)
      @stream_forever = options.fetch(:stream_forever, false)

      advance if require_last_time
    end

    def step_size
      timeseries.period.ref_size
    end

    def advance
      @last_time = @time
      @index += 1
      if stream_forever || index < timeseries.n_steps
        @time = timeseries.at(index)
      else
        @time = nil
      end
    end

    def apparent_index
      index + offset
    end

    def each_until(iteration_stop_time)
      if timeseries.increasing?
        while time && time <= iteration_stop_time
          yield(last_time, time, apparent_index)
          advance
        end
      else
        while time && time >= iteration_stop_time
          yield(last_time, time, apparent_index)
          advance
        end
      end
    end

    def set_period(str)
      if last_time
        timeseries.reconfigure(
          :period     => str,
          :start_time => last_time,
        )
        @offset += (index - 1)
        @index = 1
        @time = timeseries.at(index)
      else
        timeseries.reconfigure(:period => str)
      end
    end
  end
end
