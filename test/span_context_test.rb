require 'test_helper'

class SpanContextTest < Minitest::Test
  def test_create
    OpenTracing::SpanContext.new(id: "id", trace_id: "trace_id", baggage: {key: "value"})
  end
end
