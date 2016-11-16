require 'simplecov'
SimpleCov.start
SimpleCov.minimum_coverage 100

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'opentracing'

require 'minitest/autorun'
