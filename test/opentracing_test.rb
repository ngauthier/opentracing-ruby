require 'test_helper'

class OpenTracingTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::OpenTracing::VERSION
  end
end
