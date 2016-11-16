require "forwardable"
require "concurrent"
require "opentracing/version"
require "opentracing/span_context"
require "opentracing/span"
require "opentracing/nil_tracer"

module OpenTracing
  class << self
    extend Forwardable
    # Global tracer to be used when OpenTracing.start_span is called
    attr_accessor :global_tracer
    def_delegator :global_tracer, :start_span

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
  end
end
