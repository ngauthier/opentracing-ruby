require "forwardable"
require "concurrent"
require "opentracing/version"
require "opentracing/span_context"
require "opentracing/span"
require "opentracing/nil_tracer"

module OpenTracing
  FORMAT_TEXT_MAP = 1
  FORMAT_BINARY = 2
  FORMAT_RACK = 3

  class << self
    extend Forwardable
    # Global tracer to be used when OpenTracing.start_span is called
    attr_accessor :global_tracer
    def_delegator :global_tracer, :start_span


    # Inject a span into the given carrier
    # @param span_context [SpanContext]
    # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
    # @param carrier [Hash]
    def inject(span_context, format, carrier)
      case format
      when OpenTracing::FORMAT_TEXT_MAP
        inject_to_text_map(span_context, carrier)
      when OpenTracing::FORMAT_BINARY
        warn 'Binary inject format not yet implemented'
      when OpenTracing::FORMAT_RACK
        inject_to_rack(span_context, carrier)
      else
        warn 'Unknown inject format'
      end
    end

    # Extract a span from a carrier
    # @param operation_name [String]
    # @param format [OpenTracing::FORMAT_TEXT_MAP, OpenTracing::FORMAT_BINARY, OpenTracing::FORMAT_RACK]
    # @param carrier [Hash]
    # @param tracer [Tracer] the tracer the span will be attached to (for finish)
    # @return [Span]
    def extract(operation_name, format, carrier, tracer)
      case format
      when OpenTracing::FORMAT_TEXT_MAP
        extract_from_text_map(operation_name, carrier, tracer)
      when OpenTracing::FORMAT_BINARY
        warn 'Binary extract format not yet implemented'
        nil
      when OpenTracing::FORMAT_RACK
        extract_from_rack(operation_name, carrier, tracer)
      else
        warn 'Unknown extract format'
        nil
      end
    end

    # Convert a time to microseconds
    def micros(time)
      (time.to_f * 1E6).floor
    end

    # Returns a random guid. Note: this intentionally does not use SecureRandom,
    # which is slower and cryptographically secure randomness is not required here.
    def guid
      @_rng ||= Random.new
      @_rng.bytes(8).unpack('H*')[0]
    end

    private

    CARRIER_TRACER_STATE_PREFIX = 'ot-tracer-'.freeze
    CARRIER_BAGGAGE_PREFIX = 'ot-baggage-'.freeze

    # TODO(ngauthier@gmail.com) this shouldn't be in opentracer, but we use it
    # on spans in lightstep tracer
    DEFAULT_MAX_SPAN_RECORDS = 10_000

    def inject_to_text_map(span_context, carrier)
      carrier[CARRIER_TRACER_STATE_PREFIX + 'spanid'] = span_context.id
      carrier[CARRIER_TRACER_STATE_PREFIX + 'traceid'] = span_context.trace_id unless span_context.trace_id.nil?
      carrier[CARRIER_TRACER_STATE_PREFIX + 'sampled'] = 'true'

      span_context.baggage.each do |key, value|
        carrier[CARRIER_BAGGAGE_PREFIX + key.to_s] = value.to_s
      end
    end

    def extract_from_text_map(operation_name, carrier, tracer)
      span = Span.new(
        tracer: tracer,
        operation_name: operation_name,
        start_micros: OpenTracing.micros(Time.now),
        child_of_id: carrier[CARRIER_TRACER_STATE_PREFIX + 'spanid'],
        trace_id: carrier[CARRIER_TRACER_STATE_PREFIX + 'traceid'],
        max_log_records: DEFAULT_MAX_SPAN_RECORDS
      )

      baggage = carrier.reduce({}) do |baggage, tuple|
        key, value = tuple
        if key.start_with?(CARRIER_BAGGAGE_PREFIX)
          plain_key = key.to_s[CARRIER_BAGGAGE_PREFIX.length..key.to_s.length]
          baggage[plain_key] = value
        end
        baggage
      end
      span.set_baggage(baggage)

      span
    end

    def inject_to_rack(span_context, carrier)
      carrier[CARRIER_TRACER_STATE_PREFIX + 'spanid'] = span_context.id
      carrier[CARRIER_TRACER_STATE_PREFIX + 'traceid'] = span_context.trace_id unless span_context.trace_id.nil?
      carrier[CARRIER_TRACER_STATE_PREFIX + 'sampled'] = 'true'

      span_context.baggage.each do |key, value|
        if key =~ /[^A-Za-z0-9\-_]/
          # TODO: log the error internally
          next
        end
        carrier[CARRIER_BAGGAGE_PREFIX + key.to_s] = value.to_s
      end
    end

    def extract_from_rack(operation_name, env, tracer)
      extract_from_text_map(operation_name, env.reduce({}){|memo, tuple|
        raw_header, value = tuple
        header = raw_header.gsub(/^HTTP_/, '').gsub("_", "-").downcase

        memo[header] = value if header.start_with?(CARRIER_TRACER_STATE_PREFIX, CARRIER_BAGGAGE_PREFIX)
        memo
      }, tracer)
    end
  end
end
