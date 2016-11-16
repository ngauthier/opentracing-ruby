require 'test_helper'

class SpanTest < Minitest::Test
  def test_attributes
    start = Time.now
    span = span(start_micros: OpenTracing.micros(start))

    assert_equal "operation_name", span.operation_name
    assert_equal OpenTracing.micros(start), span.start_micros
    assert_nil span.end_micros
    assert_equal({}, span.tags)

    context = span.span_context
    assert_equal "trace_id", context.trace_id
    refute_nil context.id
    assert_equal({}, context.baggage)
  end

  def test_tags
    initial_tags = {first: 1}
    span = span(tags: initial_tags)
    assert_equal 1, span.tags[:first]

    span.set_tag(:second, 2)
    assert_equal 2, span.tags[:second]

    span.set_tag(:array, [3])
    assert_equal "[3]", span.tags[:array]
  end

  def test_baggage
    span = span()
    assert_nil span.get_baggage_item(:foo)

    span.set_baggage({foo: :bar})
    assert_equal({foo: :bar}, span.span_context.baggage)
    assert_equal :bar, span.get_baggage_item(:foo)

    span.set_baggage_item(:foo, :baz)
    assert_equal :baz, span.get_baggage_item(:foo)
  end

  def test_log
    log_time = Time.now
    span = span()
    assert_equal 0, span.logs_count
    span.log(event: "event", timestamp: log_time, key: :value)
    assert_equal 1, span.logs_count

    record = span.to_h[:log_records][0]

    assert_equal "event", record[:stable_name]
    assert_equal "nil_tracer_guid", record[:runtime_guid]
    assert_equal OpenTracing.micros(log_time), record[:timestamp_micros]
    assert_equal({"key" => "value"}, JSON.parse(record[:payload_json]))
  end

  def test_drop_logs_over_max
    span = span(max_log_records: 1)
    span.log(event: "first")
    span.log(event: "second")

    assert_equal 1, span.dropped_logs_count
    assert_equal "second", span.to_h[:log_records][0][:stable_name]
  end

  def test_finish_nil
    end_time = Time.now
    span = span()
    span.finish(end_time: end_time)
    assert_equal OpenTracing.micros(end_time), span.end_micros
  end

  def test_double_finish
    first_time = Time.now
    second_time = Time.gm(2000)
    span = span()
    span.finish(end_time: first_time)
    span.finish(end_time: second_time)
    assert_equal OpenTracing.micros(first_time), span.end_micros
  end

  def test_finish_mock
    tracer = Minitest::Mock.new
    span = span(tracer: tracer)
    tracer.expect(:finish_span, nil, [span])
    span.finish
  end

  def test_to_h
    start_time = Time.gm(2000)
    end_time = Time.gm(2001)
    span = span(tags: {key: :value}, start_micros: OpenTracing.micros(start_time))
    span.finish(end_time: end_time)
    assert_equal({
      runtime_guid: "nil_tracer_guid",
      span_guid: span.span_context.id,
      trace_guid: "trace_id",
      span_name: "operation_name",
      attributes: [{Key: "key", Value: :value}],
      oldest_micros: OpenTracing.micros(start_time),
      youngest_micros: OpenTracing.micros(end_time),
      error_flag: false,
      dropped_logs: 0,
      log_records: []
    }, span.to_h)
  end

  private

  def span(
    tracer: OpenTracing::NilTracer.new,
    operation_name: "operation_name",
    trace_id: "trace_id",
    start_micros: OpenTracing.micros(Time.now),
    max_log_records: 10_000,
    tags: nil
  )
    OpenTracing::Span.new(
      tracer: tracer,
      operation_name: operation_name,
      trace_id: trace_id,
      start_micros: start_micros,
      tags: tags,
      max_log_records: max_log_records
    )
  end
end
