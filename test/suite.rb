#!/usr/bin/env ruby
test_files = Dir.glob File.expand_path("../**/*_test.rb", __FILE__)
test_files.each {|file| require file }
