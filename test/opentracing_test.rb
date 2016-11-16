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

  def test_global_tracer
    assert_nil OpenTracing.global_tracer
    tracer = Minitest::Mock.new
    OpenTracing.global_tracer = tracer

    span = Minitest::Mock.new
    tracer.expect(:start_span, span, ["span"])
    span = OpenTracing.start_span("span")
  end
end
