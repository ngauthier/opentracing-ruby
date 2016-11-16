require 'test_helper'

class SpanContextTest < Minitest::Test
  def test_attributes
    sc = OpenTracing::SpanContext.new(id: "id", trace_id: "trace_id", baggage: {key: "value"})
    assert_equal "id", sc.id
    assert_equal "trace_id", sc.trace_id
    assert_equal "value", sc.baggage[:key]
  end

  def test_frozen
    sc = OpenTracing::SpanContext.new(id: "id", trace_id: "trace_id", baggage: {key: "value"})
    assert_raises { sc.id.slice!(0,1) }
    assert_raises { sc.trace_id.slice!(0,1) }
    assert_raises { sc.baggage[:key] = "change" }
  end
end
