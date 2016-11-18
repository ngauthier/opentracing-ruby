module OpenTracing
  # SpanContext holds the data for a span that gets inherited to child spans
  class SpanContext
    attr_reader :id, :trace_id, :baggage

    # Create a new SpanContext
    # @param id the ID of the Context
    # @param trace_id the ID of the current trace
    # @param baggage baggage
    def initialize(id:, trace_id:, baggage: {})
    end
  end
end
