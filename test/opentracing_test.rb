require 'test_helper'
require 'net/http'

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

  def test_inject_text_map
    context = OpenTracing::SpanContext.new(id: "id", trace_id: "trace_id", baggage: {key: :value})
    carrier = {}
    OpenTracing.inject(context, OpenTracing::FORMAT_TEXT_MAP, carrier)
    assert_equal({
      "ot-tracer-spanid" => "id",
      "ot-tracer-traceid" => "trace_id",
      "ot-tracer-sampled" => "true",
      "ot-baggage-key" => "value"
    }, carrier)
  end

  def test_inject_binary
    assert_warn "Binary inject format not yet implemented\n" do
      OpenTracing.inject(nil, OpenTracing::FORMAT_BINARY, nil)
    end
  end

  def test_inject_rack
    context = OpenTracing::SpanContext.new(id: "id", trace_id: "trace_id", baggage: {
      "key" => "value",
      "Invalid%^&*%" => "dropped"
    })
    carrier = Net::HTTP::Post.new("/")
    OpenTracing.inject(context, OpenTracing::FORMAT_RACK, carrier)
    assert_equal carrier["ot-tracer-spanid"], "id"
    assert_equal carrier["ot-tracer-traceid"], "trace_id"
    assert_equal carrier["ot-tracer-sampled"], "true"
    assert_equal carrier["ot-baggage-key"], "value"
    assert_nil carrier["ot-baggage-Invalid%^&*%"]
    assert_nil carrier["ot-baggage-invalid%^&*%"]
    assert_nil carrier["ot-baggage-invalid"]
  end

  def test_invalid_inject_format
    assert_warn "Unknown inject format\n" do
      OpenTracing.inject(nil, 9999, nil)
    end
  end

  def test_extract_text_map
    tracer = Minitest::Mock.new
    carrier = {
      "ot-tracer-spanid" => "id",
      "ot-tracer-traceid" => "trace_id",
      "ot-tracer-sampled" => "true",
      "ot-baggage-key" => "value"
    }
    span = OpenTracing.extract("operation_name", OpenTracing::FORMAT_TEXT_MAP, carrier, tracer)
    context = span.span_context
    refute_nil context.id
    assert_equal "id", span.tags[:parent_span_guid]
    assert_equal "trace_id", context.trace_id
    assert_equal "value", context.baggage["key"]
  end

  def test_extract_binary
    assert_warn "Binary extract format not yet implemented\n" do
      OpenTracing.extract(nil, OpenTracing::FORMAT_BINARY, nil, nil)
    end
  end

  def test_extract_rack
    tracer = Minitest::Mock.new
    carrier = {
      "OT_TRACER_SPANID" => "id",
      "OT_TRACER_TRACEID" => "trace_id",
      "OT_TRACER_SAMPLED" => "true",
      "OT_BAGGAGE_KEY" => "value"
    }
    span = OpenTracing.extract("operation_name", OpenTracing::FORMAT_RACK, carrier, tracer)
    context = span.span_context
    refute_nil context.id
    assert_equal "id", span.tags[:parent_span_guid]
    assert_equal "trace_id", context.trace_id
    assert_equal "value", context.baggage["key"]
  end

  def test_extract_unknown
    assert_warn "Unknown extract format\n" do
      OpenTracing.extract(nil, 999, nil, nil)
    end
  end

  private

  def assert_warn(msg, &block)
    original_stderr = $stderr
    begin
      str = StringIO.new
      $stderr = str
      block.call
      assert_equal msg, str.string
    ensure
      $stderr = original_stderr
    end
  end
end
