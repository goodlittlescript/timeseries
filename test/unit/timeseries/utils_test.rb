require File.expand_path("../../helper", __FILE__)
require "timeseries/utils"

class UtilsTest < Test::Unit::TestCase
  include Timeseries::Utils

  def setup
    @current_zone = Time.zone
    Time.zone = "UTC"
  end

  def teardown
    Time.zone = @current_zone
  end

  #
  # coerce
  #

  def test_coerce_returns_TimeWithZone
    obj = Time.zone.parse "2010-01-01 00:00:00"
    time = coerce obj
    assert_equal obj.object_id, time.object_id
  end

  def test_coerce_String
    time = coerce "2010-01-01 00:00:00"
    assert time.kind_of?(ActiveSupport::TimeWithZone)
    assert_equal("2010-01-01 00:00:00 UTC", time.strftime("%Y-%m-%d %H:%M:%S %Z"))
  end

  def test_coerce_using_to_time
    obj = Object.new
    def obj.to_time
      Time.parse "2010-01-01 00:00:00 UTC"
    end
    time = coerce obj

    assert time.kind_of?(ActiveSupport::TimeWithZone)
    assert_equal(Time.zone, time.time_zone)
    assert_equal("2010-01-01 00:00:00 UTC", time.strftime("%Y-%m-%d %H:%M:%S %Z"))
  end

  def test_coerce_raises_error_if_obj_cannot_be_coerced
    obj = Object.new
    err = assert_raises(RuntimeError) { coerce(obj) }
    assert_equal "cannot coerce to TimeWithZone: #{obj.inspect}", err.message
  end
end
