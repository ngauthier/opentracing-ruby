require 'test_helper'

class OpenTracingTest < Minitest::Test
  def test_micros
    assert_equal 946702800000000, OpenTracing.micros(Time.parse("01/01/2000 00:00:00"))
  end

  def test_guid
    g = OpenTracing.guid
    assert_equal 16, g.length
    assert_match /^[a-z0-9]+$/, g
  end
end
