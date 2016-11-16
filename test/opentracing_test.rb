require 'test_helper'

class OpenTracingTest < Minitest::Test
  def test_micros
    assert_equal 946684800000000, OpenTracing.micros(Time.gm(2000))
  end

  def test_guid
    g = OpenTracing.guid
    assert_equal 16, g.length
    assert_match /^[a-z0-9]+$/, g
  end
end
