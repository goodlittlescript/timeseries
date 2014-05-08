#!/usr/bin/env ruby
require File.expand_path("../../helper", __FILE__)
require "timeseries/iterator"

class IteratorTest < Test::Unit::TestCase
  Iterator = Timeseries::Iterator

  def setup
    @current_zone = Time.zone
    Time.zone = "UTC"
  end

  def teardown
    Time.zone = @current_zone
  end

  def test_initialize_creates_timeseries
    iterator = Iterator.new
    assert_equal "1s", iterator.timeseries.period.to_s
  end

  def test_initialize_sets_index_0
    iterator = Iterator.new
    assert_equal 0, iterator.index
  end
end
